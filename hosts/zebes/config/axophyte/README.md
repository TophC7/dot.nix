# Axophyte

## Before deploying

- Add `secrets.service.discord.axophyte.{token,tavily}` in git-crypt `mix/secrets.nix`. These values enter the Nix store under the repo's existing secrets convention.
- Enable Message Content Intent; [invite the bot](https://discord.com/oauth2/authorize?client_id=1557540580962336848&scope=bot+applications.commands&permissions=274877973504). Forum `1557542849275236372` needs View Channel, Read Message History, and Send Messages in Threads.
- Use Tavily's free Researcher plan; **do not enable pay-as-you-go**. Basic search costs one credit; free quota is 1,000 credits/month.

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

Each service start installs production dependencies from `bun.lock`; registry failure can prevent startup. On Zebes, inspect `journalctl -u axophyte -b`. Memory lives in `/var/lib/private/axophyte/axophyte.sqlite`; source refreshes do not remove it.

Each forum post is one conversation; start a new post for a fresh conversation. Older messages automatically compact into persistent memory against the selected model's effective runtime context, reserving 8,192 answer tokens plus 1,024 headroom; model switches recount and compact again if needed. No fixed prompt cap or training-context fallback. `/search` is the only command; the model can also search automatically when useful.
