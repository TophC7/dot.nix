# Axophyte

## Before deploying

- Add `secrets.service.discord.axophyte.{token,tavily}` in git-crypt `mix/secrets.nix`. These values enter the Nix store under the repo's existing secrets convention.
- In the Developer Portal, enable **Message Content Intent** and **Server Members Intent** (both privileged); without them login fails. [Invite the bot](https://discord.com/oauth2/authorize?client_id=1557540580962336848&scope=bot+applications.commands&permissions=274877973504) to each server.
- List each server in `servers` in [`default.nix`](default.nix): guild ID → its Axophyte forum ID, or `null` for mentions and replies only. A server the bot isn't in, or whose forum is missing, is skipped with a log line; the others still run.
- Give it View Channel, Read Message History, and Send Messages (in Threads) everywhere it should answer or search.
- Use Tavily's free Researcher plan; **do not enable pay-as-you-go**. Basic search and basic page extraction cost one credit each; free quota is 1,000 credits/month.

## Verify and deploy

From this directory:

```fish
bun install --frozen-lockfile
bun test
bun run typecheck
cd ../../../..
nix build .#nixosConfigurations.zebes.config.system.build.toplevel
bonk switch -H zebes
```

New source files must be tracked by git (`git add -N`) before `nix build`, or the flake drops them. Each service start installs production dependencies from `bun.lock`; registry failure can prevent startup. On Zebes, inspect `journalctl -u axophyte -b`; startup logs `ready … in N/M servers`. Memory lives in `/var/lib/private/axophyte/axophyte.sqlite`; source refreshes do not remove it.

## Behavior

- **Soul:** [`src/soul.ts`](src/soul.ts) is Axophyte's identity, voice, and standing rules, sent at the top of every system prompt. `src/conversation/prompt.ts` appends only per-turn context: where it is, the date, conversation memory, and notes about the people present. Tool guidance lives only in each tool's description.
- **Where it talks:** every message in its server's forum, if that server has one; anywhere else in a configured server, only when `@Axophyte` is mentioned or someone replies to it (no ping needed). Someone already in the current exchange can follow up without mentioning it. `@everyone` and role pings never trigger it.
- **Bursts:** it waits until people stop sending and typing (4 s quiet, 10 s after typing, at most 45 s) and answers exactly the messages that triggered it, by ID. A message arriving before the answer starts streaming (or before it saves a note) restarts the wait.
- **Forum memory:** each forum post is one conversation; older messages compact into persistent memory against the selected model's runtime context, reserving 8,192 answer tokens plus 1,024 headroom. Outside the forum it reads the triggering messages, up to 20 messages before them from the last 30 minutes, and the reply chains they point into (up to 10 older messages); it keeps no conversation memory there.
- **Person memory:** per server: notes and nicknames learned in one server never load in another. It notes what people share about themselves (interests, projects, how they like to talk) as it comes up, so later conversations can build on it; only in channels every member of that server can read. Each note names the message it came from and is stored under that message's author, so nobody can write notes about someone else. Notes load wherever that person talks or is mentioned in the same server. Over 2,000 characters, the model condenses them to about 1,200, keeping what helps conversation over trivia.
- **Tools:** `web_search`, `open_url` (through Tavily Extract; the bot never fetches pages itself), and `search_server` / `read_conversation`. Server search covers the current channel too (minus messages already in view) and only returns channels that everyone who can see the current channel can also read, whoever asks; it is off in private threads. Every round offers the same tools; per-turn budgets and, after 6 tool rounds, every further call are refused with an error telling the model to answer from what it has. It only gives up after 2 refused rounds.
- **Commands:** `/search query:` answers from a web search in any channel; `/memory show` lists your notes in this server; `/memory forget item:<number|all>` deletes them. All servers share one model queue and one Tavily quota.
