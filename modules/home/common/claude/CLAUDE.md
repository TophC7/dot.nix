# Global Claude Instructions

## MANDATORY: Agent Dispatch Protocol

> **CRITICAL**: This protocol is NOT optional. You MUST follow it for EVERY substantive user request.

### Pre-Task Checkpoint (REQUIRED)

**BEFORE taking ANY action on a user request, STOP and complete this checklist:**

1. **Identify task type** — What am I being asked to do?
2. **Check mandatory dispatch** — Does this task type REQUIRE an agent? (See table below)
3. **Check keyword triggers** — Do any keywords match an agent?
4. **Invoke agent(s) FIRST** — Use `Task` tool with appropriate `subagent_type`
5. **Announce dispatch** — Tell the user which agent(s) you're invoking and why

**If you skip this checkpoint and work directly, you are violating instructions.**
**If you catch yourself doing manual work that an agent handles, STOP and restart with agent dispatch.**

---

### Mandatory Dispatch by Task Type

These task types ALWAYS require agent dispatch — no exceptions, regardless of keywords:

| Task Type                      | ALWAYS Dispatch          | Even If...                                  |
| ------------------------------ | ------------------------ | ------------------------------------------- |
| Exploring/analyzing codebase   | `Explore`                | "Just a quick look" — still dispatch        |
| Writing ANY documentation      | `documentation-engineer` | READMEs, specs, guides, comments            |
| Nix/NixOS configuration        | `nix-pro`                | Flakes, modules, derivations, Home Manager  |
| mix.nix library work           | `mix-nix`                | Host specs, lib.fs.*, lib.hosts.*, theming  |
| Svelte/SvelteKit work          | `svelte-pro`             | Components, stores, routing, runes          |
| React work                     | `react-specialist`       | Components, hooks, state                    |
| Debugging ANY error            | `debugger`               | Stack traces, crashes, unexpected behavior  |
| Code review                    | `code-reviewer`          | Or `adversarial-code-reviewer` for thorough |
| Writing tests                  | `test-automator`         | Unit, integration, E2E                      |
| Prompt/instruction improvement | `prompt-engineer`        | Meta-work on LLM instructions               |
| TypeScript types/interfaces    | `typescript-pro`         | Type definitions, generics, tsconfig        |
| Planning implementation        | `Plan`                   | Multi-step features, architecture decisions |

---

### Dispatch Procedure

1. **STOP** — Do not begin work until you've checked dispatch requirements
2. **MATCH** — Check mandatory table first, then keyword table
3. **INVOKE** — Call `Task` tool with `subagent_type` parameter
4. **ANNOUNCE** — State: "Dispatching [agent] because [reason]"
5. **PROCEED** — Only after agent invocation, continue with the task

---

### Correct vs Wrong Behavior

**User:** "Analyze the codebase structure"
- **CORRECT:** STOP → Check dispatch → Codebase exploration → Invoke `Explore` → Announce → Proceed
- **WRONG:** Manually running Glob/Grep/Read and summarizing

**User:** "Write a README for this project"
- **CORRECT:** STOP → Check dispatch → Documentation → Invoke `documentation-engineer` → Announce → Proceed
- **WRONG:** Writing the README directly without agent

**User:** "Fix this Svelte component"
- **CORRECT:** STOP → Check dispatch → Svelte + debugging → Invoke `svelte-pro` + `debugger` → Announce → Proceed
- **WRONG:** Diving into the code without specialist consultation

**User:** "Create a specs document for this feature"
- **CORRECT:** STOP → Check dispatch → Documentation → Invoke `documentation-engineer` or `technical-writer` → Proceed
- **WRONG:** Writing the spec yourself

**User:** "The agent dispatch isn't working well"
- **CORRECT:** STOP → Check dispatch → Prompt improvement → Invoke `prompt-engineer` → Proceed
- **WRONG:** Trying to fix the instructions yourself

**User:** "Add a new NixOS module for my service"
- **CORRECT:** STOP → Check dispatch → Nix work → Invoke `nix-pro` → Announce → Proceed
- **WRONG:** Writing the module without Nix specialist

**User:** "Update the host spec to add a new option"
- **CORRECT:** STOP → Check dispatch → mix.nix library → Invoke `mix-nix` → Announce → Proceed
- **WRONG:** Editing lib.hosts without library specialist

---

## Keyword-Triggered Dispatch Reference

When these keywords appear, dispatch the corresponding agent:

### Core Development Agents

| Keywords                                                           | Agent                       | Use When             |
| ------------------------------------------------------------------ | --------------------------- | -------------------- |
| error, bug, crash, exception, stack trace, debug, not working      | `debugger`                  | Something is broken  |
| code review, PR, pull request, review code, check code             | `code-reviewer`             | Standard code review |
| thorough review, find problems, aggressive review, validate claims | `adversarial-code-reviewer` | Rigorous validation  |
| refactor, clean up, simplify, reduce complexity, technical debt    | `refactoring-specialist`    | Restructuring code   |
| write tests, test coverage, unit test, integration test, E2E       | `test-automator`            | Creating tests       |

### Language-Specific Agents

| Keywords                                               | Agent               | Use When               |
| ------------------------------------------------------ | ------------------- | ---------------------- |
| Nix, NixOS, flake, derivation, nixpkgs, Home Manager   | `nix-pro`           | Nix/NixOS development  |
| JavaScript, JS, ES2023, Node.js, vanilla JS, async     | `javascript-pro`    | JavaScript development |
| TypeScript, TS, type safety, tsconfig, types           | `typescript-pro`    | TypeScript development |
| Python, Python 3.11, data science, pandas, numpy       | `python-pro`        | Python development     |
| Rust, systems programming, memory safety, Cargo        | `rust-engineer`     | Rust development       |
| React, React 18, hooks, component, Redux, Next.js, JSX | `react-specialist`  | React development      |
| Svelte, SvelteKit, runes, $state, $derived, reactivity | `svelte-pro`        | Svelte development     |
| SQL, database, query, PostgreSQL, MySQL, optimization  | `sql-pro`           | Database/SQL work      |
| GraphQL, federation, subscriptions, Apollo, schema     | `graphql-architect` | GraphQL API design     |

### Library-Specific Agents

| Keywords                                               | Agent               | Use When               |
| ------------------------------------------------------ | ------------------- | ---------------------- |
| mix.nix, lib.fs, lib.hosts, hostSpec, userSpec, matugen | `mix-nix`          | mix.nix library usage  |

### Frontend & UI Agents

| Keywords                                            | Agent                  | Use When              |
| --------------------------------------------------- | ---------------------- | --------------------- |
| frontend, Vue, UI, CSS, responsive, styling         | `frontend-developer`   | Frontend development  |
| UI design, visual design, interface, interaction    | `ui-designer`          | UI/visual design      |
| UX research, user research, usability, user testing | `ux-researcher`        | Research/UX analysis  |
| accessibility, WCAG, a11y, screen reader, ADA       | `accessibility-tester` | Accessibility testing |

### Backend & Infrastructure

| Keywords                                      | Agent                 | Use When                     |
| --------------------------------------------- | --------------------- | ---------------------------- |
| backend, server, API, endpoint, microservices | `backend-developer`   | Server-side development      |
| fullstack, full-stack, end-to-end feature     | `fullstack-developer` | Complete feature development |
| deploy, deployment, CI/CD, pipeline, release  | `deployment-engineer` | Deployment & release         |
| DevOps, infrastructure, Docker, Kubernetes    | `devops-engineer`     | Infrastructure & operations  |
| network, cloud architecture, zero-trust       | `network-engineer`    | Network & infrastructure     |
| WebSocket, real-time, Socket.io, messaging    | `websocket-engineer`  | Real-time communication      |

### Security & Compliance

| Keywords                                           | Agent                | Use When              |
| -------------------------------------------------- | -------------------- | --------------------- |
| security, vulnerability, CVE, auth, injection, XSS | `security-engineer`  | Security concerns     |
| compliance, GDPR, HIPAA, PCI DSS, audit            | `compliance-auditor` | Compliance/regulatory |

### Performance & Monitoring

| Keywords                                              | Agent                  | Use When                 |
| ----------------------------------------------------- | ---------------------- | ------------------------ |
| slow, performance, optimize, latency, bottleneck      | `performance-engineer` | Performance optimization |
| monitoring, metrics, anomaly detection, observability | `performance-monitor`  | System monitoring        |

### Documentation & Writing

| Keywords                                           | Agent                    | Use When                 |
| -------------------------------------------------- | ------------------------ | ------------------------ |
| document, documentation, README, write docs, specs | `documentation-engineer` | Technical documentation  |
| API documentation, OpenAPI, Swagger                | `api-documenter`         | API documentation        |
| writing, technical writing, user guide, tutorial   | `technical-writer`       | Technical writing        |
| SEO, search, ranking, structured data              | `seo-specialist`         | SEO/content optimization |

### API & Architecture

| Keywords                                          | Agent          | Use When        |
| ------------------------------------------------- | -------------- | --------------- |
| API design, REST, endpoints, schema, architecture | `api-designer` | API design work |

### Build & Tools

| Keywords                                              | Agent                  | Use When             |
| ----------------------------------------------------- | ---------------------- | -------------------- |
| build, compilation, Webpack, Vite, build optimization | `build-engineer`       | Build system issues  |
| CLI, command-line, terminal, tool development         | `cli-developer`        | CLI tool development |
| git, branching, merge, version control, rebase        | `git-workflow-manager` | Git/version control  |

### Prompt & LLM

| Keywords                                                 | Agent             | Use When          |
| -------------------------------------------------------- | ----------------- | ----------------- |
| prompt, LLM, optimize prompt, few-shot, chain-of-thought | `prompt-engineer` | LLM prompt design |

### System & Resilience

| Keywords                                             | Agent                   | Use When                |
| ---------------------------------------------------- | ----------------------- | ----------------------- |
| chaos, resilience, failure injection, load test      | `chaos-engineer`        | Resilience testing      |
| workflow, orchestration, process automation          | `workflow-orchestrator` | Workflow design         |
| error handling, failure recovery, error coordination | `error-coordinator`     | Error handling strategy |
| error analysis, root cause, error pattern, logs      | `error-detective`       | Error pattern analysis  |

### Multi-Agent Coordination

| Keywords                                        | Agent                     | Use When                  |
| ----------------------------------------------- | ------------------------- | ------------------------- |
| multi-agent, agent orchestration, team assembly | `agent-organizer`         | Multi-agent system design |
| parallel execution, dependencies, coordination  | `multi-agent-coordinator` | Multi-agent orchestration |
| knowledge synthesis, patterns, insights         | `knowledge-synthesizer`   | Knowledge extraction      |
| context management, state, information sharing  | `context-manager`         | Context/state management  |

---

## Dispatch Rules Summary

1. **STOP First**: Always pause before starting work
2. **Mandatory Table**: Check task-type dispatch requirements (always applies)
3. **Keyword Table**: Check for keyword matches (additional triggers)
4. **Invoke**: Use `Task` tool with `subagent_type` parameter
5. **Announce**: Tell the user which agent and why
6. **Compound Tasks**: Multiple agents can be invoked sequentially
7. **User Override**: User explicit request supersedes automatic dispatch
8. **Ambiguity**: If unclear, ask user which agent fits best

---

## Self-Verification

After completing any task, ask yourself:
- Did I dispatch appropriate agents?
- Did I work manually on something an agent handles?
- Should I have consulted a specialist I skipped?

If you realize you skipped agent dispatch, acknowledge the mistake and offer to redo with proper dispatch.
