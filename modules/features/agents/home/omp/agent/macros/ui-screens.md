---
name: UI Screens
summary: Exercise UI changes in browser and capture screenshots to screens/
---

Run through the UI to test and capture screenshots of all notable changes and new features.

1. **Detect Changes**: Check recent commits and git diff to identify touched pages, components, and interactive flows.
2. **Start Stack**: Verify local services are running (`localhost:5173` / `localhost:9113`). If down, launch via `dev.fish` (or `../dev.fish`).
3. **Authenticate**: Log in using seeded credentials (e.g. `sarah.rivera@lakeside-psych.example` / `password123`) or inject auth tokens/storage to reach the relevant views.
4. **Drive Browser**: Exercise each changed workflow in the browser—test interactions, dropdowns, modals, and edge states.
5. **Take Screenshots**: Capture full or focused views of all notable additions and save them to `screens/` (or `../screens/`) with descriptive kebab-case names.
6. **Subagents**: When delegating exploration, interactions, or captures to subagents, use the `@smol` role (`model: "@smol"`).

Finish with a bulleted list of saved screenshots and the concrete UI change each one demonstrates.
