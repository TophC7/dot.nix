---
name: UI Screens
summary: Exercise UI changes via CDP browser automation and capture screenshots
---

Run through the UI to test and capture screenshots of all notable changes and new features via browser automation (CDP).

1. **Detect Changes**: Check recent commits and git diff to identify touched pages, components, and interactive user flows.
2. **Start / Verify Stack**: Verify local dev servers or services are running. If down, launch them using the repository's standard dev scripts or commands.
3. **Authenticate & Navigate**: Drive the browser via CDP (`browser` object in eval, relay, or managed Chromium). Navigate to the relevant views, authenticating with test/seed credentials or injecting auth tokens/storage if required.
4. **Exercise Flows**: Exercise each changed workflow in the browser—test buttons, inputs, dropdowns, modals, tabs, and edge states (empty states, errors, loading).
5. **Take Screenshots**: Capture full-page or focused element screenshots (`tab.screenshot(...)`) of all notable additions and save them to `screens/` with descriptive kebab-case names.
6. **Subagents**: When delegating exploration, interactions, or captures to subagents, use the `@smol` role (`model: "@smol"`).

Finish with a bulleted list of saved screenshots and the concrete UI change or state each one demonstrates.
