import type { ExtensionAPI, ExtensionContext } from "@oh-my-pi/pi-coding-agent";

interface AntigravityPayload {
	project?: string;
	requestId?: string;
	model?: string;
	userAgent?: string;
	requestType?: string;
	request?: {
		systemInstruction?: {
			role?: string;
			parts?: Array<{ text?: string }>;
		};
	};
}

export default function antigravityExtension(pi: ExtensionAPI): void {
	pi.on("before_provider_request", async (event, ctx: ExtensionContext) => {
		// Gate strictly to Google Antigravity OAuth requests.
		if (ctx.model?.provider !== "google-antigravity") {
			return;
		}

		const payload = event.payload as AntigravityPayload | null;
		if (!payload || typeof payload !== "object") {
			return;
		}

		if (payload.userAgent !== "antigravity" && payload.requestType !== "agent") {
			return;
		}

		let modified = false;

		// 1. Drop requestType to match the official Antigravity client envelope.
		if ("requestType" in payload) {
			delete payload.requestType;
			modified = true;
		}

		// 2. Break Google's prompt-fingerprint filter on <system-conventions>.
		const parts = payload.request?.systemInstruction?.parts;
		if (Array.isArray(parts)) {
			for (const part of parts) {
				if (typeof part?.text === "string" && part.text.includes("<system-conventions>")) {
					part.text = part.text
						.replaceAll("<system-conventions>", "<system_conventions>")
						.replaceAll("</system-conventions>", "</system_conventions>");
					modified = true;
				}
			}
		}

		return modified ? payload : undefined;
	});
}
