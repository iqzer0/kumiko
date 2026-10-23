---
title: Home
layout: home
nav_order: 1
description: "Documentation for Kumiko, a tiling terminal emulator for Linux."
permalink: /
---

<p style="text-align: center; margin-top: 1.5rem;">
  <img src="{{ site.baseurl }}/assets/images/logo.svg" alt="Kumiko logo" width="120">
</p>

# Kumiko
{: .fs-9 .text-center }

Tilix, but with a pulse.
{: .fs-6 .fw-300 .text-center }

Kumiko is a tiling terminal emulator for Linux, inspired by and built on [ttyx_](https://github.com/gwelr/ttyx_/) by gwelr and [Tilix](https://github.com/gnunn1/tilix/) by Gerald Nunn. Tilix did amazing work but, with development stalled and a growing list of unaddressed bugs, ttyx_ and now Kumiko pick up where it left off — with a focus on security hardening and responsiveness to modern Linux desktops.
{: .text-center }

<div style="text-align: center; margin: 2rem 0;">
  <a href="{{ site.baseurl }}/install/" class="btn btn-primary fs-5 mr-2">Install</a>
  <a href="{{ site.baseurl }}/manual/" class="btn fs-5 mr-2">Read the manual</a>
  <a href="https://github.com/iqzer0/kumiko" class="btn fs-5">View on GitHub</a>
</div>

---

## What you get

### Tile terminals any way you like

Split horizontally, vertically, nest arbitrarily. Drag and drop terminals within and between windows. Save and restore layouts as sessions. Synchronize input across terminals when you need to drive several at once. Everything that made Tilix the tiling terminal of choice on Linux is still here.

### Security-conscious by default

Paste from the clipboard with review dialogs, dangerous-command detection, and auto-clear after copy. Clear visual indicators when a session is running as root or over SSH. Core-dump protection, in-memory-only scrollback, and a one-shortcut `Secure Clear` for wiping the scrollback when sensitive data has been displayed.

See the [Security features]({{ site.baseurl }}/security/) page for the full list, configuration reference, and an explicit threat model.

### Actively maintained

Kumiko ships bug fixes (crash on malformed OSC 7 URIs, preferences-dialog segfaults, proxy URL construction, focus stealing on terminal restart, …), new color schemes, release-build optimizations, and a growing test suite. Contributions welcome via pull request; the issue tracker is actually read.

See [**What's new vs Tilix**]({{ site.baseurl }}/whats-new/) for the full comparison and the [**changelog**]({{ site.baseurl }}/changelog/) for per-release notes.

---

## Where to next

- [**Install**]({{ site.baseurl }}/install/) — source build with Dub, installed with `install.sh`.
- [**Manual**]({{ site.baseurl }}/manual/) — topic-by-topic reference: titles, Quake mode, triggers, color schemes, profile switching, and more.
- [**Security features**]({{ site.baseurl }}/security/) — paste / clipboard / memory protections, threat model, and configuration reference.
- [**What's new vs Tilix**]({{ site.baseurl }}/whats-new/) — feature-level differences from upstream.
- [**Changelog**]({{ site.baseurl }}/changelog/) — per-release notes.
- [**Migrating to Kumiko**]({{ site.baseurl }}/migrating/) — what Kumiko carries over from ttyx_ or Tilix on first run.
- [**Development**]({{ site.baseurl }}/develop/) — build, test, and debug Kumiko from source; code-style and PR conventions.
- [**Report an issue**](https://github.com/iqzer0/kumiko/issues) — bug reports and feature requests.

---

## About this documentation

Much of the manual content originated in Gerald Nunn's [Tilix](https://github.com/gnunn1/tilix) and is reused under [MPL-2.0](https://github.com/iqzer0/kumiko/blob/master/LICENSE). Adaptation is in progress; see the [documentation tracking issue](https://github.com/iqzer0/kumiko/issues/62) for what's done and what's still open.
