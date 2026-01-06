# Global Claude Instructions

## Agent Dispatch Matrix

Automatically invoke specialized agents based on task patterns and keywords.

### Core Development Agents

| Keywords                                                                         | Agent                       | Use When                            |
| -------------------------------------------------------------------------------- | --------------------------- | ----------------------------------- |
| error, bug, crash, exception, stack trace, debug, not working                    | `debugger`                  | Something is broken, need diagnosis |
| code review, PR, pull request, review code, check code, feedback                 | `code-reviewer`             | Standard code review                |
| thorough review, find problems, aggressive review, validate claims, code quality | `adversarial-code-reviewer` | Need rigorous validation of work    |
| refactor, clean up, simplify, reduce complexity, technical debt, code smell      | `refactoring-specialist`    | Restructuring existing code         |
| write tests, test coverage, unit test, integration test, E2E test, automation    | `test-automator`            | Creating or improving tests         |

### Language-Specific Agents

| Keywords                                                          | Agent               | Use When                     |
| ----------------------------------------------------------------- | ------------------- | ---------------------------- |
| JavaScript, JS, ES2023, Node.js, vanilla JS, async                | `javascript-pro`    | JavaScript development       |
| TypeScript, TS, type safety, tsconfig, types                      | `typescript-pro`    | TypeScript development       |
| Python, Python 3.11, data science, pandas, numpy                  | `python-pro`        | Python development           |
| Rust, systems programming, memory safety, WebAssembly, Cargo      | `rust-engineer`     | Rust development             |
| React, React 18, hooks, component, Redux, Next.js, JSX            | `react-specialist`  | React development            |
| Svelte, SvelteKit, runes, $state, $derived, component, reactivity | `svelte-pro`        | Svelte/SvelteKit development |
| SQL, database, query, PostgreSQL, MySQL, optimization, index      | `sql-pro`           | Database/SQL work            |
| GraphQL, federation, subscriptions, Apollo, schema                | `graphql-architect` | GraphQL API design           |

### Frontend & UI Agents

| Keywords                                                           | Agent                  | Use When              |
| ------------------------------------------------------------------ | ---------------------- | --------------------- |
| frontend, React, Vue, UI, component, CSS, responsive, styling      | `frontend-developer`   | Frontend development  |
| UI design, visual design, interface, interaction, design system    | `ui-designer`          | UI/visual design work |
| UX research, user research, usability, user testing, user insights | `ux-researcher`        | Research/UX analysis  |
| accessibility, WCAG, a11y, screen reader, inclusive design, ADA    | `accessibility-tester` | Accessibility testing |

### Backend & Infrastructure

| Keywords                                                            | Agent                 | Use When                     |
| ------------------------------------------------------------------- | --------------------- | ---------------------------- |
| backend, server, API, endpoint, microservices, architecture         | `backend-developer`   | Server-side development      |
| fullstack, full-stack, end-to-end feature, database to UI           | `fullstack-developer` | Complete feature development |
| deploy, deployment, CI/CD, pipeline, release automation             | `deployment-engineer` | Deployment & release         |
| DevOps, infrastructure, operations, container, Docker, Kubernetes   | `devops-engineer`     | Infrastructure & operations  |
| network, networking, cloud architecture, security, zero-trust       | `network-engineer`    | Network & infrastructure     |
| WebSocket, real-time, realtime, Socket.io, messaging, bidirectional | `websocket-engineer`  | Real-time communication      |

### Security & Compliance

| Keywords                                                 | Agent                | Use When                   |
| -------------------------------------------------------- | -------------------- | -------------------------- |
| security, vulnerability, CVE, auth, injection, XSS, CSRF | `security-engineer`  | Security concerns          |
| compliance, GDPR, HIPAA, PCI DSS, audit, regulation      | `compliance-auditor` | Compliance/regulatory work |

### Performance & Monitoring

| Keywords                                                      | Agent                  | Use When                 |
| ------------------------------------------------------------- | ---------------------- | ------------------------ |
| slow, performance, optimize, latency, bottleneck, profiling   | `performance-engineer` | Performance optimization |
| monitoring, metrics, anomaly detection, observability, alerts | `performance-monitor`  | System monitoring        |

### Documentation & Writing

| Keywords                                                  | Agent                    | Use When                 |
| --------------------------------------------------------- | ------------------------ | ------------------------ |
| document, documentation, README, API docs, write docs     | `documentation-engineer` | Technical documentation  |
| API documentation, OpenAPI, Swagger, write API docs       | `api-documenter`         | API documentation        |
| writing, technical writing, user guide, tutorial, content | `technical-writer`       | Technical writing        |
| SEO, search, ranking, structured data, optimization       | `seo-specialist`         | SEO/content optimization |

### API & Architecture

| Keywords                                                   | Agent          | Use When        |
| ---------------------------------------------------------- | -------------- | --------------- |
| API design, REST, GraphQL, endpoints, schema, architecture | `api-designer` | API design work |

### Build & Tools

| Keywords                                                            | Agent                  | Use When             |
| ------------------------------------------------------------------- | ---------------------- | -------------------- |
| build, compilation, build system, Webpack, Vite, build optimization | `build-engineer`       | Build system issues  |
| CLI, command-line, terminal, tool development, arguments            | `cli-developer`        | CLI tool development |
| git, branching, merge, version control, rebase, workflow            | `git-workflow-manager` | Git/version control  |

### Prompt & LLM

| Keywords                                                        | Agent             | Use When          |
| --------------------------------------------------------------- | ----------------- | ----------------- |
| prompt, LLM, optimize prompt, token, few-shot, chain-of-thought | `prompt-engineer` | LLM prompt design |

### System & Resilience

| Keywords                                                     | Agent                   | Use When                |
| ------------------------------------------------------------ | ----------------------- | ----------------------- |
| chaos, resilience, failure injection, load test, stress test | `chaos-engineer`        | Resilience testing      |
| workflow, orchestration, process automation, state machine   | `workflow-orchestrator` | Workflow design         |
| error handling, failure recovery, error coordination         | `error-coordinator`     | Error handling strategy |
| error analysis, root cause, error pattern, logs, correlation | `error-detective`       | Error pattern analysis  |

### Multi-Agent Coordination

| Keywords                                                            | Agent                     | Use When                  |
| ------------------------------------------------------------------- | ------------------------- | ------------------------- |
| multi-agent, agent orchestration, agent coordination, team assembly | `agent-organizer`         | Multi-agent system design |
| multi-agent coordination, parallel execution, dependencies          | `multi-agent-coordinator` | Multi-agent orchestration |
| knowledge synthesis, patterns, insights, collective learning        | `knowledge-synthesizer`   | Knowledge extraction      |
| context management, state, information sharing                      | `context-manager`         | Context/state management  |

## Dispatch Rules

1. **Keyword Matching**: Scan user request for trigger keywords
2. **Invoke Agent**: When a clear match is found, invoke with: `Task` tool with `subagent_type`
3. **Announce**: State which agent is being used and why
4. **Override**: User explicit request always supersedes automatic dispatch
5. **Ambiguity**: If multiple agents match, ask user which fits best OR use most specific match
6. **Compound Tasks**: For multi-phase work, invoke sequential agents as needed

## Examples

User: "There's a bug in my React component"
→ Triggers: "bug", "React" → Invoke: `debugger` + `react-specialist`

User: "Make sure this code is production ready"
→ Triggers: "production ready", validation → Invoke: `adversarial-code-reviewer`

User: "Design a REST API for user management"
→ Triggers: "design", "REST API" → Invoke: `api-designer`

User: "Slow database queries need optimization"
→ Triggers: "slow", "database" → Invoke: `performance-engineer` + `sql-pro`