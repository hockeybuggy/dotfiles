---
name: isolating-test-stacks
description: Spin up throwaway service/database stacks for tests, migrations, and ingest without touching the user's real dev stack or live data. Use when a task runs `docker compose`, database migrations, ingest jobs, or any destructive command that could hit a shared or live service. Triggers on "run the migrations", "ingest the data", "spin up the stack", "run the integration tests", or any plan step that starts containers or writes to a database.
allowed-tools: Bash
---

# Isolating Test Stacks

When a task needs real services — a database, a queue, a docker-compose stack —
run them in a **throwaway, per-run environment**. Never operate against the
user's live data or their running dev stack. A stray migration or teardown
against the wrong target is not recoverable.

## Hard rules

- **Never run ingest, migrations, or destructive commands against a live or
  shared database.** Always create a throwaway compose project with its own
  volume:

  ```bash
  export COMPOSE_PROJECT_NAME="test-<plan-id>"   # unique per run
  docker compose -p "$COMPOSE_PROJECT_NAME" up -d
  ```

  The project name namespaces containers, networks, **and volumes**, so the
  data never mixes with the real stack.

- **Never run a global teardown.** `docker compose down --remove-orphans` (or
  any unscoped `down`) kills the user's real dev stack. Scope every teardown to
  the exact project you created:

  ```bash
  docker compose -p "$COMPOSE_PROJECT_NAME" down --volumes
  ```

- **Allocate host ports from a per-run offset** so parallel runs don't collide
  with each other or with the user's services. Assert the result is a valid
  port before starting compose:

  ```bash
  host_port=$(( 20000 + (run_index * 10) ))
  [ "$host_port" -lt 65535 ] || { echo "port out of range: $host_port" >&2; exit 1; }
  ```

## Checklist before starting a stack

- [ ] `COMPOSE_PROJECT_NAME` is set to a unique per-run value
- [ ] The stack has its own volume (not a shared/named volume from the real stack)
- [ ] Host ports come from a per-run offset and are `< 65535`
- [ ] Teardown is scoped to `-p "$COMPOSE_PROJECT_NAME"`, never global
