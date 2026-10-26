export default {
  id: "model-alias",

  setup(ctx) {
    ctx.keymap.layer(() => ({
      mode: "global",
      commands: [
        {
          id: "model-alias.list",
          title: "Switch model",
          group: "Agent",
          slash: { name: "model" },
          run: () => ctx.keymap.dispatch("model.list"),
        },
      ],
    }))
  },
}
