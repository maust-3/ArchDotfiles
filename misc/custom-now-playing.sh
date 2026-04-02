#!/bin/bash

VISIBLE_MIN=10
SCROLL_FILE="$HOME/.cache/nowplaying_scroll_pos"
MEDIA_FILE="$HOME/.cache/nowplaying_last_track"
PLAYER_FILE="$HOME/.cache/nowplaying_player"

BROWSER_PLAYERS=(firefox)
TAUON_PLAYERS=(tauon tauonmb)

is_browser() {
  for b in "${BROWSER_PLAYERS[@]}"; do
    [[ "$1" == *"$b"* ]] && return 0
  done
  return 1
}

is_tauon() {
  for t in "${TAUON_PLAYERS[@]}"; do
    [[ "$1" == *"$t"* ]] && return 0
  done
  return 1
}

selected_player=""
player_status=""

players=$(playerctl -l 2>/dev/null)

# ---- PASS 1: Playing only (MPD + Tauon) ----
for player in $players; do
  is_browser "$player" && continue

  status=$(playerctl -p "$player" status 2>/dev/null)
  [[ "$status" != "Playing" ]] && continue

  if [[ "$player" == *mpd* ]]; then
    mpc status 2>/dev/null | grep -q "\[playing\]" || continue
  fi

  selected_player="$player"
  player_status="$status"
  break
done

# ---- PASS 2: Paused fallback (Tauon only) ----
if [[ -z "$selected_player" ]]; then
  for player in $players; do
    is_browser "$player" && continue
    [[ "$player" == *mpd* ]] && continue

    status=$(playerctl -p "$player" status 2>/dev/null)
    [[ "$status" != "Paused" ]] && continue

    selected_player="$player"
    player_status="$status"
    break
  done
fi

# ---- Nothing valid → hide module ----
if [[ -z "$selected_player" ]]; then
  rm -f "$SCROLL_FILE" "$MEDIA_FILE" "$PLAYER_FILE"
  exit 0
fi

echo "$selected_player" > "$PLAYER_FILE"

artist=$(playerctl -p "$selected_player" metadata xesam:artist 2>/dev/null)
title=$(playerctl -p "$selected_player" metadata xesam:title 2>/dev/null)

if [[ -z "$artist" && -z "$title" ]]; then
  track=$(cat "$MEDIA_FILE" 2>/dev/null) || exit 0
else
  track="$title • $artist • "
  echo "$track" > "$MEDIA_FILE"
fi

scroll_pos=$(cat "$SCROLL_FILE" 2>/dev/null)
[[ -z "$scroll_pos" ]] && scroll_pos=0

visible_chars=$(( ${#track} / 2 ))
(( visible_chars < VISIBLE_MIN )) && visible_chars=$VISIBLE_MIN

if [[ "$player_status" != "Paused" ]]; then
  scroll_pos=$((scroll_pos + 1))
  (( scroll_pos > ${#track} )) && scroll_pos=0
  echo "$scroll_pos" > "$SCROLL_FILE"
fi

if (( scroll_pos + visible_chars <= ${#track} )); then
  display_text="${track:scroll_pos:visible_chars}"
else
  wrap_len=$(( scroll_pos + visible_chars - ${#track} ))
  display_text="${track:scroll_pos}${track:0:wrap_len}"
fi

echo "{\"text\":\"$display_text\",\"class\":\"${player_status,,}\"}"
