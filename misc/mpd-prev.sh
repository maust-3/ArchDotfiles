#!/bin/bash

player=$(cat ~/.cache/nowplaying_player 2>/dev/null) || exit 0

case "$player" in
  *mpd*)
    playerctl -p mpd previous
    ;;
  *)
    playerctl -p "$player" previous
    ;;
esac

