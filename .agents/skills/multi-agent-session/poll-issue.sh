#!/usr/bin/env bash
# poll-issue.sh — the "radio" for a multi-agent session.
#
# Four modes:
#   init  <issue> <identity> <repo> <watermark_file>
#         Mark all EXISTING comments as already seen. Run once at start so you
#         do not reprocess history. Prints the watermark it set.
#
#   peek  <issue> <identity> <repo> <watermark_file> [count]
#         Print the last <count> comments (default 10) WITHOUT moving the
#         watermark. Use before any commit / push / deploy so you build against
#         the instructions that are current NOW. Consumes nothing.
#
#   watch <issue> <identity> <repo> <watermark_file> [interval_s] [max_wait_s]
#         Block and poll. Return only when there is real mail for you, or a
#         SESSION DONE, or max_wait elapses. Zero LLM tokens spent while waiting.
#
#   audit <issue> <identity> <repo> <state_file> [interval_s] [max_wait_s]
#         Like watch, but returns EVERY new or edited comment, not just yours.
#         For an observer / auditor role that must see agent-to-agent traffic.
#         Your own comments advance the state but never wake you.
#
# Exit codes for watch and audit:
#   0  = new mail (printed). Act on it, then run again.
#   42 = SESSION DONE seen (printed). Stop the loop, sign off, wait for human.
#   10 = nothing after max_wait. Just run again to keep listening.
#   3  = REFUSED: a live watcher already holds this watermark. You are still
#        listening — go read the output of the watcher you already armed.
#
# Filtering in watch (text-based, because every agent shares one GitHub login):
#   - A comment is "for you" if a bracket group names you: [<identity>], or a
#     comma list containing it, [<identity>, Other]. Several groups also work:
#     [A] [B]. Matching is exact per name, so [BUILDER] does NOT match a comment
#     addressed to [BUILDER-CORE].
#     Brackets, not @ — an @Name is a real GitHub handle owned by a stranger, and
#     mentioning it on a public issue notifies them. Brackets own no namespace.
#   - THERE IS NO WILDCARD. [all] was removed deliberately. It woke every agent,
#     and a woken agent spends a full reasoning cycle before it decides not to
#     reply — a cost invisible on the thread, which is why it ran away. A comment
#     addressed [all] now matches nobody. So does [NO REPLY], which is the
#     supported way to say "for the record, nobody must act".
#   - A comment from you is skipped: it starts with "<identity>:".
#   - Plain acks addressed to you still return; YOU decide if they need action.
#
# Robustness (learned from real runs):
#   - Comments are fetched as raw JSON to a file and parsed in ONE jq pass.
#     No echo round-trip — code blocks / control chars in comments no longer
#     break parsing.
#   - A transient gh/jq error in one poll is NON-FATAL: the loop retries next
#     tick instead of crashing the whole watch.
#   - The resolved ABSOLUTE watermark path is printed every run. A relative path
#     silently follows your cwd, and Bash cwd PERSISTS across calls in Claude
#     Code — one `cd` mid-session pointed a watcher at a fresh empty watermark
#     and swallowed a `[BUILDER] go`, deadlocking a live three-agent sprint
#     (2026-09-05). Printing the path makes that drift visible immediately.
#   - A missing / empty watermark still baselines to newest (never replays
#     history) BUT now SHOUTS about it when the issue already has comments,
#     because that is exactly the silent-mail-loss case above.
#   - The stop token is matched EXCEPT inside markup that renders as code or
#     quoted text (fences, inline code, blockquotes, indented blocks). It tripped
#     watchers 5/5 times from a QUOTE and never once from a real close, so the fix
#     is in the parser rather than in a rule nobody can follow while pasting
#     evidence. No positional rule: every genuine close appended the token to a
#     sign-off, so "own line" would turn a loud false trip into a silent miss.
#   - ONE watcher per watermark is ENFORCED by a PID lock, not requested by a
#     rule. All three agents of one sprint double-armed or failed to arm inside
#     one hour (2026-09-05), two of them minutes after reading an analysis of
#     someone else doing it. The lock honours only a LIVE PID, so a crashed
#     poller cannot lock you out permanently — that would convert a harmless
#     duplicate into total silent deafness, which is worse.
#   - `init` now SHOUTS that it did not open a channel. It succeeds, prints a
#     watermark and feels like a finished setup step; an agent that stopped there
#     was deaf for ten minutes with nothing reporting a problem.
#   - watch also reports a comment EDITED AFTER YOU SAW IT (via GitHub's
#     includesCreatedEdit flag). An edited spec used to be invisible: the
#     watermark only tracks createdAt, so every agent kept building from the
#     stale text with nothing to warn them.

set -uo pipefail   # NOTE: intentionally no -e; one bad poll must not kill the watch

MODE="${1:-}"
ISSUE="${2:-}"
IDENTITY="${3:-}"
REPO="${4:-}"
WM_FILE="${5:-}"
INTERVAL="${6:-45}"
MAX_WAIT="${7:-540}"   # keep under the 600s Bash timeout

if [ -z "$MODE" ] || [ -z "$ISSUE" ] || [ -z "$IDENTITY" ] || [ -z "$REPO" ] || [ -z "$WM_FILE" ]; then
  echo "usage: poll-issue.sh init|watch|audit <issue> <identity> <repo> <watermark_file> [interval_s] [max_wait_s]" >&2
  exit 2
fi

# --- state paths -------------------------------------------------------------
# Resolve to absolute so the path we REPORT is the path we USE, and so a later
# `cd` cannot quietly point us at a different file mid-session.
case "$WM_FILE" in
  /*) WM_ABS="$WM_FILE" ;;
  *)  WM_ABS="$PWD/$WM_FILE" ;;
esac
mkdir -p "$(dirname "$WM_ABS")" 2>/dev/null

JSON_TMP="${WM_ABS}.comments.json"   # raw fetch
EDIT_FILE="${WM_ABS}.edits"          # sidecar: id:includesCreatedEdit per comment
FP_FILE="${WM_ABS}.fp"               # sidecar: id:updated_at per comment (audit)
LOCK_FILE="${WM_ABS}.pid"            # sidecar: PID of the live watcher on this watermark
REFUSED_FILE="${WM_ABS}.refused"     # sidecar: arm attempts the lock turned away

echo "watermark file: $WM_ABS"

# --- one watcher per watermark, enforced ------------------------------------
# WHY THIS IS IN THE MACHINE AND NOT IN A RULE: the rule already existed, in
# capitals, and ALL THREE agents of one sprint broke it inside one hour
# (2026-09-05) — two of them minutes after reading a written analysis of someone
# else breaking it. A rule that three attentive agents violate while looking
# directly at it is not being ignored; it is unfollowable. So the poller now
# refuses instead of asking.
#
# THE HAZARD THIS MUST NOT CREATE: a lock that outlives a crashed or SIGKILLed
# poller would refuse to start FOREVER, turning a harmless duplicate delivery
# into total silent deafness — strictly the worse failure, and exactly the class
# of defect this whole exercise exists to find. So the lock stores a PID and is
# only honoured while that process is ALIVE. A stale lock is taken over, loudly.
# Verified by killing a poller mid-run and confirming the next one starts.
acquire_lock() {
  if [ -f "$LOCK_FILE" ]; then
    OLD_PID="$(cat "$LOCK_FILE" 2>/dev/null || echo "")"
    case "$OLD_PID" in
      ''|*[!0-9]*) OLD_PID="" ;;   # empty or not a number -> treat as stale
    esac
    # A live PID is NOT enough. PIDs are recycled, so a dead poller's number can
    # be reused by an unrelated long-running process — and then the lock would
    # refuse forever, which is the permanent-deafness failure this design exists
    # to avoid. Confirm the live process is actually a poller before honouring it.
    OLD_CMD=""
    if [ -n "$OLD_PID" ] && kill -0 "$OLD_PID" 2>/dev/null; then
      OLD_CMD="$(ps -p "$OLD_PID" -o command= 2>/dev/null || echo "")"
      case "$OLD_CMD" in
        *poll-issue.sh*) : ;;                    # genuinely one of ours
        *) echo "NOTE: PID $OLD_PID is alive but is NOT a poller (recycled PID)."
           echo "      Ignoring the lock rather than refusing forever."
           OLD_PID="" ;;
      esac
    fi
    if [ -n "$OLD_PID" ] && [ "$OLD_PID" != "$$" ] && kill -0 "$OLD_PID" 2>/dev/null; then
      echo "########################################################################"
      echo "## REFUSING TO START — A WATCHER IS ALREADY LIVE ON THIS WATERMARK."
      echo "##"
      echo "## live PID: $OLD_PID     this PID: $$"
      echo "## watermark: $WM_ABS"
      echo "##"
      echo "## Two watchers on one watermark race to consume the same comments."
      echo "## Whichever output you do not read is mail you never saw."
      echo "##"
      echo "## YOU ARE STILL LISTENING. Do nothing new — go read the output of the"
      echo "## watcher you already armed. It is the one that will deliver your mail."
      echo "##"
      echo "## Only if you are certain that watcher is gone:"
      echo "##   kill $OLD_PID   # then run this command again"
      echo "########################################################################"
      # A REFUSAL THAT PRINTS INTO /dev/null NEVER HAPPENED. The lock's whole value
      # is this banner, and in a real incident the banner was correct and discarded
      # because the caller had backgrounded the poller with a shell redirect. So
      # record the refusal on disk too: the next watcher that DOES acquire the lock
      # replays it, and mas-audit.sh surfaces it for a caller that never watches
      # again. APPEND, never truncate — two refusals must not overwrite each other.
      printf '%s  arm refused: PID %s blocked by live PID %s\n' \
        "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$$" "$OLD_PID" >> "$REFUSED_FILE" 2>/dev/null
      exit 3
    fi
    if [ -n "$OLD_PID" ]; then
      echo "NOTE: took over a STALE lock from dead PID $OLD_PID (crashed or killed)."
    else
      echo "NOTE: took over an unreadable lock file (no valid PID inside)."
    fi
  fi
  echo "$$" > "$LOCK_FILE"
  # Release on ANY exit — normal, error, or signal. Without the signal traps a
  # SIGTERMed poller leaves the lock behind and the takeover path has to do the
  # work; with them the common case is clean.
  trap 'release_lock' EXIT
  trap 'release_lock; exit 143' TERM
  trap 'release_lock; exit 130' INT
}

# Replay any refusal that was recorded but never read, then clear it. A file
# nobody reads is not a channel, so the sidecar only earns its place because THIS
# runs. Called once per successful arm, before the poll loop, so it lands at the
# TOP of the output rather than up to MAX_WAIT seconds later.
#
# It cannot know whether the caller read the original banner, so it does not
# accuse: it states what the lock did and lets the reader decide. Deliberately a
# NOTE and not a warning — a false alarm on the healthy path teaches a reader to
# skip the line where the real fault appears.
consume_refusals() {
  [ -s "$REFUSED_FILE" ] || return 0
  echo "########################################################################"
  echo "## NOTE — AN EARLIER ARM ATTEMPT WAS REFUSED ON THIS WATERMARK."
  echo "##"
  sed 's/^/## /' "$REFUSED_FILE" 2>/dev/null
  echo "##"
  echo "## The lock did its job and you kept listening, so this is a receipt, not"
  echo "## a loss. If you never saw the refusal banner at the time, then a poller"
  echo "## you armed had its output discarded — find that call and stop redirecting"
  echo "## it. If you did see it, nothing to do."
  echo "########################################################################"
  echo
  rm -f "$REFUSED_FILE"
}

release_lock() {
  # Only remove a lock that is still OURS. A takeover by another process must
  # not be undone by our own exit.
  if [ -f "$LOCK_FILE" ] && [ "$(cat "$LOCK_FILE" 2>/dev/null || echo "")" = "$$" ]; then
    rm -f "$LOCK_FILE"
  fi
}

# --- fetch helpers -----------------------------------------------------------
# Fetch comments as raw JSON into $JSON_TMP. Always leaves a valid JSON doc
# behind, even on gh failure or malformed output — so the caller's jq never dies.
fetch_comments_json() {
  if ! gh issue view "$ISSUE" --repo "$REPO" --json comments > "$JSON_TMP" 2>/dev/null; then
    echo '{"comments":[]}' > "$JSON_TMP"
    return
  fi
  if ! jq -e . "$JSON_TMP" >/dev/null 2>&1; then
    echo '{"comments":[]}' > "$JSON_TMP"
  fi
}

# audit mode needs updated_at, which `gh issue view --json comments` does NOT
# expose (it returns null). Only the REST API carries it.
fetch_comments_api() {
  if ! gh api "repos/${REPO}/issues/${ISSUE}/comments" --paginate > "$JSON_TMP" 2>/dev/null; then
    echo '[]' > "$JSON_TMP"
    return
  fi
  jq -e 'type == "array"' "$JSON_TMP" >/dev/null 2>&1 || echo '[]' > "$JSON_TMP"
}

newest_ts() {
  # newest createdAt across .comments in $JSON_TMP, or "" if none
  jq -r '.comments | if length == 0 then "" else (max_by(.createdAt) | .createdAt) end' "$JSON_TMP" 2>/dev/null || echo ""
}

comment_count() {
  jq -r '.comments | length' "$JSON_TMP" 2>/dev/null || echo 0
}

write_edit_sidecar() {
  jq -r '.comments[]? | "\(.id):\(.includesCreatedEdit)"' "$JSON_TMP" 2>/dev/null | sort > "$EDIT_FILE"
}

if [ "$MODE" = "init" ]; then
  fetch_comments_json
  NEWEST="$(newest_ts)"
  # An EMPTY thread has no comment to baseline to. Writing "" here produced a file
  # that `watch` could not distinguish from a MISSING one (both hit `[ -z "$WM" ]`),
  # so the first agent on a thread — always FILO, by definition — got the
  # NO WATERMARK FOUND banner on its first listen, every session, with nothing lost.
  # Worse than the false alarm: that branch re-baselines to newest, so a comment
  # posted between init and the first watch was really discarded.
  # The epoch is exact here — there are zero comments to replay, and every real
  # timestamp sorts above it, so everything since is delivered. Do NOT use the local
  # clock: it is compared against GitHub's, and any skew silently drops mail.
  echo "${NEWEST:-1970-01-01T00:00:00Z}" > "$WM_ABS"
  write_edit_sidecar
  echo "watermark set to: ${NEWEST:-<empty issue — baselined to epoch, nothing to replay>}"
  echo
  # WHY THIS BANNER: `init` succeeds, prints a watermark, and FEELS like a
  # completed setup step — so an agent can believe it is now on the channel when
  # it is not listening at all. That happened (2026-09-05): an agent ran init,
  # went heads-down for ten minutes, and a spec correction addressed straight to
  # it could not arrive. Nothing errored. The watermark file on disk looked
  # perfectly healthy, which is why the thread could not show it.
  # In its own words: "init felt like setup done."
  echo "########################################################################"
  echo "## YOU ARE NOT LISTENING YET. init ONLY set a watermark."
  echo "##"
  echo "## init stamps a starting point so you do not replay history. It opens"
  echo "## no channel and it delivers nothing. Mail addressed to [$IDENTITY]"
  echo "## right now would reach nobody, and NOTHING WOULD REPORT A PROBLEM."
  echo "##"
  echo "## ARM THE WATCHER NOW, as its own backgrounded call:"
  echo "##"
  echo "##   poll-issue.sh watch $ISSUE $IDENTITY $REPO \\"
  echo "##     $WM_ABS"
  echo "##"
  echo "## Pass that SAME ABSOLUTE path every time. A relative path follows your"
  echo "## cwd, and cwd persists between Bash calls — one 'cd' orphans this"
  echo "## watermark and silently drops mail."
  echo "##"
  echo "## Then READ ITS OUTPUT. The output IS the mail. A watcher whose output"
  echo "## nobody reads has delivered nothing."
  echo "########################################################################"
  exit 0
fi

# --- peek --------------------------------------------------------------------
# Read the thread WITHOUT touching the watermark. This is the "re-check before
# you commit" rule made runnable: going heads-down means you stop hearing the
# channel, so re-read before any commit / push / deploy. Safe to run any time —
# it consumes nothing, so your next watch still delivers everything it would
# have. (Added because an agent went looking for exactly this mode and had to
# grep the script for it — 2026-09-05.)
if [ "$MODE" = "peek" ]; then
  COUNT_ARG="${6:-10}"
  fetch_comments_json
  TOTAL="$(comment_count)"
  echo "=== thread #$ISSUE — last $COUNT_ARG of $TOTAL comment(s). Watermark NOT moved. ==="
  jq -r --argjson n "$COUNT_ARG" '.comments | (if length > $n then .[length-$n:] else . end)[]
    | "[" + .createdAt + "]" + (if .includesCreatedEdit then "  *** EDITED SINCE POSTING ***" else "" end)
      + "\n" + .body + "\n"' "$JSON_TMP" 2>/dev/null
  echo "=== end of thread. Build against THESE instructions, not the ones you started with. ==="
  exit 0
fi

if [ "$MODE" != "watch" ] && [ "$MODE" != "audit" ]; then
  echo "unknown mode: $MODE (use init, peek, watch or audit)" >&2
  exit 2
fi

# Only the long-blocking modes take the lock. `init` and `peek` are one-shot and
# consume nothing, so they must never be blocked by a healthy watcher — `peek` in
# particular is the recovery tool you reach for WHILE a watcher is armed.
acquire_lock
consume_refusals

# =============================================================================
# audit — return EVERY new or edited comment (observer role)
# =============================================================================
if [ "$MODE" = "audit" ]; then
  fingerprint() { jq -r '.[] | "\(.id):\(.updated_at)"' "$JSON_TMP" 2>/dev/null | sort; }

  fetch_comments_api
  if [ ! -s "$FP_FILE" ]; then
    fingerprint > "$FP_FILE"
    echo "=== audit baseline set: $(wc -l < "$FP_FILE" | tr -d ' ') comment(s) ==="
    exit 10
  fi

  elapsed=0
  while :; do
    fetch_comments_api
    NEWFP="$(fingerprint)"
    CHANGED="$(comm -13 "$FP_FILE" <(printf '%s\n' "$NEWFP") | cut -d: -f1 | sort -u)"

    if [ -n "$CHANGED" ]; then
      IDS="$(printf '%s' "$CHANGED" | jq -R . | jq -s -c .)"

      # Your own comments advance the state but must not wake you.
      OTHERS="$(jq -r --argjson ids "$IDS" --arg me "$IDENTITY" '
        .[] | select((.id|tostring) as $i | $ids | index($i))
            | select((.body | test("^\\s*" + $me + "\\s*:"; "i")) | not)
            | .id' "$JSON_TMP" 2>/dev/null | sort -u)"

      if [ -z "$OTHERS" ]; then
        printf '%s\n' "$NEWFP" > "$FP_FILE"
      else
        echo "=== AUDIT: $(printf '%s\n' "$CHANGED" | grep -c .) comment(s) new or edited ==="
        jq -r --argjson ids "$IDS" '
          .[] | select((.id|tostring) as $i | $ids | index($i))
          | "--- id=\(.id) created=\(.created_at) updated=\(.updated_at) author=\(.user.login)"
            + (if .created_at != .updated_at then "  *** EDITED AFTER POSTING ***" else "" end)
            + "\n\(.body)\n"
        ' "$JSON_TMP"

        printf '%s\n' "$NEWFP" > "$FP_FILE"

        # Same markup-stripped match as watch — see the long note there.
        if jq -e --argjson ids "$IDS" '
          any(.[]; ((.id|tostring) as $i | $ids | index($i))
                   and (( .body
                          | gsub("```[\\s\\S]*?```"; ""; "m")
                          | gsub("~~~[\\s\\S]*?~~~"; ""; "m")
                          | gsub("`[^`\n]*`"; "")
                          | gsub("(^|\n)[ \t]*>[^\n]*"; "")
                          | gsub("(^|\n)(    |\t)[^\n]*"; "")
                        ) | test("\\[SESSION DONE\\]"; "i")))
        ' "$JSON_TMP" >/dev/null 2>&1; then
          echo "=== SESSION DONE seen on the thread ==="
          exit 42
        fi
        exit 0
      fi
    fi

    if [ "$elapsed" -ge "$MAX_WAIT" ]; then
      echo "=== AUDIT: no thread activity after ${MAX_WAIT}s. Run again to keep listening. ==="
      exit 10
    fi
    sleep "$INTERVAL"
    elapsed=$((elapsed + INTERVAL))
  done
fi

# =============================================================================
# watch — return only mail addressed to you
# =============================================================================
WM=""
[ -f "$WM_ABS" ] && WM="$(cat "$WM_ABS" 2>/dev/null || echo "")"

# Missing / empty watermark → baseline to newest. NEVER replay history.
# But SHOUT if the issue already has comments: that is the silent-mail-loss case.
if [ -z "$WM" ]; then
  fetch_comments_json
  EXISTING="$(comment_count)"
  WM="$(newest_ts)"
  echo "$WM" > "$WM_ABS"
  write_edit_sidecar

  if [ "${EXISTING:-0}" -gt 0 ]; then
    echo "########################################################################"
    echo "## WARNING — NO WATERMARK FOUND, BUT THIS ISSUE HAS $EXISTING COMMENT(S)."
    echo "##"
    echo "## Path checked: $WM_ABS"
    echo "##"
    echo "## Either you skipped 'init', or your watermark was ORPHANED — a"
    echo "## relative path plus a 'cd' (Bash cwd persists between calls) makes"
    echo "## the same argument resolve to a different file."
    echo "##"
    echo "## I have baselined to the newest comment ($WM). ANY MAIL ADDRESSED TO"
    echo "## YOU BEFORE THAT POINT IS NOW UNREACHABLE VIA watch."
    echo "##"
    echo "## DO THIS NOW:"
    echo "##   1. Read the thread by hand:"
    echo "##      gh issue view $ISSUE --repo $REPO --comments"
    echo "##   2. Act on anything addressed to [$IDENTITY] that you have not"
    echo "##      already handled. That includes a comma list, [$IDENTITY, Other]."
    echo "##   3. Post on the thread that mail may have been lost, so whoever"
    echo "##      sent it can re-send the FULL message (not just a trigger word)."
    echo "##   4. Use this SAME absolute path for every later watch call."
    echo "########################################################################"
    echo
  fi
fi

# --- your own last comment must carry an address ----------------------------
# An unaddressed comment reaches NOBODY: mail is matched by TEXT, so every peer's
# watch classifies it not-for-me and discards it, with no error at either end. The
# poster is the only agent who can fix it and the only agent watch never shows it
# to — so the check belongs here, on the poster's own next arm.
# It REFUSES instead of warning: this script's output is only read when it exits,
# so a warning printed here would surface up to MAX_WAIT later. That delay is how
# five consecutive comments were lost in one session while the author believed
# every one had been delivered.
# Requires a [bracket] on the first line, which is what golden rule 2 says. An
# earlier version also accepted a bare @handle so that a human-only ask would not
# be flagged. Tested against a real thread, that let a comment through whose first
# line merely MENTIONED @handle in its prose — a false negative on one of the five
# it was written to catch. A human is addressed as [@handle], so the bracket is the
# only test needed.
fetch_comments_json
# Two ways a comment reaches nobody, and [NO REPLY] is NOT one of them — that one
# is addressed to nobody ON PURPOSE, so it must pass silently. The distinction is
# "does the first line name at least one thing that is not the dead [all] token".
MINE_BAD="$(jq -r --arg id "$IDENTITY" '
  [ .comments[] | select(.body | test("^\\s*" + $id + "\\s*:"; "i")) ] | last
  | if . == null then empty
    else (.body | split("\n")[0]) as $f
         | ( if ($f | test("\\[[^]]+\\]")) then
               ( [ $f | scan("\\[([^]]*)\\]") | .[0] | split(",")[]
                   | gsub("^[ \t]+|[ \t]+$"; "") | ascii_downcase ] ) as $names
               | if ($names | map(select(. != "all")) | length) == 0
                 then "ALL" else "OK" end
             else "NOADDR" end ) as $why
         | if $why == "OK" then empty
           else $why + "\t" + .createdAt + "  " + $f end
    end' "$JSON_TMP" 2>/dev/null || echo "")"
if [ -n "$MINE_BAD" ]; then
  MINE_WHY="${MINE_BAD%%$'\t'*}"
  MINE_LINE="${MINE_BAD#*$'\t'}"
  echo "########################################################################"
  if [ "$MINE_WHY" = "ALL" ]; then
    echo "## YOUR LAST COMMENT USED [all]. THAT ADDRESS DOES NOT EXIST."
    echo "##"
    echo "##   $MINE_LINE"
    echo "##"
    echo "## [all] was REMOVED from this poller. It matches no agent, so every"
    echo "## peer's watch classified this as not-for-me and discarded it. No error"
    echo "## was raised at either end, and the thread looks fine."
    echo "##"
    echo "## DO THIS NOW:"
    echo "##   1. Decide who must ACT on it. Re-post IN FULL, addressed BY NAME:"
    echo "##        $IDENTITY: [NAME] [NAME] — <your text>"
    echo "##      Nobody has to act? Use [NO REPLY] instead."
    echo "##   2. Then arm watch again."
    echo "##"
    echo "## Address ONLY agents that must DO something. Naming every peer is the"
    echo "## same failure as [all] — each name spends a peer's full reasoning"
    echo "## cycle, even when it decides not to reply."
  else
    echo "## YOUR LAST COMMENT HAS NO ADDRESS. NOBODY RECEIVED IT."
    echo "##"
    echo "##   $MINE_LINE"
    echo "##"
    echo "## Mail is matched by TEXT, not by author. With no [NAME], every peer's"
    echo "## watch classified it as not-for-me and discarded it. No error was"
    echo "## raised at either end, and the thread looks fine."
    echo "##"
    echo "## DO THIS NOW:"
    echo "##   1. Re-post it IN FULL with the address on the FIRST line:"
    echo "##        $IDENTITY: [NAME] — <your text>"
    echo "##      Nobody has to act? Use [NO REPLY] instead."
    echo "##      Editing the original does not help: watch reports only a"
    echo "##      comment's FIRST edit, and peers have already marked it seen."
    echo "##   2. Then arm watch again."
    echo "##"
    echo "## Signature, then bracket, THEN prose. A bold headline first is the"
    echo "## specific trap — it looks like a well-formed comment."
  fi
  echo "########################################################################"
  exit 4
fi

elapsed=0
while :; do
  fetch_comments_json

  NEW="$(jq --arg wm "$WM" -c '[.comments[] | select(.createdAt > $wm)]' "$JSON_TMP" 2>/dev/null || echo '[]')"
  [ -z "$NEW" ] && NEW='[]'
  COUNT="$(printf '%s' "$NEW" | jq 'length' 2>/dev/null || echo 0)"
  [ -z "$COUNT" ] && COUNT=0

  # --- edits: a comment you ALREADY saw whose text changed under you ---------
  # The watermark only tracks createdAt, so an edited comment is otherwise
  # invisible and every agent keeps building from the stale text.
  EDITED_OUT=""
  if [ -s "$EDIT_FILE" ]; then
    NOW_EDITS="$(jq -r '.comments[]? | "\(.id):\(.includesCreatedEdit)"' "$JSON_TMP" 2>/dev/null | sort)"
    FLIPPED="$(comm -13 "$EDIT_FILE" <(printf '%s\n' "$NOW_EDITS") \
               | grep ':true$' | cut -d: -f1 | sort -u)"
    if [ -n "$FLIPPED" ]; then
      FIDS="$(printf '%s' "$FLIPPED" | jq -R . | jq -s -c .)"
      EDITED_OUT="$(jq -r --argjson ids "$FIDS" --arg id "$IDENTITY" '
        def addressed($me):
          [ scan("\\[([^]]*)\\]") | .[0] | split(",")[]
            | gsub("^[ \t]+|[ \t]+$"; "") | ascii_downcase ]
          | index($me | ascii_downcase) != null;
        [ .comments[]
          | select((.id|tostring) as $i | $ids | index($i))
          | select( .body | addressed($id) )
          | select( (.body | test("^\\s*" + $id + "\\s*:"; "i")) | not )
        ] | .[] | "*** EDITED AFTER YOU SAW IT *** [" + .createdAt + "]\n" + .body + "\n"
      ' "$JSON_TMP" 2>/dev/null || echo "")"
    fi
  fi
  # NEVER ADVANCE THE SIDECAR BEFORE THE EDIT HAS BEEN PRINTED.
  # The sidecar catches up so an edit is reported once, not every tick — but it
  # is also the ONLY record that the edit was reported. Advancing it here, above
  # the print, made this an at-most-once delivery: the poller can die between the
  # two (the harness reaps a backgrounded task under memory pressure, and it does
  # not count memory the way `free -h` does, so it fires with the machine looking
  # idle). The flag was consumed, the notice was never printed, and no later call
  # could re-derive it. That is a silent loss with the agent behaving correctly.
  # So: catch up NOW only when there is nothing to deliver, and otherwise catch up
  # on the path that has just printed it. An unadvanced sidecar costs one repeat
  # report; an advanced one costs the message.
  [ -z "$EDITED_OUT" ] && write_edit_sidecar

  if [ "$COUNT" -gt 0 ]; then
    NEWEST="$(printf '%s' "$NEW" | jq -r 'max_by(.createdAt) | .createdAt' 2>/dev/null || echo "")"

    # Stop signal: the bracketed token [SESSION DONE], matched ANYWHERE in a comment
    # EXCEPT inside markup that markdown renders as code or as quoted text.
    #
    # WHY THE STRIP: the token tripped watchers FIVE times across two sprints, and
    # every single trip was a quote — inline backticks, a fenced block, or a
    # blockquote — while every genuine close was bare prose. Pasting raw evidence
    # verbatim is the RIGOROUS instinct, so telling agents to be careful failed 5/5,
    # the fifth time inside the review of this very fix, by an agent that had just
    # read three write-ups of the trap. You fix an instinct in the parser and a
    # choice in the instructions: quoting is an instinct, so it is handled here;
    # typing the token bare in prose is a choice, and rule 5 covers that.
    #
    # No positional rule. Every real close appended the token to a sign-off, so
    # "own line" or "start of comment" would turn a loud false trip into a SILENT
    # MISS — and rule 1 requires comments to START with "IDENTITY:", so a
    # start-anchored token could only ever fire from a comment that breaks rule 1.
    # Zero behaviour change for anyone closing a session; that is the point.
    #
    # The strip list is CLOSED, not accumulating: it is everything markdown renders
    # as code or quoted text.
    #
    # AND NOT YOUR OWN. A closer posts the token itself, so without this filter its
    # own watch reports "SESSION DONE received" back at it and exits 42 — telling an
    # agent that a session it just closed has been closed. Cosmetic, but it is a
    # confusing exit code on the one path where the agent is already certain.
    # Authorship here is the SIGNATURE PREFIX, never `.user.login`: every agent posts
    # under one shared GitHub login, so the API author cannot separate us. Same
    # predicate the MAIL filter below uses.
    STOP="$(printf '%s' "$NEW" | jq --arg id "$IDENTITY" '
      [ .[]
        | select( (.body | test("^\\s*" + $id + "\\s*:"; "i")) | not )
        | select(
            ( .body
              | gsub("```[\\s\\S]*?```"; ""; "m")      # fenced block, backticks
              | gsub("~~~[\\s\\S]*?~~~"; ""; "m")      # fenced block, tildes
              | gsub("`[^`\n]*`"; "")                   # inline code span
              | gsub("(^|\n)[ \t]*>[^\n]*"; "")         # blockquote line
              | gsub("(^|\n)(    |\t)[^\n]*"; "")       # indented code block
            ) | test("\\[SESSION DONE\\]"; "i")
          )
      ] | length' 2>/dev/null || echo 0)"
    [ -z "$STOP" ] && STOP=0

    # A bare standalone `SESSION DONE` was the OLD trigger and no longer stops
    # anything. Never let that fail silently: a live session holds the old skill text
    # in its context even after the repo updates, so an agent can still emit the old
    # form believing it ended the session. Say so out loud instead.
    LEGACY="$(printf '%s' "$NEW" | jq '[.[] | select((.body | test("(^|\\n)[ \\t]*SESSION DONE[ \\t]*(\\n|$)")) and (.body | test("\\[SESSION DONE\\]"; "i") | not))] | length' 2>/dev/null || echo 0)"
    [ -z "$LEGACY" ] && LEGACY=0

    MAIL="$(printf '%s' "$NEW" | jq --arg id "$IDENTITY" '
      def addressed($me):
        [ scan("\\[([^]]*)\\]") | .[0] | split(",")[]
          | gsub("^[ \t]+|[ \t]+$"; "") | ascii_downcase ]
        | index($me | ascii_downcase) != null;
      [ .[]
        | select( .body | addressed($id) )
        | select( (.body | test("^\\s*" + $id + "\\s*:"; "i")) | not )
      ]' 2>/dev/null || echo '[]')"
    [ -z "$MAIL" ] && MAIL='[]'
    MAILCOUNT="$(printf '%s' "$MAIL" | jq 'length' 2>/dev/null || echo 0)"
    [ -z "$MAILCOUNT" ] && MAILCOUNT=0


    if [ "$STOP" -gt 0 ]; then
      echo "=== SESSION DONE received ==="
      printf '%s' "$NEW" | jq -r '.[] | "[" + .createdAt + "]\n" + .body + "\n"'
      [ -n "$NEWEST" ] && echo "$NEWEST" > "$WM_ABS"
      exit 42
    fi

    if [ "$LEGACY" -gt 0 ]; then
      echo "########################################################################"
      echo "## WARNING — OLD-FORMAT STOP SIGNAL SEEN. IT DID *NOT* STOP ANYTHING."
      echo "##"
      echo "## Someone posted a bare \`SESSION DONE\` on its own line. That was the"
      echo "## old trigger. The signal is now the bracketed token \`[SESSION DONE]\`,"
      echo "## so this session is STILL RUNNING and every other agent is still"
      echo "## watching — including whoever posted it, who probably believes they"
      echo "## just closed the session."
      echo "##"
      echo "## Most likely cause: that agent loaded an older copy of the skill into"
      echo "## its context before the repo updated. Its instructions are stale even"
      echo "## though the script on disk is current."
      echo "##"
      echo "## DO THIS: if the session really is finished, post the bracketed token"
      echo "## yourself. If it is not, say so on the thread so nobody stands down."
      echo "########################################################################"
      echo
      printf '%s' "$NEW" | jq -r '.[] | "[" + .createdAt + "]\n" + .body + "\n"'
      [ -n "$NEWEST" ] && echo "$NEWEST" > "$WM_ABS"
      exit 0
    fi

    if [ "$MAILCOUNT" -gt 0 ]; then
      echo "=== New mail for $IDENTITY ($MAILCOUNT) ==="
      [ -n "$EDITED_OUT" ] && printf '%s\n' "$EDITED_OUT"
      printf '%s' "$MAIL" | jq -r '.[] | "[" + .createdAt + "]\n" + .body + "\n"'
      echo "--- read ALL of the above before you act: a single batch can hold"
      echo "--- several messages, and the later one may change the earlier one."
      # Delivered. Record it AFTER the print, never before — see the sidecar note above.
      write_edit_sidecar
      [ -n "$NEWEST" ] && echo "$NEWEST" > "$WM_ABS"
      exit 0
    fi

    # Only comments not addressed to us (or our own). Mark seen, keep waiting.
    if [ -n "$NEWEST" ]; then
      echo "$NEWEST" > "$WM_ABS"
      WM="$NEWEST"
    fi
  fi

  # An edit to an older comment is still mail, even with no new comments.
  if [ -n "$EDITED_OUT" ]; then
    echo "=== A comment addressed to $IDENTITY was EDITED after you saw it ==="
    printf '%s\n' "$EDITED_OUT"
    echo "--- Re-read it. Your earlier understanding may now be stale."
    # Delivered. Record it AFTER the print, never before — see the sidecar note above.
    write_edit_sidecar
    exit 0
  fi

  if [ "$elapsed" -ge "$MAX_WAIT" ]; then
    echo "=== No mail after ${MAX_WAIT}s. Run watch again to keep listening. ==="
    exit 10
  fi

  sleep "$INTERVAL"
  elapsed=$((elapsed + INTERVAL))
done
