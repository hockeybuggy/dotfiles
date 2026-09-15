import assert from "node:assert/strict";
import { test } from "node:test";
import exitExtension from "../agents/extensions/exit.ts";

test("/exit aborts before requesting shutdown", async () => {
	const commands = new Map();
	exitExtension({ registerCommand: (name, command) => commands.set(name, command) });
	const calls = [];
	await commands.get("exit").handler("", {
		abort: () => calls.push("abort"),
		shutdown: () => calls.push("shutdown"),
	});
	assert.deepEqual(calls, ["abort", "shutdown"]);
});
