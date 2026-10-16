import { Database } from "bun:sqlite";
import { createHash } from "node:crypto";
import { existsSync, mkdirSync, rmSync } from "node:fs";
import { readdir, realpath, stat, writeFile } from "node:fs/promises";
import { homedir } from "node:os";
import { extname, join, resolve } from "node:path";
import type { ExtensionAPI } from "@oh-my-pi/pi-coding-agent";

const ROOT = join(homedir(), ".omp", "docs");
const PAGES = join(ROOT, "pages");
// The index is a rebuildable cache: bump this to drop and re-index everything instead of migrating.
const SCHEMA_VERSION = 3;
const URL_TTL_MS = 24 * 60 * 60 * 1000;
// Sources unused (not searched by name, not in any result) for this long are dropped, bounding index growth.
const RETAIN_MS = 30 * 24 * 60 * 60 * 1000;
const IS_URL = /^https?:\/\//i;
const FETCH_TIMEOUT_MS = 30_000;
const DOC_EXTS: Record<string, true> = { ".md": true, ".mdx": true, ".markdown": true, ".txt": true };
const MAX_FILES = 5000;
// Bounds open files and in-flight raw text while indexing a directory.
const READ_BATCH = 32;
// Indexed chunk size and display size are the same, so a hit is shown whole unless one paragraph alone exceeds it.
const CHUNK_CHARS = 2000;
const ANCHOR = /\s*\{#([^}\s]+)\}\s*/g;

interface Section {
	crumb: string;
	anchor: string;
	body: string;
	start: number;
	end: number;
}

interface Line {
	text: string;
	n: number;
}

let db: Database | undefined;

function open(): Database {
	if (db) return db;
	mkdirSync(ROOT, { recursive: true });
	db = new Database(join(ROOT, "index.db"), { create: true });
	// Concurrent OMP sessions share this file; wait for their writes instead of failing with SQLITE_BUSY.
	db.run("PRAGMA busy_timeout = 5000");
	db.run("PRAGMA journal_mode = WAL");
	if (db.query<{ user_version: number }, []>("PRAGMA user_version").get()?.user_version !== SCHEMA_VERSION) {
		db.run("DROP TABLE IF EXISTS sections");
		db.run("DROP TABLE IF EXISTS sources");
		rmSync(PAGES, { recursive: true, force: true });
		db.run(`PRAGMA user_version = ${SCHEMA_VERSION}`);
	}
	mkdirSync(PAGES, { recursive: true });
	db.run(
		"CREATE TABLE IF NOT EXISTS sources (key TEXT PRIMARY KEY, fingerprint TEXT NOT NULL, indexed_at INTEGER NOT NULL, used_at INTEGER NOT NULL)",
	);
	db.run(
		"CREATE VIRTUAL TABLE IF NOT EXISTS sections USING fts5(source UNINDEXED, file UNINDEXED, start UNINDEXED, end UNINDEXED, anchor UNINDEXED, crumb, body, tokenize = 'porter unicode61')",
	);
	// Vanished paths (garbage-collected store paths, deleted local docs) go immediately: their `file:line` ranges are dead.
	const cutoff = Date.now() - RETAIN_MS;
	const expired = db
		.query<{ key: string; used_at: number }, []>("SELECT key, used_at FROM sources")
		.all()
		.filter(row => row.used_at < cutoff || (!IS_URL.test(row.key) && !existsSync(row.key)))
		.map(row => row.key);
	const d = db;
	d.transaction(() => {
		for (const key of expired) {
			d.run("DELETE FROM sections WHERE source = ?", [key]);
			d.run("DELETE FROM sources WHERE key = ?", [key]);
		}
	})();
	for (const key of expired) if (IS_URL.test(key)) rmSync(pagePath(key), { force: true });
	return db;
}

/** Marks sources as used now, restarting their retention window. */
function touch(keys: string[]): void {
	const d = open();
	const update = d.prepare<unknown, [number, string]>("UPDATE sources SET used_at = ? WHERE key = ?");
	const now = Date.now();
	d.transaction(() => {
		for (const key of keys) update.run(now, key);
	})();
}

const sha1 = (s: string) => createHash("sha1").update(s).digest("hex");
const pagePath = (url: string) => join(PAGES, `${sha1(url).slice(0, 16)}.md`);

/**
 * Splits markdown into heading-delimited sections, then packs each section's paragraphs into chunks of at most
 * CHUNK_CHARS so long sections rank and display by the part that matches. Fences are never split and their `#`
 * lines are not headings; `{#id}` heading anchors are kept for citation links.
 */
function splitSections(text: string, title: string): Section[] {
	const out: Section[] = [];
	const crumbs: string[] = [];
	const anchors: string[] = [];
	let paras: Line[][] = [[]];
	let start: number | undefined = 1;
	let fence: string | undefined;
	const cut = () => {
		if (paras.at(-1)?.length) paras.push([]);
	};
	const flush = () => {
		const crumb = crumbs.filter(Boolean).join(" > ") || title;
		const anchor = anchors.findLast(Boolean) ?? "";
		let chunk: Line[] = [];
		let size = 0;
		const emit = () => {
			const kept = chunk.filter(line => line.text.trim());
			if (kept.length) {
				const body = chunk.map(line => line.text).join("\n").trim();
				out.push({ crumb, anchor, body, start: start ?? kept[0].n, end: kept[kept.length - 1].n });
				start = undefined;
			}
			chunk = [];
			size = 0;
		};
		for (const para of paras) {
			const len = para.reduce((n, line) => n + line.text.length + 1, 0);
			if (size && size + len > CHUNK_CHARS) emit();
			chunk.push(...para);
			size += len;
		}
		emit();
		paras = [[]];
	};
	text.split("\n").forEach((line, i) => {
		const marker = line.match(/^\s*(`{3,}|~{3,})/)?.[1];
		if (marker) {
			if (!fence) fence = marker;
			else if (marker[0] === fence[0] && marker.length >= fence.length) fence = undefined;
		}
		const loose = !fence && !marker;
		const heading = loose && line.match(/^(#{1,6})\s+(.+?)\s*#*\s*$/);
		if (!heading) {
			// Paragraphs end at blank lines and before top-level list items, so changelog-style lists split per item.
			if (loose && /^([-*+]|\d+\.)\s/.test(line)) cut();
			paras[paras.length - 1].push({ text: line, n: i + 1 });
			if (loose && !line.trim()) cut();
			return;
		}
		flush();
		const level = heading[1].length;
		crumbs.length = anchors.length = level;
		crumbs[level - 1] = heading[2].replace(ANCHOR, " ").trim();
		anchors[level - 1] = heading[2].match(/\{#([^}\s]+)\}/)?.[1] ?? "";
		start = i + 1;
	});
	flush();
	return out;
}

const ENTITIES: Record<string, string> = {
	amp: "&",
	lt: "<",
	gt: ">",
	quot: '"',
	apos: "'",
	nbsp: " ",
	ndash: "–",
	mdash: "—",
	hellip: "…",
	lsquo: "‘",
	rsquo: "’",
	ldquo: "“",
	rdquo: "”",
};

function decodeEntities(s: string): string {
	return s.replace(/&(#x[0-9a-f]+|#\d+|[a-z]+);/gi, (m, e: string) => {
		if (e[0] !== "#") return ENTITIES[e.toLowerCase()] ?? m;
		const code = e[1] === "x" || e[1] === "X" ? Number.parseInt(e.slice(2), 16) : Number(e.slice(1));
		return code > 0 && code <= 0x10ffff ? String.fromCodePoint(code) : m;
	});
}

const DROP: Record<string, true> = {
	script: true,
	style: true,
	noscript: true,
	svg: true,
	template: true,
	iframe: true,
	nav: true,
	footer: true,
};
const BLOCK: Record<string, true> = {
	p: true,
	div: true,
	section: true,
	article: true,
	main: true,
	details: true,
	summary: true,
	tr: true,
	dt: true,
	dd: true,
	blockquote: true,
	table: true,
	ul: true,
	ol: true,
	br: true,
	hr: true,
};

/**
 * Headings (with `{#id}` anchors), fences, table cells, and paragraph breaks are all section search needs;
 * everything else becomes plain text.
 */
function htmlToMarkdown(html: string): string {
	let pre = 0;
	let heading = 0;
	const raw = { html: true };
	const text = new HTMLRewriter()
		.on("*", {
			element(e) {
				const tag = e.tagName.toLowerCase();
				if (DROP[tag]) {
					e.remove();
					return;
				}
				// Docs put heading ids on the heading itself or on an empty `<a id>` inside it.
				const id = e.getAttribute("id") ?? (tag === "a" ? e.getAttribute("name") : null);
				if (/^h[1-6]$/.test(tag)) {
					heading++;
					e.before(`\n\n${"#".repeat(Number(tag[1]))} ${id ? `{#${id}} ` : ""}`, raw);
					e.after("\n\n", raw);
					e.onEndTag(() => {
						heading--;
					});
				} else if (heading && id) {
					e.before(` {#${id}} `, raw);
				} else if (tag === "pre") {
					pre++;
					e.before("\n\n```\n", raw);
					e.after("\n```\n\n", raw);
					e.onEndTag(() => {
						pre--;
					});
				} else if (tag === "code" && pre === 0) {
					e.before("`", raw);
					e.after("`", raw);
				} else if (tag === "li") {
					e.before("\n- ", raw);
				} else if (tag === "td" || tag === "th") {
					e.after(" | ", raw);
				} else if (BLOCK[tag]) {
					e.after("\n", raw);
				}
				e.removeAndKeepContent();
			},
		})
		.onDocument({
			text(t) {
				if (pre === 0 && t.text) t.replace(t.text.replace(/\s+/g, " "), raw);
			},
			comments(c) {
				c.remove();
			},
		})
		.transform(html);

	let fenced = false;
	return decodeEntities(text.replace(/<!doctype[^>]*>/i, ""))
		.split("\n")
		.map(line => {
			if (line.trim().startsWith("```")) {
				fenced = !fenced;
				return line.trim();
			}
			return fenced ? line : line.trim();
		})
		.join("\n")
		.replace(/\n{3,}/g, "\n\n")
		.trim();
}

function rawGithubUrl(url: string): string {
	const m = url.match(/^https:\/\/github\.com\/([^/]+)\/([^/]+)\/blob\/(.+)$/);
	return m ? `https://raw.githubusercontent.com/${m[1]}/${m[2]}/${m[3]}` : url;
}

async function fetchMarkdown(url: string, signal?: AbortSignal): Promise<string> {
	const deadline = AbortSignal.timeout(FETCH_TIMEOUT_MS);
	const abort = signal ? AbortSignal.any([signal, deadline]) : deadline;
	let target = url;
	for (let hop = 0; hop < 4; hop++) {
		const res = await fetch(target, {
			headers: {
				Accept: "text/markdown, text/plain;q=0.9, text/html;q=0.8, */*;q=0.5",
				"User-Agent": "Mozilla/5.0 (compatible; omp-docs)",
			},
			signal: abort,
		});
		if (!res.ok) throw new Error(`GET ${target}: HTTP ${res.status}`);
		const body = await res.text();
		if (!/html/i.test(res.headers.get("content-type") ?? "")) return body;
		// Static doc sites (e.g. Home Manager options) redirect with <meta http-equiv="refresh">, which fetch does not follow.
		const refresh = body.length < 20_000 && body.match(/<meta\b[^>]*http-equiv=["']?refresh[^>]*>/i)?.[0];
		const next = refresh && refresh.match(/url\s*=\s*["']?([^"'>\s]+)/i)?.[1];
		if (!next) return htmlToMarkdown(body);
		target = new URL(next, res.url).href;
	}
	throw new Error(`Too many refresh redirects from ${url}`);
}

async function docFiles(root: string): Promise<string[]> {
	if ((await stat(root)).isFile()) return [root];
	const files: string[] = [];
	const dirs = [root];
	for (let dir = dirs.pop(); dir !== undefined; dir = dirs.pop()) {
		for (const entry of await readdir(dir, { withFileTypes: true })) {
			if (entry.name.startsWith(".") || entry.name === "node_modules") continue;
			const path = join(dir, entry.name);
			if (entry.isDirectory()) dirs.push(path);
			else if (DOC_EXTS[extname(entry.name).toLowerCase()]) {
				files.push(path);
				if (files.length > MAX_FILES) throw new Error(`${root} has more than ${MAX_FILES} doc files; pass a narrower directory`);
			}
		}
	}
	return files.sort();
}

function replaceSource(key: string, fingerprint: string, files: { file: string; sections: Section[] }[]): number {
	const d = open();
	const insert = d.prepare(
		"INSERT INTO sections (source, file, start, end, anchor, crumb, body) VALUES (?, ?, ?, ?, ?, ?, ?)",
	);
	let count = 0;
	d.transaction(() => {
		d.run("DELETE FROM sections WHERE source = ?", [key]);
		for (const { file, sections } of files) {
			for (const s of sections) insert.run(key, file, s.start, s.end, s.anchor, s.crumb, s.body);
			count += sections.length;
		}
		const now = Date.now();
		d.run("INSERT OR REPLACE INTO sources (key, fingerprint, indexed_at, used_at) VALUES (?, ?, ?, ?)", [key, fingerprint, now, now]);
	})();
	return count;
}

/** Indexes `source` when missing or stale and returns its key plus a note when it (re)indexed. */
async function ensureIndexed(source: string, cwd: string, refresh: boolean, signal?: AbortSignal) {
	const known = open().prepare<{ fingerprint: string; indexed_at: number }, [string]>(
		"SELECT fingerprint, indexed_at FROM sources WHERE key = ?",
	);

	if (IS_URL.test(source)) {
		const key = rawGithubUrl(source);
		const row = known.get(key);
		if (row && !refresh && Date.now() - row.indexed_at < URL_TTL_MS) return { key };
		let markdown: string;
		try {
			markdown = await fetchMarkdown(key, signal);
		} catch (err) {
			// A stale index beats no answer when the site is down or rate-limiting; cancellation still propagates.
			if (!row || signal?.aborted) throw err;
			const reason = err instanceof Error ? err.message : String(err);
			return { key, note: `Re-fetch of ${key} failed (${reason}); searching the index from ${new Date(row.indexed_at).toISOString().slice(0, 10)}` };
		}
		const page = pagePath(key);
		await writeFile(page, markdown);
		const count = replaceSource(key, sha1(markdown), [{ file: page, sections: splitSections(markdown, key) }]);
		return { key, note: `Indexed ${key}: ${count} sections (${Math.round(markdown.length / 1024)} KB)` };
	}

	const key = await realpath(resolve(cwd, source));
	const row = known.get(key);
	// Store paths never change, so their presence alone proves freshness.
	const immutable = key.startsWith("/nix/store/");
	if (row && !refresh && immutable) return { key };
	const files = await docFiles(key);
	const fingerprint = immutable
		? "immutable"
		: sha1((await Promise.all(files.map(async f => `${f}:${(await stat(f)).mtimeMs}`))).join("\n"));
	if (row && !refresh && row.fingerprint === fingerprint) return { key };
	const parsed: { file: string; sections: Section[] }[] = [];
	for (let i = 0; i < files.length; i += READ_BATCH) {
		const batch = files.slice(i, i + READ_BATCH);
		parsed.push(
			...(await Promise.all(
				batch.map(async file => ({ file, sections: splitSections(await Bun.file(file).text(), file.slice(key.length + 1) || file) })),
			)),
		);
	}
	const count = replaceSource(key, fingerprint, parsed);
	return { key, note: `Indexed ${key}: ${count} sections from ${files.length} files` };
}

interface Hit {
	source: string;
	file: string;
	start: number;
	end: number;
	anchor: string;
	crumb: string;
	body: string;
}

/**
 * Each whitespace-separated term becomes an FTS5 phrase, so `services.nginx.virtualHosts` matches those words in
 * order and a trailing `*` matches word prefixes. All terms must match; if none do, any term may.
 */
function search(query: string, key: string | undefined, limit: number): { hits: Hit[]; loose: boolean } {
	const terms = query.split(/\s+/).flatMap(term => {
		const words = term.match(/[\p{L}\p{N}_]+/gu);
		return words ? [`"${words.join(" ")}"${term.endsWith("*") ? "*" : ""}`] : [];
	});
	if (!terms.length) throw new Error("Query has no searchable words");
	// Heading text outranks body text: a section titled after the query is usually the answer.
	const stmt = open().prepare<Hit, (string | number)[]>(
		`SELECT source, file, start, end, anchor, crumb, body FROM sections WHERE sections MATCH ?${key ? " AND source = ?" : ""} ORDER BY bm25(sections, 0, 0, 0, 0, 0, 4, 1) LIMIT ?`,
	);
	const run = (match: string) => stmt.all(...(key ? [match, key, limit] : [match, limit]));
	const hits = run(terms.join(" AND "));
	if (hits.length || terms.length === 1) return { hits, loose: false };
	return { hits: run(terms.join(" OR ")), loose: true };
}

function render(hit: Hit, showSource: boolean): string {
	const where = `${hit.file}:${hit.start}-${hit.end}`;
	const url = IS_URL.test(hit.source) ? (hit.anchor ? `${hit.source.split("#")[0]}#${hit.anchor}` : hit.source) : undefined;
	const origin = url ?? (showSource && hit.source !== hit.file ? hit.source : undefined);
	const body = hit.body.length > CHUNK_CHARS ? `${hit.body.slice(0, CHUNK_CHARS)}\n… (truncated; read ${where})` : hit.body;
	return [`## ${hit.crumb}`, origin ? `${where} — ${origin}` : where, body].join("\n");
}

export default function docsExtension(pi: ExtensionAPI): void {
	const z = pi.zod;

	pi.registerTool({
		name: "docs",
		label: "Docs",
		description:
			"Ranked full-text search over documentation: returns matching sections (≤2000 chars, with heading path, `file:start-end` for `read`, and the page URL#anchor for web sources), not matching lines. Use for questions against large docs (manuals, READMEs, changelogs, references) where `grep` would return noise or `read` would flood context. `source` is a URL, local file/dir, or Nix store path (e.g. a pinned flake input's `doc/`); it is indexed on first use and kept in ~/.omp/docs — URLs re-fetched after 24h, local paths when files change, and any source unused for 30 days dropped. Query terms are plain words ranked by BM25 with stemming, not a regex: every term must match (falling back to any term), dotted or hyphenated identifiers match as phrases, and a trailing `*` matches prefixes. Plain HTTP only: JavaScript-rendered pages index as empty, and only the given page is fetched, so point multi-page books at their single-page or print version.",
		loadMode: "essential",
		approval: "read",
		parameters: z.object({
			i: z.string().optional().describe("Present-participle intent"),
			query: z.string().describe("Terms to rank sections by, e.g. `writeShellApplication runtimeInputs`"),
			source: z
				.string()
				.optional()
				.describe("URL, local file/dir, or store path to search; omit to search every indexed source"),
			limit: z.number().optional().describe("Sections to return (default 5, max 20)"),
			refresh: z.boolean().optional().describe("Re-index `source` even if it looks fresh"),
		}),
		async execute(_toolCallId, params, signal, _onUpdate, ctx) {
			const indexed = params.source ? await ensureIndexed(params.source, ctx.cwd, params.refresh ?? false, signal) : undefined;
			const limit = Math.min(Math.max(Math.trunc(params.limit ?? 5), 1), 20);
			const { hits, loose } = search(params.query, indexed?.key, limit);
			touch([...new Set([...(indexed ? [indexed.key] : []), ...hits.map(h => h.source)])]);
			const lines = indexed?.note ? [indexed.note, ""] : [];
			if (loose && hits.length) lines.push("No section contains every term; showing sections that match any.", "");
			if (hits.length) {
				lines.push(hits.map(h => render(h, !indexed)).join("\n\n"));
			} else {
				lines.push(`No sections match "${params.query}" in ${indexed?.key ?? "all indexed sources"}.`);
				if (!indexed) {
					const keys = open()
						.query<{ key: string }, []>("SELECT key FROM sources ORDER BY key")
						.all()
						.map(r => r.key);
					lines.push(keys.length ? `Indexed sources:\n${keys.map(k => `- ${k}`).join("\n")}` : "Nothing is indexed yet; pass `source`.");
				}
			}
			return { content: [{ type: "text", text: lines.join("\n") }], details: { source: indexed?.key, hits: hits.length } };
		},
	});
}
