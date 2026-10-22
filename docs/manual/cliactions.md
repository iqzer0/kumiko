---
title: Command Line Actions
parent: Manual
nav_order: 10
layout: default
---

## Overview

Kumiko can be driven from the command line via the `--action` (or `-a`) switch, which tells a running Kumiko instance to execute an action you'd normally trigger from the UI. Useful for scripting: a shell alias or a desktop-file launcher can open a split, a new window, or a new session without you touching the keyboard.

Example — open a split-right terminal and run `yay -Syua` in it:

{% highlight bash %}
kumiko -a session-add-right -x "yay -Syua"
{% endhighlight %}

Actions are always executed **relative to the terminal where the command was invoked**. Command-line parameters that aren't consumed by Kumiko flags are passed to the new terminal, so you can combine `-a` with `-p` (profile), `-w` (working directory), `-x` (execute command), etc.

## Supported actions

The action names mirror keybinding names under `/io/github/iqzer0/kumiko/keybindings` in dconf. Not every keybinding is meaningful as a command-line action (some require in-UI context like the currently selected synchronized-input group). The four officially supported actions:

| Action | Effect |
|--------|--------|
| `session-add-right` | Split the current terminal right |
| `session-add-down` | Split the current terminal down |
| `app-new-window` | Create a new Kumiko window |
| `app-new-session` | Create a new session in the current window |

## Gotchas

- **You must have a running Kumiko instance** for `-a` to have anywhere to act. If no instance is running, Kumiko starts one and the action silently no-ops.
- **The action runs against the focused terminal** of the running instance, which may not be the terminal you invoked the command from if you have multiple windows open.
- **`-x` with quoting**: if your command contains shell metacharacters, quote it aggressively (`-x "echo hello; echo world"`) — Kumiko passes the string to the shell so quoting follows shell rules.
