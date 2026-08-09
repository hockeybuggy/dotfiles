---
name: 1password-cli
description: "Use the `op` CLI to sign in, read secrets, and inject them into commands or files via `op run`, `op read`, and `op inject`. Use when the user needs a credential from 1Password, wants a command run with secrets injected as env vars, or needs to manage vaults/items from the terminal."
---

# 1Password CLI Skill

Use the `op` CLI (https://www.1password.dev/cli) to work with 1Password
from the terminal instead of pasting secrets into files or shell history.

## Install

```bash
brew install 1password-cli   # macOS
op --version
```

## Sign in

Prefer the 1Password desktop app integration over `op signin`: enable it
once in the app (Settings > Developer > "Integrate with 1Password CLI"),
then `op` commands authenticate via Touch ID/system prompt automatically —
no session token to manage. `op signin` (with an account shorthand from
`op account list` if more than one) is the fallback when the app isn't
available, e.g. on a headless machine. For scripts/CI, use a service
account token (`OP_SERVICE_ACCOUNT_TOKEN` env var) instead of a personal
sign-in.

Check who's signed in: `op whoami`

## Secret references

Items are addressed with a `op://` reference:

```
op://vault-name/item-name/[section-name/]field-name
```

Get one for an existing item: `op item get <item> --format json | jq .reference`

## Reading and injecting secrets

Never print a secret to stdout and paste it into a file by hand — use one
of these instead:

```bash
# Read a single value
op read "op://Work/GitHub/token"

# Run a command with secrets as env vars, without them touching disk
op run --env-file=.env.template -- npm start

# Expand op:// references inside a template file
op inject -i config.tpl -o config.json
```

An `.env.template` / `config.tpl` file holds `op://` references in place
of values (e.g. `API_KEY=op://Work/GitHub/token`) and is safe to commit;
`op run`/`op inject` resolve the references at run time.

## Items and vaults

```bash
op vault list
op item list --vault Work
op item get Netflix --format json      # structured output, pipe to jq
op item get Netflix --fields password  # single field, plain text
```

## Notes

- Never run `op item delete`, `op vault delete`, or anything else
  destructive without explicit confirmation from the user.
- Prefer `op run`/`op inject` over `op read` piped into a variable — they
  keep the plaintext out of shell history and process listings.
