import { readdirSync } from "node:fs";
import { readFile } from "node:fs/promises";
import { join } from "node:path";
import type { ExtensionAPI, ExtensionContext } from "@oh-my-pi/pi-coding-agent";
import { getAgentDir } from "@oh-my-pi/pi-utils";

interface Macro {
	/** File stem — stable id typed after `/macro`. */
	readonly id: string;
	readonly name: string;
	readonly summary: string;
	readonly body: string;
}

const macroDir = join(getAgentDir(), "macros");
const summaryLimit = 72;
const frontmatterPattern = /^---[ \t]*\r?\n([\s\S]*?)\r?\n---[ \t]*(?:\r?\n|$)/;

function parseFrontmatter(raw: string): { fields: Map<string, string>; body: string } {
	const match = frontmatterPattern.exec(raw);
	if (!match) return { fields: new Map(), body: raw };

	const fields = new Map<string, string>();
	for (const line of match[1].split("\n")) {
		const separator = line.indexOf(":");
		if (separator <= 0) continue;
		const key = line.slice(0, separator).trim().toLowerCase();
		const value = line
			.slice(separator + 1)
			.trim()
			.replace(/^(["'])(.*)\1$/, "$2");
		if (key.length > 0 && value.length > 0) fields.set(key, value);
	}
	return { fields, body: raw.slice(match[0].length) };
}

/** Fallback summary: first non-empty line, clipped on a word boundary. */
function summarize(body: string): string {
	const first = body.split("\n").find(line => line.trim().length > 0)?.trim() ?? "";
	if (first.length <= summaryLimit) return first;
	const boundary = first.lastIndexOf(" ", summaryLimit);
	return `${first.slice(0, boundary > summaryLimit / 2 ? boundary : summaryLimit).trimEnd()}…`;
}

async function loadMacros(): Promise<Macro[]> {
	const files = readdirSync(macroDir)
		.filter(name => !name.startsWith(".") && name.endsWith(".md"))
		.sort((left, right) => left.localeCompare(right));

	const macros = await Promise.all(
		files.map(async (file): Promise<Macro> => {
			const id = file.slice(0, -3);
			const { fields, body } = parseFrontmatter(await readFile(join(macroDir, file), "utf8"));
			const text = body.trim();
			return {
				id,
				name: fields.get("name") ?? id,
				summary: fields.get("summary") ?? fields.get("description") ?? summarize(text),
				body: text,
			};
		}),
	);
	return macros.filter(macro => macro.body.length > 0);
}

type MacroContext = Pick<ExtensionContext, "ui">;

async function pickMacro(ctx: MacroContext, macros: Macro[]): Promise<Macro | undefined> {
	// Labels must stay unique — same display name from two files disambiguates by id.
	const byLabel = new Map<string, Macro>();
	const options = macros.map(macro => {
		const label = byLabel.has(macro.name) ? `${macro.name} (${macro.id})` : macro.name;
		byLabel.set(label, macro);
		return { label, description: macro.summary };
	});

	const picked = await ctx.ui.select("Insert macro", options);
	return picked === undefined ? undefined : byLabel.get(picked);
}

async function insertMacro(ctx: MacroContext, requested: string): Promise<void> {
	let macros: Macro[];
	try {
		macros = await loadMacros();
	} catch (error) {
		const missingDir = error instanceof Error && "code" in error && error.code === "ENOENT";
		if (missingDir) {
			ctx.ui.notify("No macros found in ~/.omp/agent/macros.", "info");
		} else {
			ctx.ui.notify(
				`Could not list macros: ${error instanceof Error ? error.message : String(error)}`,
				"error",
			);
		}
		return;
	}

	if (macros.length === 0) {
		ctx.ui.notify("No macros found in ~/.omp/agent/macros.", "info");
		return;
	}

	let macro: Macro | undefined;
	if (requested.length > 0) {
		const wanted = requested.toLowerCase();
		macro = macros.find(
			candidate => candidate.id.toLowerCase() === wanted || candidate.name.toLowerCase() === wanted,
		);
		if (!macro) {
			ctx.ui.notify(`Unknown macro "${requested}".`, "error");
			return;
		}
	} else {
		macro = await pickMacro(ctx, macros);
		if (!macro) return;
	}

	ctx.ui.setEditorText(macro.body);
}

export default function macrosExtension(pi: ExtensionAPI): void {
	pi.registerCommand("macro", {
		description: "Insert a Markdown prompt macro",
		getArgumentCompletions: async (prefix: string) => {
			let macros: Macro[];
			try {
				macros = await loadMacros();
			} catch {
				return null;
			}

			const normalized = prefix.trim().toLowerCase();
			const items = macros
				.filter(
					macro =>
						macro.id.toLowerCase().startsWith(normalized) ||
						macro.name.toLowerCase().startsWith(normalized),
				)
				.map(macro => ({ value: macro.id, label: macro.name, description: macro.summary }));
			return items.length > 0 ? items : null;
		},
		handler: (args, ctx) => insertMacro(ctx, args.trim()),
	});

	// Ctrl+M needs the kitty keyboard protocol to be distinguishable from Enter;
	// terminals without it just never deliver the chord, so /macro stays the fallback.
	pi.registerShortcut("ctrl+m", {
		description: "Insert a Markdown prompt macro",
		handler: ctx => insertMacro(ctx, ""),
	});
}
