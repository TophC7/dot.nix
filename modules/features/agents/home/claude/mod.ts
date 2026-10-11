// DATA is prepended by default.nix from the shared workflow catalog.
import type { Register } from "claude-code";

export const register: Register = on => {

  on("session.start", async ($, e, next) => {
    await $.command.register({
      name: "macro",
      description: "Insert a Markdown prompt macro",
      argumentHint: "[name]",
    });
    return next(e);
  });

  on("command.run", { command: "macro" }, async ($, e) => {
    const requested = e.args.trim();
    let macro: (typeof DATA.macros)[number] | undefined;
    if (requested) {
      const wanted = requested.toLowerCase();
      macro = DATA.macros.find(entry =>
        entry.id.toLowerCase() === wanted || entry.name.toLowerCase() === wanted,
      );
      if (!macro) return { text: `Unknown macro "${requested}".` };
    } else {
      const byLabel = new Map<string, (typeof DATA.macros)[number]>();
      const labels = DATA.macros.map(entry => {
        const label = byLabel.has(entry.name) ? `${entry.name} (${entry.id})` : entry.name;
        byLabel.set(label, entry);
        return label;
      });
      // Native ask accepts four options; page rather than hide the remaining macros.
      for (let offset = 0; offset < labels.length; offset += 3) {
        const remaining = labels.slice(offset);
        const options = remaining.length > 4
          ? [...remaining.slice(0, 3), "More macros…"]
          : remaining;
        const selected = await $.ui.ask("Insert macro?", options);
        if (selected !== "More macros…") {
          macro = byLabel.get(selected);
          break;
        }
      }
      if (!macro) return {};
    }
    await $.prompt.fill({ text: macro.body });
    return {};
  });
};
