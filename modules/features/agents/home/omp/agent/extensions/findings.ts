import { mkdir, writeFile } from "node:fs/promises";
import { join } from "node:path";
import type { ExtensionAPI, ExtensionContext } from "@oh-my-pi/pi-coding-agent";

type Severity = "blocking" | "required" | "suggestion";
type FixKind = "mechanical" | "judgment";

interface Finding {
	id: string;
	scope: string;
	file: string;
	line: number;
	endLine?: number;
	inChangedLines: boolean;
	severity: Severity;
	problem: string;
	evidence: string;
	mechanism?: string;
	impact?: string;
	risk?: string;
	edit?: string;
	fixKind?: FixKind;
}

interface Verdict {
	id: string;
	status: "confirmed" | "refuted" | "unverified" | "duplicate";
	reason: string;
	duplicateOf?: string;
	fixKind?: FixKind;
}

interface FixGate {
	files: string[];
	partiallyStaged?: string[];
}

interface Fixer {
	applied: { id: string; file: string; line: number; summary: string }[];
	notApplied: { id: string; reason: string }[];
	checks: { command: string; passed: boolean; note?: string }[];
	restaged?: string[];
}

/** One reported defect after duplicate folding: the kept root plus every finding the skeptic merged into it. */
interface Entry {
	f: Finding;
	also: Finding[];
	note?: string;
}

const SEVERITY_RANK: Record<Severity, number> = { blocking: 0, required: 1, suggestion: 2 };

const at = (f: Finding) => `${f.file}:${f.line}${f.endLine && f.endLine > f.line ? `-${f.endLine}` : ""}`;

const byRank = (a: Entry, b: Entry) =>
	SEVERITY_RANK[a.f.severity] - SEVERITY_RANK[b.f.severity] || at(a.f).localeCompare(at(b.f));

/** Folds skeptic duplicates into their roots, then routes each root by verdict and, for cleanup, the auto-fix gate. */
function triage(workflow: "cleanup" | "review", findings: Finding[], verdicts: Verdict[], fixGate?: FixGate) {
	const byId = new Map(findings.map(f => [f.id, f]));
	const verdictOf = new Map(verdicts.map(v => [v.id, v]));
	const gaps = verdicts.filter(v => !byId.has(v.id)).map(v => `skeptic returned a verdict for unknown finding ${v.id}`);

	// Follows a duplicate chain to its first non-duplicate finding; missing targets and cycles have no root.
	const rootOf = (id: string): string | undefined => {
		const seen = new Set<string>();
		let cur = id;
		while (verdictOf.get(cur)?.status === "duplicate") {
			const next = verdictOf.get(cur)?.duplicateOf;
			if (seen.has(cur) || !next || !byId.has(next)) return undefined;
			seen.add(cur);
			cur = next;
		}
		return cur;
	};

	const entries = new Map<string, Entry>();
	for (const f of findings) {
		const root = rootOf(f.id);
		if (root === f.id) entries.set(f.id, { f: { ...f }, also: [] });
		else if (root === undefined) {
			entries.set(f.id, { f: { ...f }, also: [], note: `unresolved duplicate of ${verdictOf.get(f.id)?.duplicateOf ?? "nothing"}` });
		}
	}
	for (const f of findings) {
		const root = rootOf(f.id);
		const entry = root && root !== f.id ? entries.get(root) : undefined;
		if (!entry) continue;
		entry.also.push(f);
		if (SEVERITY_RANK[f.severity] < SEVERITY_RANK[entry.f.severity]) entry.f.severity = f.severity;
	}

	const toFix: Entry[] = [];
	const confirmed: Entry[] = [];
	const unverified: Entry[] = [];
	const refuted: Entry[] = [];
	for (const e of entries.values()) {
		const v = verdictOf.get(e.f.id);
		if (e.note) unverified.push(e);
		else if (!v) unverified.push({ ...e, note: "no skeptic verdict" });
		else if (v.status === "refuted") refuted.push({ ...e, note: v.reason });
		else if (v.status === "unverified") unverified.push({ ...e, note: v.reason });
		else if (workflow === "review") confirmed.push(e);
		else {
			// The skeptic can only downgrade: any audit or judgment voice on the same defect keeps it out of auto-fix.
			const mechanical =
				Boolean(e.f.edit) &&
				(v.fixKind ?? e.f.fixKind) === "mechanical" &&
				[e.f, ...e.also].every(f => f.scope !== "audit" && f.fixKind !== "judgment");
			if (!mechanical) {
				confirmed.push(e);
				continue;
			}
			const blocker = !e.f.inChangedLines
				? "outside changed lines"
				: !fixGate
					? "target is not an editable working tree"
					: !fixGate.files.includes(e.f.file)
						? "file is not part of the editable target"
						: fixGate.partiallyStaged?.includes(e.f.file)
							? "file is partially staged"
							: undefined;
			if (blocker) confirmed.push({ ...e, note: `not auto-fixed: ${blocker}` });
			else toFix.push(e);
		}
	}
	return { toFix, confirmed, unverified, refuted, gaps };
}

function renderEntry({ f, also, note }: Entry): string[] {
	return [
		`### ${f.id} · ${f.severity} · \`${at(f)}\` (${f.scope}${f.risk ? `, ${f.risk}` : ""})`,
		`- **Problem**: ${f.problem}`,
		...(f.mechanism ? [`- **Mechanism**: ${f.mechanism}`] : []),
		...(f.impact ? [`- **Impact**: ${f.impact}`] : []),
		`- **Evidence**: ${f.evidence}`,
		...(f.edit ? [`- **Edit**: ${f.edit}`] : []),
		...(also.length ? [`- **Also reported**: ${also.map(a => `${a.id} (${a.scope})`).join(", ")}`] : []),
		...(note ? [`- **Note**: ${note}`] : []),
		"",
	];
}

function localRoot(ctx: ExtensionContext): string {
	const artifactsDir =
		ctx.localProtocolOptions?.getArtifactsDir?.() ?? ctx.sessionManager.getSessionFile()?.replace(/\.jsonl$/, "");
	if (!artifactsDir) throw new Error("No session artifacts directory: cannot write local://findings.md");
	return join(artifactsDir, "local");
}

export default function findingsExtension(pi: ExtensionAPI): void {
	const z = pi.zod;
	const severity = z.enum(["blocking", "required", "suggestion"]);
	const fixKind = z.enum(["mechanical", "judgment"]);

	pi.registerTool({
		name: "triage_findings",
		label: "Triage Findings",
		description:
			"Stateless triage for /cleanup and /review:adversarial: folds skeptic duplicates, routes findings by verdict, gates cleanup auto-fixes, and writes the shared report to local://findings.md. Cleanup with auto-fixable findings and no fixer result returns the toFix list instead; call again with the same inputs plus `fixer`.",
		loadMode: "essential",
		approval: "read",
		parameters: z.object({
			i: z.string().optional().describe("Present-participle intent"),
			workflow: z.enum(["cleanup", "review"]),
			target: z.string().describe("Target label, e.g. `staged changes` or `PR #12`"),
			findings: z
				.array(
					z.object({
						id: z.string().describe("Unique `<scope>-<n>`"),
						scope: z.string(),
						file: z.string(),
						line: z.number(),
						endLine: z.number().optional(),
						inChangedLines: z.boolean(),
						severity,
						problem: z.string(),
						evidence: z.string(),
						mechanism: z.string().optional(),
						impact: z.string().optional(),
						risk: z.string().optional(),
						edit: z.string().optional(),
						fixKind: fixKind.optional(),
					}),
				)
				.describe("Every scout and omission finding, verbatim, with an assigned id and scope"),
			verdicts: z
				.array(
					z.object({
						id: z.string(),
						status: z.enum(["confirmed", "refuted", "unverified", "duplicate"]),
						reason: z.string(),
						duplicateOf: z.string().optional(),
						fixKind: fixKind.optional(),
					}),
				)
				.describe("Every skeptic verdict, verbatim"),
			gaps: z.array(z.string()).optional().describe("Coverage gaps: failed agents, unexamined files, omission gaps"),
			fixGate: z
				.object({
					files: z.array(z.string()).describe("Target files whose working-tree content is the reviewed version"),
					partiallyStaged: z.array(z.string()).optional(),
				})
				.optional()
				.describe("Cleanup only; omit when the working tree is not the target version"),
			fixer: z
				.object({
					applied: z.array(z.object({ id: z.string(), file: z.string(), line: z.number(), summary: z.string() })),
					notApplied: z.array(z.object({ id: z.string(), reason: z.string() })),
					checks: z.array(z.object({ command: z.string(), passed: z.boolean(), note: z.string().optional() })),
					restaged: z.array(z.string()).optional(),
				})
				.optional()
				.describe("cleanup-fixer result, verbatim"),
		}),
		async execute(_toolCallId, params, _signal, _onUpdate, ctx) {
			const dupe = params.findings.find((f, i) => params.findings.findIndex(g => g.id === f.id) !== i);
			if (dupe) throw new Error(`Duplicate finding id: ${dupe.id}`);

			const { toFix, confirmed, unverified, refuted, gaps } = triage(
				params.workflow,
				params.findings,
				params.verdicts,
				params.fixGate,
			);
			gaps.unshift(...(params.gaps ?? []));
			const fixer: Fixer | undefined = params.fixer;

			if (params.workflow === "cleanup" && !fixer && toFix.length > 0) {
				const fixes = toFix.map(e => e.f);
				return {
					content: [{ type: "text", text: `toFix (${fixes.length}):\n${JSON.stringify(fixes, null, 2)}` }],
					details: { done: false, toFix: fixes },
				};
			}

			if (fixer) {
				const appliedIds = new Set(fixer.applied.map(a => a.id));
				const rejected = new Map(fixer.notApplied.map(n => [n.id, n.reason]));
				for (const e of toFix) {
					if (!appliedIds.has(e.f.id)) {
						confirmed.push({ ...e, note: `not applied: ${rejected.get(e.f.id) ?? "fixer did not report it"}` });
					}
				}
			}
			for (const list of [confirmed, unverified, refuted]) list.sort(byRank);

			const verdict =
				params.workflow !== "review"
					? undefined
					: confirmed.some(e => e.f.severity !== "suggestion")
						? "Request Changes"
						: unverified.length || gaps.length
							? "Needs Discussion"
							: "Approve";
			const empty = !fixer?.applied.length && !confirmed.length && !unverified.length && !refuted.length;

			const report = [
				`# /${params.workflow === "review" ? "review:adversarial" : "cleanup"}: ${params.target}`,
				"",
				...(verdict
					? [`**Verdict**: ${verdict} (${confirmed.length} confirmed, ${unverified.length} unverified, ${refuted.length} refuted)`, ""]
					: []),
				...(fixer?.applied.length
					? ["## Applied", ...fixer.applied.map(a => `- ${a.id} \`${a.file}:${a.line}\`: ${a.summary}`), ""]
					: []),
				...(fixer?.checks.length || fixer?.restaged?.length
					? [
							"## Checks",
							...fixer.checks.map(c => `- \`${c.command}\`: ${c.passed ? "passed" : "failed"}${c.note ? ` (${c.note})` : ""}`),
							...(fixer.restaged?.length ? [`- re-staged: ${fixer.restaged.join(", ")}`] : []),
							"",
						]
					: []),
				...(confirmed.length ? ["## Confirmed", "", ...confirmed.flatMap(renderEntry)] : []),
				...(unverified.length ? ["## Unverified", "", ...unverified.flatMap(renderEntry)] : []),
				...(refuted.length
					? ["## Refuted", ...refuted.map(({ f, note }) => `- ${f.id} \`${at(f)}\` (${f.scope}): ${f.problem} — ${note}`), ""]
					: []),
				...(gaps.length ? ["## Coverage gaps", ...gaps.map(g => `- ${g}`), ""] : []),
				...(empty ? ["No findings.", ""] : []),
			]
				.join("\n")
				.trimEnd();

			const root = localRoot(ctx);
			await mkdir(root, { recursive: true });
			await writeFile(join(root, "findings.md"), `${report}\n`, "utf8");

			return {
				content: [{ type: "text", text: `${report}\n\n*Saved to \`local://findings.md\`.*` }],
				details: { done: true, verdict },
			};
		},
	});
}
