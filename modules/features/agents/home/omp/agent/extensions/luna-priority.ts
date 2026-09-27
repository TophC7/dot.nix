import type { ExtensionAPI, ExtensionContext } from "@oh-my-pi/pi-coding-agent";

export default function lunaPriorityExtension(pi: ExtensionAPI): void {
	pi.on("before_provider_request", async (event, ctx: ExtensionContext) => {
		if (ctx.model?.provider !== "openai-codex" || ctx.model.id !== "gpt-5.6-luna") {
			return;
		}

		const payload = event.payload;
		if (!payload || typeof payload !== "object") {
			return;
		}

		// OpenAI Codex provider drops compat.extraBody; inject priority tier directly onto outgoing request.
		return {
			...(payload as Record<string, unknown>),
			service_tier: "priority",
		};
	});
}
