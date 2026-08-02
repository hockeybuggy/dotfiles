import { homedir } from "node:os";
import { join } from "node:path";

import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

// Pi has no settings.json hook table like Claude Code, so the equivalent
// wiring lives here. Both agents run the same scripts from agents/hooks;
// bootstrap links them into ~/.pi/agent/scripts and ~/.claude/hooks. Pi
// reserves ~/.pi/agent/hooks as the deprecated name for extensions and warns
// when it exists, hence the scripts/ directory.
const HOOKS = join(homedir(), ".pi", "agent", "scripts");

const STARTED = "🤖";
const WORKING = "⚡";
const WAITING = "💬";

export default function notificationsExtension(pi: ExtensionAPI) {
	// Sounds are fire-and-forget: afplay blocks for the length of the clip and
	// no handler should stall the agent waiting on it.
	const sound = (script: string) => {
		void pi.exec("bash", [join(HOOKS, script)]).catch(() => {});
	};

	// Titles are awaited — they're a couple of fast tmux calls, and the reset
	// on shutdown has to land before pi exits.
	const title = (arg: string, cwd: string) =>
		pi
			.exec("bash", [join(HOOKS, "tmux-title.sh"), arg], { cwd })
			.catch(() => {});

	pi.on("session_start", (_event, ctx) => title(STARTED, ctx.cwd));
	pi.on("before_agent_start", (_event, ctx) => title(WORKING, ctx.cwd));

	// Pi prompts on an untrusted project the way Claude Code prompts for
	// permission. Announce it, then leave the decision to pi's built-in flow.
	pi.on("project_trust", async (event) => {
		sound("notify.sh");
		await title(WAITING, event.cwd);
		return { trusted: "undecided" as const };
	});

	// agent_settled rather than agent_end: pi may still auto-retry or compact
	// and keep going after agent_end, which would chime mid-turn.
	pi.on("agent_settled", async (_event, ctx) => {
		sound("done.sh");
		await title(STARTED, ctx.cwd);
	});

	pi.on("session_shutdown", (_event, ctx) => title("--reset", ctx.cwd));
}
