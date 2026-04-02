#!/bin/bash

player=$(cat ~/.cache/nowplaying_player 2>/dev/null) || exit 0

case "$player" in
  *mpd*)
    playerctl -p mpd play-pause
    ;;
  *)
    playerctl -p "$player" play-pause
    ;;
esac

