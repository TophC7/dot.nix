import { readdirSync } from "node:fs";
import { readFile } from "node:fs/promises";
import { join } from "node:path";
import type { ExtensionAPI } from "@oh-my-pi/pi-coding-agent";
import { getAgentDir } from "@oh-my-pi/pi-utils";

interface Macro {
	readonly id: string;
	readonly path: string;
}

const macroDir = join(getAgentDir(), "macros");

function listMacros(): Macro[] {
	return readdirSync(macroDir)
		.filter(name => !name.startsWith(".") && name.endsWith(".md"))
		.sort((left, right) => left.localeCompare(right))
		.map(name => ({ id: name.slice(0, -3), path: join(macroDir, name) }));
}

export default function macrosExtension(pi: ExtensionAPI): void {
	pi.registerCommand("macro", {
		description: "Insert a Markdown prompt macro",
		getArgumentCompletions: (prefix: string) => {
			try {
				const macros = listMacros();
				const normalized = prefix.trim();
				const items = macros
					.filter(macro => macro.id.startsWith(normalized))
					.map(macro => ({ value: macro.id, label: macro.id }));
				return items.length > 0 ? items : null;
			} catch {
				return null;
			}
		},
		handler: async (args, ctx) => {
			let macros: Macro[];
			try {
				macros = listMacros();
			} catch (error) {
				if (error instanceof Error && "code" in error && error.code === "ENOENT") {
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

			const requested = args.trim();
			const id =
				requested ||
				(await ctx.ui.select(
					"Select macro",
					macros.map(macro => macro.id),
				));
			if (!id) return;

			const macro = macros.find(candidate => candidate.id === id);
			if (!macro) {
				ctx.ui.notify(`Unknown macro "${id}".`, "error");
				return;
			}

			let content: string;
			try {
				content = await readFile(macro.path, "utf8");
			} catch (error) {
				ctx.ui.notify(
					`Could not read macro "${id}": ${error instanceof Error ? error.message : String(error)}`,
					"error",
				);
				return;
			}

			if (content.trim().length === 0) {
				ctx.ui.notify(`Macro "${id}" is empty.`, "error");
				return;
			}

			ctx.ui.setEditorText(content);
		},
	});
}
