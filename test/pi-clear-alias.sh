#!/usr/bin/env bash
# Verify that /clear is installed as a global Pi extension and starts a session.

set -euo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
EXTENSION="$ROOT/agents/extensions/clear.ts"
TMPDIR_ROOT=$(mktemp -d)
trap 'rm -rf "$TMPDIR_ROOT"' EXIT

fail() {
    echo "FAIL: $*" >&2
    exit 1
}

[ -f "$EXTENSION" ] || fail "missing /clear extension: $EXTENSION"

home="$TMPDIR_ROOT/home"
true_bin=$(command -v true)
mkdir -p "$home"
(
    cd "$ROOT"
    HOME="$home" TERM=xterm DOTFILES_SETUP_SCRIPT="$true_bin" \
        ./bootstrap.sh --minimal >/dev/null
)

link="$home/.pi/agent/extensions/clear.ts"
[ -L "$link" ] || fail "Pi /clear extension was not linked"
[ "$(readlink "$link")" = "$EXTENSION" ] || fail "Pi /clear extension points at the wrong file"

node - "$home" "$TMPDIR_ROOT/sessions" <<'NODE'
const { spawn } = require("node:child_process");

const [home, sessionDir] = process.argv.slice(2);
const pi = spawn("pi", [
	"--offline",
	"--no-context-files",
	"--mode", "rpc",
	"--session-dir", sessionDir,
], {
	env: { ...process.env, HOME: home },
	stdio: ["pipe", "pipe", "pipe"],
});

const pending = new Map();
let output = "";
let stderr = "";

function fail(message) {
	console.error(`FAIL: ${message}`);
	console.error(stderr || output);
	pi.kill();
	process.exit(1);
}

function send(type, data = {}) {
	const id = crypto.randomUUID();
	pi.stdin.write(`${JSON.stringify({ id, type, ...data })}\n`);
	return new Promise((resolve, reject) => {
		const timeout = setTimeout(() => {
			if (pending.delete(id)) reject(new Error(`timed out waiting for ${type}`));
		}, 10_000);
		pending.set(id, { resolve, reject, timeout });
	});
}

pi.stdout.setEncoding("utf8");
pi.stdout.on("data", (chunk) => {
	output += chunk;
	const lines = output.split("\n");
	output = lines.pop();
	for (const line of lines) {
		if (!line) continue;
		const message = JSON.parse(line);
		if (message.type !== "response" || !message.id) continue;
		const request = pending.get(message.id);
		if (!request) continue;
		pending.delete(message.id);
		clearTimeout(request.timeout);
		message.success ? request.resolve(message.data) : request.reject(new Error(message.error));
	}
});
pi.stderr.setEncoding("utf8");
pi.stderr.on("data", (chunk) => { stderr += chunk; });
pi.on("error", (error) => fail(`could not start Pi: ${error.message}`));

(async () => {
	try {
		const commands = await send("get_commands");
		if (!commands.commands.some((command) => command.name === "clear")) {
			fail("/clear is not registered");
		}
		const before = await send("get_state");
		await send("prompt", { message: "/clear" });
		const after = await send("get_state");
		if (!before.sessionFile || !after.sessionFile || before.sessionFile === after.sessionFile) {
			fail("/clear did not start a new session");
		}
		pi.stdin.end();
	} catch (error) {
		fail(error instanceof Error ? error.message : String(error));
	}
})();
NODE

echo "Pi /clear alias tests passed"
