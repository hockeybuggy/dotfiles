import { getSupportedThinkingLevels } from "@earendil-works/pi-ai";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

export default function effortExtension(pi: ExtensionAPI) {
	pi.registerCommand("effort", {
		description: "Set thinking level (alias for /thinking)",
		handler: async (args, ctx) => {
			if (!ctx.model) {
				ctx.ui.notify("No model selected", "error");
				return;
			}
			const levels = getSupportedThinkingLevels(ctx.model);
			const searchTerm = args.trim().toLowerCase();
			const level = searchTerm
				? levels.find((candidate) => candidate === searchTerm)
				: await ctx.ui.select("Thinking level", levels);
			if (!level) {
				if (searchTerm) {
					ctx.ui.notify(`Unknown thinking level "${args.trim()}". Available levels: ${levels.join(", ")}.`, "error");
				}
				return;
			}
			pi.setThinkingLevel(level);
			ctx.ui.notify(`Thinking level: ${pi.getThinkingLevel()}`, "info");
		},
	});
}
