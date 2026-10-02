import type { ExtensionAPI } from "@oh-my-pi/pi-coding-agent";

/** Routes `/decomplect` through `/plan` so the audit runs in native plan mode. Interactive TUI only. */
export default function decomplectExtension(pi: ExtensionAPI): void {
	pi.on("input", (event, ctx) => {
		const text = event.text.trim();
		if (!/^\/decomplect(?:\s|$)/.test(text)) return;

		// /plan toggles off when already active; use the current branch after resume/tree navigation.
		const mode = ctx.sessionManager.getBranch().findLast(entry => entry.type === "mode_change")?.mode;
		if (mode !== "plan") return { text: `/plan ${text}` };
	});
}
