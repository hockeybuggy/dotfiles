---
name: caffeinate
description: "Keep the computer awake for a set duration or while a command runs, using `caffeinate` on macOS. Use when the user wants to prevent sleep during a long-running task, download, or presentation."
---

# caffeinate Skill

Prevent the machine from going to sleep. On macOS this wraps the
built-in `caffeinate` command; on Linux it falls back to
`systemd-inhibit` (or a `sleep` loop if neither is available).

## When to use

- Keeping the machine awake for a fixed window (a download, a long
  build, a presentation).
- Keeping it awake for the lifetime of a specific command.

For anything trivial that finishes on its own quickly, there's no
need to bother.

## macOS

The relevant flags:

- `-d` prevent the **display** from sleeping
- `-i` prevent the **system** from idle sleeping
- `-m` prevent the **disk** from idle sleeping
- `-s` prevent sleep while on **AC power**
- `-u` declare the **user** is active (asserts for `-t` seconds)
- `-t <seconds>` assert for a fixed duration, then exit
- `-w <pid>` wait for a process to finish, then stop asserting

### Stay awake for a fixed duration

Keep the system (and display) awake for one hour, then let it sleep:

```bash
caffeinate -dimsu -t 3600
```

Run it in the background so the shell stays free:

```bash
caffeinate -dimsu -t 3600 &
```

### Stay awake while a command runs

`caffeinate` keeps the assertion until the wrapped command exits:

```bash
caffeinate -dimsu ./long-build.sh
```

### Stay awake until an existing process finishes

Wait on a PID that's already running:

```bash
caffeinate -dimsu -w 12345 &
```

### Stopping it early

If launched in the background, note the PID it prints (or use
`jobs -l`) and kill it:

```bash
kill %1        # by job number
kill <pid>     # by PID
```

A `-t` invocation also stops on its own once the timer elapses.

## Linux fallback

macOS `caffeinate` doesn't exist here. Prefer `systemd-inhibit`:

```bash
# Fixed duration (1 hour)
systemd-inhibit --what=idle:sleep --why="Keep awake" sleep 3600

# For the lifetime of a command
systemd-inhibit --what=idle:sleep --why="Keep awake" ./long-build.sh
```

If `systemd-inhibit` isn't available, tools like `caffeine`,
`xdotool`, or a simple background `sleep` loop are options, but they
vary by desktop environment — check what's installed first.

## Tips

- Combine `-t` with a wrapped command sparingly: `-t` and a command
  argument together will assert for the duration *or* until the
  command exits, whichever the version supports — prefer one or the
  other.
- `-u` without `-t` defaults to a short (~5s) assertion, so pair
  `-u` with `-t` when you want a specific window.
- Backgrounding with `&` is the usual pattern so the agent can keep
  working while the machine stays awake.
