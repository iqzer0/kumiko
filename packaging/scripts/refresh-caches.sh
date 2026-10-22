#!/bin/sh
# Rebuild the system caches Kumiko's files feed: settings schemas, the icon
# cache and the desktop-file database. Distros with package triggers do this
# on their own; running it here covers the rest. Never fails the transaction.
command -v glib-compile-schemas >/dev/null 2>&1 && glib-compile-schemas /usr/share/glib-2.0/schemas >/dev/null 2>&1
command -v gtk-update-icon-cache >/dev/null 2>&1 && gtk-update-icon-cache -q -t -f /usr/share/icons/hicolor >/dev/null 2>&1
command -v update-desktop-database >/dev/null 2>&1 && update-desktop-database -q /usr/share/applications >/dev/null 2>&1
exit 0
