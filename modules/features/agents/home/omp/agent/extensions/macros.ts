import { readdirSync } from "node:fs";
import { readFile } from "node:fs/promises";
import { join } from "node:path";
import type { ExtensionAPI, ExtensionContext } from "@oh-my-pi/pi-coding-agent";
import {
	type Component,
	type KeybindingsManager,
	matchesKey,
	type Theme,
	TreeView,
	truncateToWidth,
	visibleWidth,
} from "@oh-my-pi/pi-tui";
import { getAgentDir } from "@oh-my-pi/pi-utils";

interface Macro {
	/** Path stem under the macro dir (`ui-screens`, `pr/merge`) — stable id typed after `/macro`. */
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

/** Root `*.md` files plus one level of folders; deeper nesting is ignored. */
function listMacroIds(): string[] {
	const ids: string[] = [];
	for (const entry of readdirSync(macroDir, { withFileTypes: true })) {
		if (entry.name.startsWith(".")) continue;
		const files = entry.isDirectory()
			? readdirSync(join(macroDir, entry.name)).map(name => `${entry.name}/${name}`)
			: [entry.name];
		for (const file of files) {
			if (file.endsWith(".md") && !file.includes("/.")) ids.push(file.slice(0, -3));
		}
	}
	return ids.sort((left, right) => left.localeCompare(right));
}

async function loadMacros(): Promise<Macro[]> {
	const macros = await Promise.all(
		listMacroIds().map(async (id): Promise<Macro> => {
			const { fields, body } = parseFrontmatter(await readFile(join(macroDir, `${id}.md`), "utf8"));
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

type MacroLeaf = { readonly kind: "macro"; readonly key: string; readonly macro: Macro };
type MacroFolder = { readonly kind: "folder"; readonly key: string; readonly name: string; readonly children: MacroLeaf[] };
type MacroNode = MacroLeaf | MacroFolder;

/** Folders first (like a file browser), then root macros; both keep id order. */
function buildTree(macros: readonly Macro[]): MacroNode[] {
	const leaves: MacroLeaf[] = [];
	const folders = new Map<string, MacroFolder>();
	for (const macro of macros) {
		const leaf: MacroLeaf = { kind: "macro", key: macro.id, macro };
		const slash = macro.id.indexOf("/");
		if (slash < 0) {
			leaves.push(leaf);
			continue;
		}
		const name = macro.id.slice(0, slash);
		let folder = folders.get(name);
		if (!folder) {
			folder = { kind: "folder", key: `${name}/`, name, children: [] };
			folders.set(name, folder);
		}
		folder.children.push(leaf);
	}
	return [...folders.values(), ...leaves];
}

/** Clip or pad styled text to exactly `width` cells. */
function fit(text: string, width: number): string {
	const clipped = truncateToWidth(text, width);
	return clipped + " ".repeat(Math.max(0, width - visibleWidth(clipped)));
}

/**
 * Accordion over root macros and folders: OMP's own `TreeView` (the `/tree`
 * component) inside the rounded overlay chrome its built-in pickers use.
 */
class MacroPicker implements Component {
	readonly #expanded = new Set<string>();
	readonly #tree: TreeView<MacroNode>;
	readonly #theme: Theme;
	readonly #hint: string;

	constructor(
		roots: MacroNode[],
		theme: Theme,
		private readonly keybindings: KeybindingsManager,
		private readonly done: (macro: Macro | undefined) => void,
	) {
		this.#theme = theme;
		this.#hint = theme.fg("dim", "↑↓: move. →/←: open/close folder. Enter: insert. Esc: cancel.");
		// Root macros indent past the folder arrow; folder children sit behind a `  ├─ ` gutter.
		const childIndent = 3 + visibleWidth(theme.tree.branch);
		const nameWidths = roots.flatMap(node =>
			node.kind === "folder"
				? node.children.map(child => childIndent + visibleWidth(child.macro.name))
				: [2 + visibleWidth(node.macro.name)],
		);
		const nameColumn = Math.max(0, ...nameWidths) + 3;
		this.#tree = new TreeView<MacroNode>({
			roots,
			theme,
			getKey: node => node.key,
			getChildren: node => (node.kind === "folder" ? node.children : []),
			isExpanded: node => this.#expanded.has(node.key),
			maxRows: 15,
			renderPrefix: () => ({ first: "", continuation: "" }),
			renderLeading: (_node, context) => (context.selected ? theme.fg("accent", "› ") : "  "),
			renderRow: (node, { row, selected, contentWidth }) => {
				let text: string;
				if (node.kind === "folder") {
					const arrow = theme.fg("accent", this.#expanded.has(node.key) ? "▾" : "▸");
					text = `${arrow} ${theme.bold(node.name)}  ${theme.fg("dim", String(node.children.length))}`;
				} else {
					const lead = row.depth === 0 ? "  " : theme.fg("dim", `  ${row.isLast ? theme.tree.last : theme.tree.branch} `);
					const name = lead + node.macro.name;
					text = name + " ".repeat(Math.max(2, nameColumn - visibleWidth(name))) + theme.fg("dim", node.macro.summary);
				}
				// Pad the selected row so its highlight spans the panel.
				return selected ? fit(text, contentWidth) : text;
			},
			styleSelected: line => theme.bg("selectedBg", line),
		});
	}

	#setExpanded(key: string, expanded: boolean): void {
		if (expanded) this.#expanded.add(key);
		else this.#expanded.delete(key);
		this.#tree.invalidate();
	}

	handleInput(data: string): void {
		const node = this.#tree.selectedItem;
		if (this.keybindings.matches(data, "tui.select.up")) this.#tree.moveSelection(-1, true);
		else if (this.keybindings.matches(data, "tui.select.down")) this.#tree.moveSelection(1, true);
		else if (this.keybindings.matches(data, "tui.select.cancel")) this.done(undefined);
		else if (!node) return;
		else if (this.keybindings.matches(data, "tui.select.confirm")) {
			if (node.kind === "macro") this.done(node.macro);
			else this.#setExpanded(node.key, !this.#expanded.has(node.key));
		} else if (matchesKey(data, "right") && node.kind === "folder") this.#setExpanded(node.key, true);
		else if (matchesKey(data, "left")) {
			// Folding from a child jumps back to its folder.
			const folderKey = node.kind === "folder" ? node.key : this.#tree.rows[this.#tree.selectionIndex]?.parentKey;
			if (folderKey === undefined) return;
			this.#setExpanded(folderKey, false);
			this.#tree.setSelectedKey(folderKey);
		}
	}

	render(width: number): readonly string[] {
		const theme = this.#theme;
		const box = theme.boxRound;
		const border = (glyphs: string) => theme.fg("border", glyphs);
		const inner = Math.max(0, width - 4);
		const row = (content: string) => `${border(box.vertical)} ${fit(content, inner)} ${border(box.vertical)}`;
		const rule = (left: string, right: string) => border(left + box.horizontal.repeat(Math.max(0, width - 2)) + right);
		const title = theme.bold(theme.fg("accent", " Macros "));
		const titleFill = box.horizontal.repeat(Math.max(0, width - 3 - visibleWidth(title)));
		return [
			border(box.topLeft + box.horizontal) + title + border(titleFill + box.topRight),
			row(this.#hint),
			rule(box.teeRight, box.teeLeft),
			...this.#tree.render(inner).map(row),
			rule(box.bottomLeft, box.bottomRight),
		];
	}

	invalidate(): void {
		this.#tree.invalidate();
	}

	dispose(): void {
		this.#tree.dispose();
	}
}

type MacroContext = Pick<ExtensionContext, "ui">;

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
		// ponytail: custom() is TUI-only (RPC resolves undefined); `/macro <id>` stays the non-TUI path.
		macro = await ctx.ui.custom<Macro | undefined>(
			(_tui, theme, keybindings, done) => new MacroPicker(buildTree(macros), theme, keybindings, done),
		);
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
