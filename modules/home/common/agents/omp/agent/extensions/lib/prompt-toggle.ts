import { mkdir, readFile, writeFile } from "node:fs/promises";
import { join } from "node:path";
import type { ExtensionAPI, ExtensionCommandContext, ExtensionContext } from "@oh-my-pi/pi-coding-agent";
import { getAgentDir } from "@oh-my-pi/pi-utils";

export interface PromptToggleOptions {
	readonly name: string;
	readonly label: string;
	readonly prompt: string;
	readonly defaultEnabled?: boolean;
}

export function definePromptToggle(options: PromptToggleOptions): (pi: ExtensionAPI) => void {
	const configPath = join(getAgentDir(), `${options.name}.json`);
	const entryType = `${options.name}-enabled`;
	const prompt = options.prompt.trim();
	const builtInDefault = options.defaultEnabled ?? true;

	return function promptToggleExtension(pi: ExtensionAPI): void {
		let enabled = builtInDefault;
		let defaultEnabled = builtInDefault;
		let configLoad: Promise<void> | null = null;
		let saveQueue: Promise<void> = Promise.resolve();

		function load(): Promise<void> {
			configLoad ??= (async () => {
				let raw: string;
				try {
					raw = await readFile(configPath, "utf8");
				} catch (error) {
					if (!(error instanceof Error && "code" in error && error.code === "ENOENT")) {
						console.error(`[${options.name}] cannot read ${configPath}, using defaults:`, error);
					}
					return;
				}

				let parsed: unknown;
				try {
					parsed = JSON.parse(raw);
				} catch (error) {
					console.error(`[${options.name}] ${configPath} is not valid JSON, using defaults:`, error);
					return;
				}
				if (parsed === null || typeof parsed !== "object" || Array.isArray(parsed)) {
					console.error(`[${options.name}] ${configPath} is not an object, using defaults.`);
					return;
				}

				const stored = "enabled" in parsed ? parsed.enabled : undefined;

				if (typeof stored === "boolean") {
					enabled = stored;
					defaultEnabled = stored;
					return;
				}
				if (stored !== undefined) {
					console.error(
						`[${options.name}] ${configPath} has non-boolean enabled ${JSON.stringify(stored)}, using ${defaultEnabled}.`,
					);
					return;
				}

			})();
			return configLoad;
		}

		function save(): Promise<void> {
			const snapshot = `${JSON.stringify({ enabled: defaultEnabled }, null, 2)}\n`;
			saveQueue = saveQueue.then(
				() => writeSnapshot(snapshot),
				() => writeSnapshot(snapshot),
			);
			return saveQueue;
		}

		async function writeSnapshot(snapshot: string): Promise<void> {
			await mkdir(getAgentDir(), { recursive: true });
			await writeFile(configPath, snapshot, "utf8");
		}

		async function apply(next: boolean): Promise<void> {
			if (next !== enabled) {
				enabled = next;
				pi.appendEntry(entryType, { enabled: next });
			}
			if (next !== defaultEnabled) {
				defaultEnabled = next;
				await save();
			}
		}

		async function select(ctx: ExtensionCommandContext, next: boolean): Promise<void> {
			try {
				await apply(next);
				ctx.ui.notify(`${options.label} ${next ? "on" : "off"}.`, "info");
			} catch (error) {
				ctx.ui.notify(`${options.label} changed, but could not save the default: ${error}`, "error");
			}
		}

		async function restoreFromBranch(ctx: ExtensionContext): Promise<boolean> {
			await load();

			let restored: boolean | null = null;
			for (const entry of ctx.sessionManager.getBranch()) {
				if (entry.type !== "custom") continue;
				const data = entry.data;
				if (data === null || typeof data !== "object" || Array.isArray(data)) continue;

				if (entry.customType !== entryType || !("enabled" in data)) continue;
				const candidate = data.enabled;
				if (typeof candidate === "boolean") restored = candidate;
			}

			enabled = restored ?? defaultEnabled;
			return restored !== null;
		}

		pi.on("session_start", async (_event, ctx) => {
			if (!(await restoreFromBranch(ctx))) pi.appendEntry(entryType, { enabled });
		});
		pi.on("session_switch", async (_event, ctx) => {
			if (!(await restoreFromBranch(ctx))) pi.appendEntry(entryType, { enabled });
		});
		pi.on("session_branch", async (_event, ctx) => {
			await restoreFromBranch(ctx);
		});
		pi.on("session_tree", async (_event, ctx) => {
			await restoreFromBranch(ctx);
		});

		pi.registerCommand(options.name, {
			description: `Toggle ${options.name}, or pass on/off`,
			getArgumentCompletions: (prefix: string) => {
				const normalized = prefix.trim().toLowerCase();
				const items = [
					{ value: "on", label: "on", description: `Enable ${options.name}` },
					{ value: "off", label: "off", description: `Disable ${options.name}` },
				].filter((item) => item.value.startsWith(normalized));
				return items.length > 0 ? items : null;
			},
			handler: async (args, ctx) => {
				await load();
				const arg = args?.trim().toLowerCase();
				if (arg && arg !== "on" && arg !== "off") {
					ctx.ui.notify(`Unknown ${options.name} state "${arg}". Use: on, off`, "error");
					return;
				}
				await select(ctx, arg ? arg === "on" : !enabled);
			},
		});

		pi.on("before_agent_start", async (event) => {
			await load();
			if (!enabled) return;
			return { systemPrompt: [...event.systemPrompt, prompt] };
		});
	};
}
