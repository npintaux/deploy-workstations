#!/bin/bash
# Antigravity CLI Status Line — Full Input Showcase
# https://antigravity.google/docs
#
# Demonstrates every field passed via JSON on stdin:
#   workspace.current_dir / project_dir   → directory & project name
#   model.display_name / id               → active model
#   context_window.used_percentage        → context usage bar
#   context_window.remaining_percentage   → remaining context
#   context_window.context_window_size    → max token capacity
#   context_window.current_usage          → input / output / cache token counts
#   session_id                            → session identifier
#   transcript_path                       → path to transcript log
#   cwd                                   → working directory
#   version                               → CLI version
#
# Line 1: dir  branch  model  context-bar  tokens
# Line 2: session  version  project-drift  cache-stats (shown when relevant)
#
# Install:
#   chmod +x statusline.sh
#   cp statusline.sh ~/.gemini/antigravity-cli/statusline.sh
#
# Configure in ~/.gemini/antigravity-cli/settings.json:
#   {
#     "statusLine": {
#       "type": "command",
#       "command": "~/.gemini/antigravity-cli/statusline.sh",
#       "enabled": true
#     }
#   }

input=$(cat)

# ─── Colors (ANSI 256-color) ────────────────────────────────────────────────
RESET="\033[0m"
BOLD="\033[1m"
DIM="\033[2m"

# Palette
FG_DIR="\033[38;5;117m"       # sky blue — directory
FG_BRANCH="\033[38;5;114m"    # soft green — git branch
FG_DIRTY="\033[38;5;214m"     # amber — dirty indicator
FG_MODEL="\033[38;5;183m"     # lavender — model name
FG_OK="\033[38;5;114m"        # green — low context usage
FG_WARN="\033[38;5;214m"      # amber — moderate context usage
FG_CRIT="\033[38;5;203m"      # coral red — high context usage
FG_SEP="\033[38;5;240m"       # dark gray — separators
FG_TOKEN="\033[38;5;249m"     # light gray — token count
FG_CACHE="\033[38;5;73m"      # teal — cache stats
FG_SESSION="\033[38;5;243m"   # medium gray — session / meta
FG_VERSION="\033[38;5;139m"   # muted purple — version

SEP="${FG_SEP} │ ${RESET}"

# ─── Check jq availability ──────────────────────────────────────────────────
if ! command -v jq &>/dev/null; then
  printf "${DIM}[statusline: jq required]${RESET}"
  exit 0
fi

# ─── Extract all JSON fields in a single jq call ────────────────────────────
eval "$(echo "$input" | jq -r '
  @sh "CURRENT_DIR=\(.workspace.current_dir // .cwd // "")",
  @sh "PROJECT_DIR=\(.workspace.project_dir // "")",
  @sh "MODEL_NAME=\(.model.display_name // "")",
  @sh "MODEL_ID=\(.model.id // "")",
  @sh "USED_PCT=\(.context_window.used_percentage // "")",
  @sh "REMAINING_PCT=\(.context_window.remaining_percentage // "")",
  @sh "CTX_SIZE=\(.context_window.context_window_size // 0)",
  @sh "INPUT_TOKENS=\(.context_window.current_usage.input_tokens // 0)",
  @sh "OUTPUT_TOKENS=\(.context_window.current_usage.output_tokens // 0)",
  @sh "CACHE_CREATE=\(.context_window.current_usage.cache_creation_input_tokens // 0)",
  @sh "CACHE_READ=\(.context_window.current_usage.cache_read_input_tokens // 0)",
  @sh "SESSION_ID=\(.session_id // "")",
  @sh "TRANSCRIPT=\(.transcript_path // "")",
  @sh "VERSION=\(.version // "")"
' 2>/dev/null)"

# ─── Helper: format token counts (e.g. 12345 → 12.3k, 1200000 → 1.2M) ─────
fmt_tokens() {
  local n=$1
  if [ "$n" -ge 1000000 ] 2>/dev/null; then
    awk "BEGIN { printf \"%.1fM\", $n / 1000000 }"
  elif [ "$n" -ge 1000 ] 2>/dev/null; then
    awk "BEGIN { printf \"%.1fk\", $n / 1000 }"
  else
    echo "${n}"
  fi
}

# ═══════════════════════════════════════════════════════════════════════════
# LINE 1: Primary status — directory, git, model, context gauge, tokens
# ═══════════════════════════════════════════════════════════════════════════
line1=""

# ─── 1. Directory (workspace.current_dir & workspace.project_dir) ───────────
if [ -n "$CURRENT_DIR" ]; then
  # Show relative path when inside project_dir, otherwise basename
  if [ -n "$PROJECT_DIR" ] && [ "$CURRENT_DIR" != "$PROJECT_DIR" ] && [[ "$CURRENT_DIR" == "$PROJECT_DIR"/* ]]; then
    rel_path="${CURRENT_DIR#"$PROJECT_DIR"/}"
    proj_name="${PROJECT_DIR##*/}"
    dir_display="${proj_name}/${rel_path}"
  else
    dir_display="${CURRENT_DIR##*/}"
    [ -z "$dir_display" ] && dir_display="/"
  fi
  line1+="${FG_DIR}${BOLD} ${dir_display}${RESET}"
fi

# ─── 2. Git branch + status ─────────────────────────────────────────────────
if [ -n "$CURRENT_DIR" ] && git -C "$CURRENT_DIR" rev-parse --git-dir &>/dev/null 2>&1; then
  branch=$(git -C "$CURRENT_DIR" symbolic-ref --short HEAD 2>/dev/null \
        || git -C "$CURRENT_DIR" rev-parse --short HEAD 2>/dev/null)
  if [ -n "$branch" ]; then
    # Truncate long branch names
    if [ ${#branch} -gt 24 ]; then
      branch="${branch:0:21}…"
    fi

    # Count staged, modified, untracked
    dirty=""
    staged=$(git -C "$CURRENT_DIR" diff --cached --numstat 2>/dev/null | wc -l | tr -d ' ')
    modified=$(git -C "$CURRENT_DIR" diff --numstat 2>/dev/null | wc -l | tr -d ' ')
    untracked=$(git -C "$CURRENT_DIR" ls-files --others --exclude-standard 2>/dev/null | wc -l | tr -d ' ')

    [ "$staged" -gt 0 ] 2>/dev/null    && dirty+=" +${staged}"
    [ "$modified" -gt 0 ] 2>/dev/null  && dirty+=" ~${modified}"
    [ "$untracked" -gt 0 ] 2>/dev/null && dirty+=" ?${untracked}"

    # Ahead / behind remote
    ab=""
    ahead_behind=$(git -C "$CURRENT_DIR" rev-list --left-right --count HEAD...@{upstream} 2>/dev/null)
    if [ -n "$ahead_behind" ]; then
      ahead=$(echo "$ahead_behind" | awk '{print $1}')
      behind=$(echo "$ahead_behind" | awk '{print $2}')
      [ "$ahead" -gt 0 ] 2>/dev/null  && ab+=" ↑${ahead}"
      [ "$behind" -gt 0 ] 2>/dev/null && ab+=" ↓${behind}"
    fi

    line1+="${SEP}${FG_BRANCH} ${branch}${RESET}"
    [ -n "$ab" ]    && line1+="${FG_BRANCH}${ab}${RESET}"
    [ -n "$dirty" ] && line1+="${FG_DIRTY}${dirty}${RESET}"
  fi
fi

# ─── 3. Model (model.display_name, fallback to model.id) ────────────────────
model_label="${MODEL_NAME:-$MODEL_ID}"
if [ -n "$model_label" ]; then
  line1+="${SEP}${FG_MODEL}✦ ${model_label}${RESET}"
fi

# ─── 4. Accumulate Session Token Usage ──────────────────────────────────────
STATE_DIR="${HOME}/.gemini/antigravity-cli/scratch"
mkdir -p "$STATE_DIR" 2>/dev/null
STATE_FILE="${STATE_DIR}/statusline_tokens_${SESSION_ID:-default}.state"

TOTAL_IN=0
TOTAL_OUT=0
LAST_IN=0
LAST_OUT=0

if [ -f "$STATE_FILE" ]; then
  read -r TOTAL_IN TOTAL_OUT LAST_IN LAST_OUT < "$STATE_FILE" 2>/dev/null || true
fi

# Ensure numeric values
TOTAL_IN=${TOTAL_IN:-0}
TOTAL_OUT=${TOTAL_OUT:-0}
LAST_IN=${LAST_IN:-0}
LAST_OUT=${LAST_OUT:-0}

# Only accumulate when usage reading changes (indicates a new step/turn)
if [ "$INPUT_TOKENS" -ne "$LAST_IN" ] || [ "$OUTPUT_TOKENS" -ne "$LAST_OUT" ]; then
  if [ "$INPUT_TOKENS" -gt 0 ] || [ "$OUTPUT_TOKENS" -gt 0 ]; then
    TOTAL_IN=$((TOTAL_IN + INPUT_TOKENS))
    TOTAL_OUT=$((TOTAL_OUT + OUTPUT_TOKENS))
  fi
  echo "$TOTAL_IN $TOTAL_OUT $INPUT_TOKENS $OUTPUT_TOKENS" > "$STATE_FILE" 2>/dev/null
fi

# ─── 5. Context window gauge (used_percentage, remaining_percentage, size) ──
if [ -n "$USED_PCT" ]; then
  pct_int=$(printf "%.0f" "$USED_PCT" 2>/dev/null || echo 0)
  pct_fmt=$(printf "%.1f" "$USED_PCT" 2>/dev/null || echo "0.0")

  # Color shifts: green (<50%) → amber (50-79%) → coral (≥80%)
  if [ "$pct_int" -ge 80 ] 2>/dev/null; then
    bar_color="$FG_CRIT"
  elif [ "$pct_int" -ge 50 ] 2>/dev/null; then
    bar_color="$FG_WARN"
  else
    bar_color="$FG_OK"
  fi

  # 15-segment progress bar with smooth block characters
  bar_width=15
  filled=$(( pct_int * bar_width / 100 ))
  [ "$filled" -gt "$bar_width" ] && filled=$bar_width
  [ "$filled" -lt 0 ] && filled=0
  empty=$(( bar_width - filled ))

  bar=""
  for ((i = 0; i < filled; i++)); do bar+="█"; done
  for ((i = 0; i < empty; i++)); do bar+="░"; done

  line1+="${SEP}${DIM}ctx${RESET} ${bar_color}${bar}${RESET} ${bar_color}${pct_fmt}%${RESET}"
fi

# ─── 6. Token breakdown (Total accumulated session input + output) ──────────
in_h=$(fmt_tokens "$TOTAL_IN")
out_h=$(fmt_tokens "$TOTAL_OUT")
line1+="${SEP}${DIM}tokens${RESET} ${FG_TOKEN}${in_h}${RESET}${DIM} in / ${RESET}${FG_TOKEN}${out_h}${RESET}${DIM} out${RESET}"

# ═══════════════════════════════════════════════════════════════════════════
# LINE 2: Secondary metadata — cache stats, session, transcript, CLI version
# ═══════════════════════════════════════════════════════════════════════════
line2_parts=()

# ─── 6. Cache token stats (cache_read & cache_creation) ─────────────────────
if [ "$CACHE_READ" -gt 0 ] 2>/dev/null || [ "$CACHE_CREATE" -gt 0 ] 2>/dev/null; then
  cache_info="${FG_CACHE}⚡ cache:"
  if [ "$CACHE_READ" -gt 0 ] 2>/dev/null; then
    cr_h=$(fmt_tokens "$CACHE_READ")
    # Calculate cache hit ratio against total input
    total_in=$(( INPUT_TOKENS + CACHE_READ + CACHE_CREATE ))
    if [ "$total_in" -gt 0 ]; then
      hit_pct=$(( CACHE_READ * 100 / total_in ))
      cache_info+=" ${cr_h} hit (${hit_pct}%)"
    else
      cache_info+=" ${cr_h} read"
    fi
  fi
  if [ "$CACHE_CREATE" -gt 0 ] 2>/dev/null; then
    cc_h=$(fmt_tokens "$CACHE_CREATE")
    cache_info+=" +${cc_h} new"
  fi
  cache_info+="${RESET}"
  line2_parts+=("$cache_info")
fi

# ─── 7. Session ID (shortened to first 8 chars) ─────────────────────────────
if [ -n "$SESSION_ID" ]; then
  short_sid="${SESSION_ID:0:8}"
  line2_parts+=("${FG_SESSION}⌗ ${short_sid}${RESET}")
fi

# ─── 8. Transcript log indicator ────────────────────────────────────────────
if [ -n "$TRANSCRIPT" ] && [ -f "$TRANSCRIPT" ]; then
  log_size=$(wc -c < "$TRANSCRIPT" 2>/dev/null | tr -d ' ')
  if [ "$log_size" -gt 0 ] 2>/dev/null; then
    log_h=$(fmt_tokens "$log_size")
    line2_parts+=("${FG_SESSION} ${log_h}B${RESET}")
  fi
fi

# ─── 9. CLI version ─────────────────────────────────────────────────────────
if [ -n "$VERSION" ]; then
  line2_parts+=("${FG_VERSION}v${VERSION}${RESET}")
fi

# ─── Assemble output ────────────────────────────────────────────────────────
printf "%b" "$line1"

if [ ${#line2_parts[@]} -gt 0 ]; then
  line2=""
  for ((i = 0; i < ${#line2_parts[@]}; i++)); do
    [ "$i" -gt 0 ] && line2+="${SEP}"
    line2+="${line2_parts[$i]}"
  done
  printf "\n%b" "$line2"
fi
