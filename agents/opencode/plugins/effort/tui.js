export default {
  id: "effort",

  setup(ctx) {
    const { model, toast } = ctx.ui

    const apply = (variant) => {
      if (model.variant.set(variant)) {
        toast.show({ message: `Effort set to ${variant ?? "default"}`, variant: "success" })
        return
      }
      const available = model.variant.list()
      toast.show({
        message: available.length
          ? `Unknown effort "${variant}". Try: ${available.join(", ")}`
          : "The current model has no effort levels",
        variant: "error",
      })
    }

    ctx.keymap.layer(() => ({
      mode: "global",
      commands: [
        {
          id: "effort.set",
          title: "Set effort",
          group: "Agent",
          slash: { name: "effort", arguments: true },
          run: (input) => {
            const variant = input?.trim().toLowerCase()
            if (!variant) return ctx.keymap.dispatch("variant.list")
            apply(variant === "default" ? undefined : variant)
          },
        },
      ],
    }))
  },
}
