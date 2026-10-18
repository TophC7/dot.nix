---
name: PR UI Screens
summary: Capture UI screenshots via CDP and attach directly to the PR summary
---

Exercise the UI changes via CDP browser automation, capture screenshots, and attach them to the PR summary.

1. **Detect Changes**: Check recent commits and git diff to identify touched pages, components, and interactive flows.
2. **Start Stack**: Verify local services are running (`localhost:5173` / `localhost:9113`). If down, launch via `dev.fish` (or `../dev.fish`).
3. **Authenticate**: Log in using seeded credentials (e.g. `sarah.rivera@lakeside-psych.example` / `password123`) or inject auth tokens/storage to reach the relevant views.
4. **Drive & Capture**: Exercise each changed workflow—interactions, dropdowns, modals, and edge states—and save focused screenshots (`tab.screenshot(...)`) to `screens/` (or `../screens/`) with descriptive kebab-case names.
5. **Attach to PR**: Upload via `gh pr edit <PR> --body-file <BODY> --attach <FILE>...` (or `gh pr create`). Reference relative local paths in the body markdown (e.g. `![State](./screens/feature.png)`) so `gh` rewrites them to `user-attachments` URLs. Never commit screenshots to git or artifact branches (raw links 404 in private repos). Clean up local screenshot/body files after verifying.
6. **Subagents**: When delegating exploration, interactions, or captures to subagents, use the `@smol` role (`model: "@smol"`).

PR or additional guidance: {{cursor}}
