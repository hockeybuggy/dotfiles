export default {
  id: "model-alias",

  setup(ctx) {
    const models = () => {
      const location = ctx.location ?? ctx.data.location.default()
      return (ctx.data.location.model.list(location) ?? []).filter((model) => model.status !== "deprecated")
    }

    const matching = (query) => {
      const candidates = models()
      const exact = candidates.filter((model) => [model.id, model.name].some((key) => key.toLowerCase() === query))
      if (exact.length) return exact
      return candidates.filter((model) => [model.id, model.name].some((key) => key.toLowerCase().includes(query)))
    }

    // Plugins can't select a model, so drive the built-in picker by typing
    // into its search box through the renderer's stdin handler.
    const type = async (text) => {
      await ctx.renderer.idle()
      ctx.renderer.stdinListener(Buffer.from(text))
    }

    ctx.keymap.layer(() => ({
      mode: "global",
      commands: [
        {
          id: "model-alias.list",
          title: "Switch model",
          group: "Agent",
          slash: { name: "model", arguments: true },
          run: async (input) => {
            const query = input?.trim().toLowerCase()
            ctx.keymap.dispatch("model.list")
            if (!query) return
            const matches = matching(query)
            if (matches.length !== 1) return type(query)
            await type(matches[0].name)
            await type("\r")
          },
        },
      ],
    }))
  },
}
