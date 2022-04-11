#!/bin/sh
# vim: ft=sh ts=2 sw=2 et:

# Reminder: This file is intended to be sourced on many shells. It should be 
# usable regardless of environment. Stick to POSIX, and make concessions for
# where common shells (bash, zsh, *ksh) diverge from POSIX, in a way that is
# compatible with the lowest common denominator.

# Export some niceties for use later on
# Where does our config live?
# If we set XDG_CONFIG_HOME prior, respect it. Else, use .config, but try
# to resolve its symlink.
: ${CONF:="$XDG_CONFIG_HOME"}
: ${CONF:="$(test -d "$HOME/.config" && cd -P "$HOME/.config" && pwd -P)"}
: ${CONF:="$HOME/.config"}
export CONF

# Some facts about the environment we're in
export OS="$(uname -s | tr '[:upper:]' '[:lower:]')"

case "$OS" in
  linux)
    if [ -n "$XDG_SESSION_TYPE" ]; then
      GUI="$(printf '%s' "$XDG_SESSION_TYPE" | tr '[:upper:]' '[:lower:]')"
    elif [ -n "$WAYLAND_DISPLAY" ]; then
      GUI=wayland
    elif ps -fe | grep -q '[x]init' && [ -n "$DISPLAY" ]; then
      GUI=x11
    fi
    ;;
  darwin)
    if ps -fe | grep -q '[W]indowServer'; then
      GUI=aqua
    elif ps -fe | grep -q '[x]init' && [ -n "$DISPLAY" ]; then
      GUI=x11
    fi
    ;;
esac
export GUI

# Some useful functions we'll use multiple times
quiet() {
  # If we're not connected to a terminal, then don't suppress stdout -- so that
  # quiet can be used inside pipelines without wrapping the whole thing.
  if [ -t 1 ]; then
    "$@" >/dev/null 2>/dev/null
  else
    "$@" 2>/dev/null
  fi
}

has() {
  quiet command -v "$1"
}

isgnu() {
  quiet command -v "$1" && quiet "$1" --version | grep -q GNU
}

# profile.d
if [ -d "$CONF/profile.d" ]; then
  for f in "$CONF"/profile.d/*; do
    [ -x "$f" ] && . "$f"
  done
fi
unset f
