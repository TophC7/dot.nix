window.__ModuleLoader__.load({
  id: "toph-workflow",
  factory: () => ({
    inject: ["inputTriggers", "conversation", "sessions"],
    apply(ctx) {
      const macros = window.__TOPH_WORKFLOW_MACROS__ ?? [];
      const find = (requested) => macros.find((macro) =>
        macro.id.toLowerCase() === requested || macro.name.toLowerCase() === requested);
      ctx.effect(() => ctx.inputTriggers.registerSource({
        trigger: "/",
        name: "macro",
        order: 10,
        async candidates(_session, req) {
          // List macros while `/macro` is still being typed, then filter by name.
          const typed = req.query.toLowerCase();
          const match = "macro".startsWith(typed) ? [typed, ""] : /^macro\s+(.*)$/.exec(typed);
          if (!match) return [];
          const query = match[1].trim();
          return macros.filter((macro) => macro.id.toLowerCase().startsWith(query)
            || macro.name.toLowerCase().startsWith(query)).map((macro) => ({
              name: `macro ${macro.id}`,
              description: macro.summary,
            }));
        },
        onPick({ candidate }) {
          const macro = find(candidate.name.slice("macro ".length).toLowerCase());
          return macro ? { text: macro.body } : undefined;
        },
        async matchEnter(session, line) {
          const match = /^\/macro\s+(.+)$/i.exec(line);
          if (!match) return undefined;
          const macro = find(match[1].trim().toLowerCase());
          if (!macro) return undefined;
          ctx.conversation.input.for(ctx.sessions.scope(session.sessionId)).setDraft(macro.body);
          return "handled";
        },
      }), "workflow: macro source");
    },
  }),
});
