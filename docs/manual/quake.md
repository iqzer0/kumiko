---
title: Quake
parent: Manual
nav_order: 2
layout: default
---

## Overview

Kumiko supports running in a _Quake_-style mode where it appears at the top of the screen and can be toggled on or off on demand. Unlike most terminal emulators that offer this feature, Kumiko does **not** register a global hot key itself — you register one with your desktop environment. Wayland doesn't expose global hot keys to applications, so this is the only portable approach.

When you register the hot key, bind it to the following command:

{% highlight bash %}
kumiko --quake
{% endhighlight %}

When `kumiko --quake` runs, it checks whether a quake-style window already exists and toggles its visibility if so. Otherwise it creates a new one and shows it.

## Configuring the hot key in GNOME

Open **Settings → Keyboard → View and Customize Shortcuts → Custom Shortcuts** and add a new entry:

- **Name** — anything you like (e.g. `kumiko quake`).
- **Command** — `kumiko --quake`.
- **Shortcut** — whatever key combination you want to toggle the window (e.g. `F12`).

## Wayland

Quake mode relies on X11 window-positioning APIs that Wayland compositors don't expose to applications, so behaviour is compositor-dependent. GNOME Shell in particular cannot position windows from the application side.

Two workarounds:

- **Use an X11 session.** Kumiko's desktop file already prefers X11 when available. If you're on a distro that ships Wayland by default, you can force a single Kumiko launch to use X11 with:

  {% highlight bash %}
  GDK_BACKEND=x11 kumiko --quake
  {% endhighlight %}

  To make this permanent, override the bundled desktop file in `~/.local/share/applications/io.github.iqzer0.kumiko.desktop` and set `Exec=env GDK_BACKEND=x11 kumiko --quake`.

- **Use a GNOME Shell quake extension** that handles the positioning on the compositor side, for example [gnome-shell-extension-quake-mode](https://github.com/repsac-by/gnome-shell-extension-quake-mode), which can put any application into quake mode without the app needing native support.

On wlroots-based compositors (Sway, Hyprland, Wayfire), first-class support may arrive in a future release via the `wlr-layer-shell` protocol — see the [ROADMAP](https://github.com/iqzer0/kumiko/blob/master/ROADMAP.md) for status.

## KDE

If the quake window doesn't receive focus on KDE, try disabling the **Focus stealing prevention** feature. This was originally reported against upstream Tilix — see the workaround in [this issue comment](https://github.com/gnunn1/tilix/issues/895#issuecomment-385275324).
