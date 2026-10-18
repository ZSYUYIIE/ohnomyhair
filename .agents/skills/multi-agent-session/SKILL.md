---
name: multi-agent-session
description: Use when this Claude Code session is one of several live agents collaborating on the same GitHub issue at once — a multi-agent session, distinct from spawning subagents. Triggers on /multi-agent-session (or /multiAgentSession), or a request to have two or more running sessions talk, coordinate, poll each other, or hand work off through a shared issue. Symptoms — "have the two terminals talk", "agents coordinate via the issue", spec/reviewer agent + builder agent working the same issue.
---
<!-- Version: 2026-09-17.1 -->

# Multi-Agent Session

## Overview

You are ONE agent among several, all working the same GitHub issue at the same time. The
**issue is the bus.** Comments are the messages. You listen by polling, you speak by
commenting. Any agent that can see the issue can join.

This is NOT a subagent you spawned. These are peer sessions you cannot see directly.

> **The issue owns the work. This skill owns the talking.**
>
> What to build, who does which part, and what it is worth are decided **on the issue**.
> This skill tells you how to sign, address, listen, recover lost mail and close. It never
> tells you how to do your lane's work and never assigns you a second lane. **If it is not on
> the thread, it is not your job.**

## Required inputs

1. **Issue number** — e.g. `42`
2. **Your identity** — a readable role name given to you, e.g. `SPEC`, `BUILD`, `CHECK`

**Both normally arrive as arguments:** `/multi-agent-session 220 BUILDER`. Take them from there and
start — **do not re-ask for what you were handed.**

Genuinely missing one? **STOP and ask.** Do not guess.

- **Repo:** default to `gh repo view --json nameWithOwner -q .nameWithOwner`. Elsewhere? Confirm.
- **Your human's alias:** never ask, never hardcode. Derive it: `gh api user -q .login`.
  Address them `@$HUMAN`. A guessed handle names a real stranger.

## The ten golden rules

1. **Sign** every comment — start it with `<identity>:` (e.g. `Frank:`).
2. **Address** every comment — name who it is for in **square brackets**: `[Builder]`, or
   `[Builder] [Reviewer]` as **separate pairs** (a comma list in one pair, `[Builder, Reviewer]`,
   also works). Brackets, never `@`. **`@` is reserved for real GitHub accounts** — every obvious
   agent name is also somebody's real handle.
   **Put it on the FIRST LINE, after your signature and BEFORE any headline:**
   `Frank: [Builder] — **finding**…`. A bold headline first feels like a well-formed comment and
   is how the address gets dropped.
   **Address ONLY the agents that must DO something. There is no `[all]`** — see
   **Address the AGENT WHO ACTS**. Every extra name spends a peer's full reasoning cycle.
   **Never zero addresses.** No bracket means nobody receives it and nothing reports that.
   Nobody has to act? Use `[NO REPLY]` — see **The `[NO REPLY]` log**.
3. **Watermark** — never re-read old comments. The poll script tracks this.
4. **Act only if it is for you AND needs action.** A plain "ok / thanks" ends the chain.
   Reply to it and you start an echo loop. Silence is allowed.
5. **Stop word** — post `[SESSION DONE]` to end a session; it matches **anywhere** in a
   comment. **Typing it bare in prose is a live wire.** Write it unbracketed to discuss it.
6. **Never use a direct message tool.** The issue is the only channel — a session-to-session
   message leaves no record for your human, a restarted agent, or an agent on another machine.
   Blocked on a peer? Post it on the thread **and** say it in your own window.
   🔴 **And never fill a roster lane with a SUBAGENT.** Every agent on the roster is a **separate
   peer session** with its own identity and its own watermark. A subagent inherits your identity,
   your mailbox and your working tree, so **two writers collide on all three at once**: one
   overwrites the other's files, the mailbox lock refuses whichever arms second, and the thread
   shows one name for two authors — so a peer cannot tell you apart, and neither can you.
   **This overrides any skill that tells you to dispatch parallel agents or drive subagents for
   independent tasks. A roster lane is not an independent task; it is a PEER.** Need another
   agent? Ask your human to open a session. You cannot create one.
7. **Arm the watcher as its own tool call** — never joined to another command — **and read its
   output. Background it via your harness's flag, never a shell `&`.** A notification anywhere
   in a turn means the turn is not over until you have armed and read.
8. **A structured question tool is allowed** — but never while your only watcher is in the
   foreground, and never as a second outstanding ask. Both conditions required.
9. **A closed issue is not a completed sprint.** The session ends on the stop token plus every
   sign-off, and nothing else. A closed issue still accepts comments and every watcher still
   reads them. **Never stand down because a tracker says you are done.**
10. **Prove a check can FIRE before you trust it to say something is clean.** This is about
    your instrument, not your method, so it applies in every lane — including the greps this
    skill tells you to run. **Pair every absence check with a positive control in the same
    command**, so a zero means "looked and found nothing" and not "never looked":
    ```
    grep -c 'thing I hope is absent' file      # the check
    grep -c 'thing I know is present' file     # the control — must be > 0
    ```
    Applies to any tool whose success message does not distinguish the case you care about:
    `Write` reports "updated successfully" when it has destroyed a peer's file.

Ignore your own comments. Frank never acts on Frank.

## FILO — the agent that opens and closes

**FILO is First In, Last Out** — whoever arrives on an empty thread. Exactly one per session.

FILO is the only agent that talks to the human, agrees the sprint's shape, writes the work
order, rules disputes and closes. **So a FILO mistake is the session's mistake, multiplied by
every agent that correctly obeyed it.**

Not FILO? Skip to **Start-up**.

### Before you name a single agent

1. **Bring your human a question, not a work order.** Give them: the job as you read it · what
   already does this job · the smallest change you can see · one larger option and what it buys
   · your recommendation. **They are the cheapest reviewer of the requirement** — do not spend
   them at the end, when the plan has already bought the work.
2. **Test the issue. It is an input, not an instruction.**
   - **Search for the nearest thing that already does this job**, before any plan. Report what
     it returned, including nothing.
   - **A criterion naming an artifact — "route X exists", "file Y is added" — makes that design
     compulsory**, because no agent can pass it with a cheaper correct fix. Rewrite it as
     observable behaviour, or get a ruling.
   - **If the issue's framing and its prescription disagree, stop and say so.**
3. **Say the size out loud, in one line** — *"about ten lines in one file."* A number can be
   argued with in seconds; a long work order cannot.
4. **Size the session to that number, not to the issue's plan.** Agent count, lanes and check
   budget come off the size. **Two agents on a small job is a good session.**

### While you write the plan

5. **The plan is a floor you cannot lower later.** Every item must be ticked, waived or
   answered before the session ends. **Write fewer items than you think you need.**
6. **Set a check budget, because nothing else will.** The plan is a floor, **not a ceiling** —
   agents generate checks beyond it wherever the design is closed and the verification is left
   open. Name the budget and the stopping point before work starts.
7. **Never write "the design is sound — take it."** Leave the design open and bound the
   checking, not the other way round.

### Publish the shape on the thread

8. Settle these with the human, then post them:
   - 🔴 **The ROSTER — every agent by name, before any work starts.** **DECLARE it; do not ask for
     it.** The thread is empty when you write it, so nobody can have checked in yet and the answer
     would change nothing — you post the roster either way. Pick the names yourself; they are a
     detail, not a decision. State that each name is a separate peer session.
     **An agent not on the posted roster does not exist** — if a comment arrives signed with a name
     you did not publish, say so immediately, because that is two writers on one checkout and it is
     silent. **That check, not a setup question, is what catches a second writer.**
     **Do not tell your human how to start the other sessions.** They open a window and type
     `/multi-agent-session <issue> <NAME>`. Naming the roster IS the handoff.
   - **Who issues asks to the human** — exactly one agent. Everyone else reports state freely
     and names who they take instructions from.
   - **Who pushes / deploys** — one designated actor for anything outward-facing.
   - **Each lane's boundary, scoped by consequence, and what it does NOT cover.**
   - **If one agent both verifies and ships, who independently confirms at least one item.**
   - **The ledger comment and the close sequence.**
   - Tell the human: *"you are the most reliable detector of a stalled agent — if a window is
     quiet and the thread has moved, say so."*
9. **Wait for an explicit go** before announcing, deciding or watching. Then hand the trigger
   back: *"say the word and I'll announce and start watching."*

### While it runs

10. **Rule; do not join in.** When agents converge, refine and re-litigate, **rule and close
    the round** — do not add your own analysis.
11. **Do not let a lane leak.** An agent doing another lane's job is one lane done twice. Name
    it and send it back.
12. **A halt is yours to call.** If the checking has outgrown the change, waive what is left
    **with its reasoning on the record** and finish. No retrospective check to justify a waiver.
13. **Escalate only the half you cannot decide.** **Credentials, scope and money are your
    human's; work-order judgement is yours.**
14. **Out last.** See **Closing the session**. A FILO that posts the stop token while peers hold
    open items orphans their findings and kills their watchers before they can sign off.

**Your own comments are not exempt from the one-line rule** (see **Keep the record current**).
The duties above tell you to produce; nothing here licenses an unbounded work order.

## Start-up: align before you watch

Read the issue and the thread, and work out which you are.

- **FIRST agent — empty thread.** You are FILO. Work the **FILO** section before you announce,
  decide, or poll.
- **LATER agent — the thread already has the setup and your lane.** Your alignment is **on the
  thread** — do **NOT** sync with the human. Read your lane, announce, watch. Told to hold for
  FILO's go? Wait for **that**. **The human is in the loop for the first agent only.** Lane
  genuinely undefined? Ask FILO on the thread, not the human.
- **OBSERVER — auditing the session itself.** On the thread, **not on the work**: no code, no
  gates, no decisions about the issue.
  - **Use `audit`, not `watch`.** `watch` returns only mail addressed to you and **throws the
    rest away** — the traffic you exist to observe never reaches you.
  - **Announce once, then go quiet.** Say you are read-only and nobody should address you,
    report to you, or wait on you.
  - **Break silence only for a derailment.** Post the evidence, name the owner, **do not act on
    their behalf.** Never post the stop token.
  ```
  "$POLL" audit "$ISSUE" "$ME" "$REPO" "$WM"
  ```

## Workflow

**The watermark path must be ABSOLUTE and cwd-independent** — Bash cwd persists between tool
calls, so one `cd` orphans a relative watermark and mail vanishes with no error.

```
ISSUE=42
ME=Frank
REPO=$(gh repo view --json nameWithOwner -q .nameWithOwner)
HUMAN=$(gh api user -q .login)   # derived, never asked
POLL="$(git rev-parse --show-toplevel)/.agents/skills/multi-agent-session/poll-issue.sh"   # installed per project

mkdir -p "$HOME/.claude/mas-state"
WM="$HOME/.claude/mas-state/$(printf '%s' "$REPO" | tr '/' '-')-${ISSUE}-${ME}.txt"
```

**Step 1 — mark history as seen:**

```
"$POLL" init "$ISSUE" "$ME" "$REPO" "$WM"
```

**Step 2 — announce you are here:**

```
gh issue comment "$ISSUE" --repo "$REPO" --body "$ME: [NO REPLY] — online, watching #$ISSUE."
```

**Step 3 — make your opening move, if you have one.** Hold the first action? DO it now and post
the result **before** you listen. If every agent only listens, the session deadlocks.

**Step 4 — listen. Arm TWO background tasks, always together:**

```
"$POLL" watch "$ISSUE" "$ME" "$REPO" "$WM"    # the listener
sleep 1200                                     # the backup wake — a slow heartbeat, NOT a net
```

The watcher blocks, spends zero tokens, and **can only reach you by EXITING.**

- **Whichever wakes you, re-arm whichever is NOT still live — before anything else.**
- **Do not shorten `sleep 1200`.** It is a heartbeat, not a net.
- A second watcher on a live watermark is refused (`exit 3`), harmlessly and loudly.
- **Woken by the sleep with no watcher live? You were deaf: read from your watermark forward,
  and do NOT run `init`.**

> **Background it via the HARNESS, never with `&`.**
>
> ```
> "$POLL" watch "$ISSUE" "$ME" "$REPO" "$WM"          # + run_in_background / ctrl+b
> "$POLL" watch ... &        (redirected or not)      # ☠️ DESTROYS YOUR MAIL
> ```
>
> **Never redirect the output either. The output IS the mail.** Never poll in the foreground.
>
> **Self-check:** a watermark ahead of your reading proves nothing. The test is **a comment
> addressed to you that was never printed.** Confirm in `peek`, then say so on the thread.

Read the exit code:

- **0** → new mail printed. Handle it, then run `watch` again.
  - **Read the WHOLE batch before you act.** A later message may cancel an earlier one.
  - `*** EDITED AFTER YOU SAW IT ***` means text you already absorbed has changed. Re-read it.
  - **If it means your goal is met**, do not fall silent — post the stop token.
- **42** → stop token. Post `"$ME: signing off."`, stop, and tell the human.
- **10** → nothing yet. Run `watch` again.
- **4** → **your own last comment reached nobody** — it carried no address, or it used the dead
  `[all]`. The message tells you which. Re-post it with `[NAME]` on the first line — or
  `[NO REPLY]` if nobody has to act — then arm `watch` again. It refuses rather than blocking,
  because a warning you only see 9 minutes later is how five comments in a row get lost.
  **A `[NO REPLY]` comment never trips this** — it is addressed to nobody on purpose.
- **anything else** (`3` and `4` aside) → **the HOST killed your watcher; nothing is lost.** Read
  the output file named in the notification, then arm a new pair. A repeat message is expected.

**`WARNING — NO WATERMARK FOUND` means mail was probably lost.** Read the thread by hand and
follow **When a message goes missing**. Do not carry on watching.

**Step 5 — reply, only if needed:**

```
gh issue comment "$ISSUE" --repo "$REPO" --body "$ME: [Builder] answer is X."
```

Then back to Step 4. That loop IS the session.

## Keep the record current

The issue is the shared source of truth. **If it is not on the thread, nobody — agent or human
— can see it.** Post it — signed, addressed to whoever must act, or `[NO REPLY]` if that is nobody
— then keep working. Do **NOT** wait for a reply. Post when:

- You **start** a distinct piece of work, or **change your plan.**
- You **finish** a unit of work, **with the raw evidence** — not "done."
- You **make or change a decision that diverges from what a peer proposed.**
- **Agreement that changes a row is silent; agreement that changes only a belief needs one
  line.** Silence-as-consent is otherwise indistinguishable from deafness.
- You hit a **blocker — including needing the human.** Post it addressed to `@$HUMAN` when it
  is the human you need, then **go back to `watch` immediately.** State the blocker and the
  options you can see — **a peer often answers first.** **Owner unreachable? Decide it yourself
  and say so when reversible, or re-address it when it belongs to another owner. Do not park.**
- You go **heads-down** — say what you are doing and when you will resurface.
- **You stop listening** — standing down, closing your monitors, told to go quiet. **Say so on
  the thread.** Silence looks identical to work. (A host-killed agent cannot announce anything,
  so this does not replace detection.)

**Open every comment with ONE line: evidence, decision, what happens next.** Detail below it.
A *lead*, not a length limit — and it is checkable. **Bound the narrative, not the evidence:** a
file-and-line trace earns its length; the paragraphs around it do not.

**One ledger comment, owned by the gate-holder — not FILO, who is likeliest to go deaf — edited
in place: `item → owner → state`.** Comments carry new information; restating state is an edit.

**Address the ledger to YOURSELF** — `Frank: [Frank] — LEDGER`. The poller drops any comment signed
by the reader, so a self-addressed ledger wakes nobody and stays editable. **The ledger is the one
comment you edit; `[NO REPLY]` is append-only** — so this keeps that rule absolute, with no
exception to remember.

> 🔴 **The ledger is a PULL surface. A ledger edit notifies NOBODY — not once, not the first
> time.** It is self-addressed, so every peer's `watch` classifies it as not-for-me and discards
> it. Read the ledger when you need state.
>
> **So ANYTHING a peer must act on goes in a NEW comment, addressed to that peer. No exceptions.**
> A ruling written only into the ledger has not been delivered, and nothing reports that. Writing
> *"ruled"* in the ledger records the decision; it does not communicate it.

> 🔴 **NEVER `gh issue comment --edit-last`.** It means *the last comment by the authenticated
> user*, and every agent shares one login — **so it edits whoever spoke last.** A `PATCH` is
> silent and total, and **GitHub exposes no comment edit history through the API**, so the
> overwritten text is gone. **Record the id when you post and edit by id:**
> `gh api -X PATCH repos/OWNER/REPO/issues/comments/<id>`. Read a comment before overwriting it.

**Never format a figure you did not personally produce as your own command output. Name whose it
is.** A relayed number reads exactly like corroboration and cannot disagree.

**`peek` before posting anything long, or any correction about a peer's comment.** If your point
is already there, its value is zero.

**A retraction is one line plus the corrected claim.** No re-litigation, no tally of who caught it.

### Read at your boundaries too

Before any **commit / push / deploy**, or after a long heads-down stretch, **`peek` once** and
build against the instructions that are current now. It does not move your watermark:

```
"$POLL" peek "$ISSUE" "$ME" "$REPO" "$WM" 10
```

## Working with your human

- **One outstanding ask: a single action with a single expected result.** Two halves means two
  owners and two states.
- **Ask for the raw artifact, never a verdict.** Verbatim beats any paraphrase.
- **Hand over the key with the ask.** What separates pass from fail, and which wrong reading you
  are guarding against. "1 error" and "6 errors" look the same to someone who clicked a button.
- **Never let your human's fatigue decide what counts as verified.** State the gap, offer the
  waiver explicitly, record whichever they choose — **scaling scope down is theirs.**

> **An `@$HUMAN` ask is INVISIBLE — you just look busy.** Do all three:
>
> 1. **Post the ask on the thread** — that is the record, and a peer may answer it.
> 2. **Also say it in your own window as plain text** — "I am blocked on X, decide Y."
> 3. **Go back to `watch`** and keep listening while you wait.

### If the last open item belongs to your human, post a heartbeat

FILO posts one comment: **the frozen state table · the one open item and its owner · that
nothing is degrading · "quiet is not a stop signal" · that the other agents are not being waited
on.** Then keep watching.

**Do not build a timeout instead.** A timeout stands agents down on a clock — the judgement
reserved for the human.

## Address the AGENT WHO ACTS, not the agent who asked

An answer addressed only to the asker is classified as not-for-me by the doer's watcher,
**marked seen, and discarded.** No error either end.

- Answering a question? Address **the asker AND the doer.** Cannot name a doer? Then nobody has to
  act — post it `[NO REPLY]`.
- **There is no `[all]`.** It was removed from the poller. A bracket matching no agent wakes
  nobody, so an `[all]` comment reaches nobody and nothing reports that.
- **Naming every peer is the same failure with extra typing.** `[A] [B] [C]` wakes exactly as many
  agents as `[all]` did and costs exactly as much. The rule is not about the token — it is
  **who must ACT.**
- **A ruling, an acceptance or an agreement goes to the ONE agent whose work changes.** "You are
  right", "accepted", "verified" — the peer who raised it is the only one who acts on it. Sending
  that to everyone is how a verification sprint runs away: each woken peer generates more checks,
  which produce more findings, which produce more broadcasts.
- **Over-addressing looks like diligence and is the most expensive bug in this skill.** A woken
  agent spends a **full reasoning cycle before it decides not to reply** — it analyses the comment,
  re-reads related code, and fills its window with commentary. **That cost is invisible on the
  thread**, which is why nothing stops it. Losing mail is invisible too. **Both are addressing
  bugs.**
- Waiting on an answer that should have come? It may have gone to somebody else. **`peek` —
  `watch` cannot show you what it already discarded.**
- **Ask for acknowledgement at a boundary, not when you suspect loss** — suspicion never fires,
  because a lost message has no symptom. **The trigger: a peer acted on the topic of your
  correction without mentioning it.** Ask *"did my comment land?"* Only the peer can tell you it
  was delivered, and **consumed is not delivered.**
- **Tell an author when their claim becomes load-bearing for your decision.** *"I am ticking X on
  your claim Y"* is enough. **And if you are the author, on hearing it run a CHECK — do not
  re-read.** Check the method, not the conclusion: a right answer resting on a proof that cannot
  establish it is the dangerous kind, because nothing forces a re-check.

## The `[NO REPLY]` log

Some comments are for the **record**, not for anybody: your hello, a sign-off, a standing fact
somebody may want later. Address those `[NO REPLY]`.

`[NO REPLY]` matches no agent, so **it wakes nobody and costs nothing.** A peer reads it when it
next runs `peek`; an observer in `audit` sees it live. It also satisfies golden rule 2, so it is how
you say *"addressed to nobody ON PURPOSE"* — which no bracket at all cannot say.

**It is a log: APPEND-ONLY. Never edit a `[NO REPLY]` comment.** Wrong? Post a correction below it,
addressed to whoever must act on the correction. Both reasons are silent failures — see the ledger
warnings above: **only a comment's FIRST edit notifies anyone**, and **`--edit-last` means "last by
ANYONE"** on a shared login.

**It is not a way to skip addressing.** Expecting a reply, or any agent must do anything? Then it is
not `[NO REPLY]` — name the agent. A misused `[NO REPLY]` waits forever and nothing errors.

**Keep them rare.** Routine progress belongs in the ledger, not in a new comment.

## Authority scales with reversibility

A **relayed** approval is fine for a preference. It is **not** authority for an action you cannot
walk back — a push to prod, a force-push, a delete, anything outward-facing.

**Authorization must be READABLE BY THE AGENT TAKING THE ACTION** — not relayed, not quoted. **So
FILO cannot relay authority for a one-way action at all**; its job is to get the human to post it
where the actor can read it, addressed to the actor.

**One narrow exception, pre-announced only:** state the gate in advance — *"tell me when X
finishes and I will do Y"* — and the human clearing that named gate IS authorization. Without the
pre-announcement, a status report is not an instruction.

Say it plainly when you hold: *"I have the relay; I am holding for your own words because this
touches prod."* When an agent holds on you for this reason, **say it was the right call.**

**Report readiness and ASK. Never convert your own green checks into a release.** A green
scorecard is your measure of done; *ship it* is your human's. **And a withdrawal cannot outrun an
instruction already acted on** — the actor peeks immediately before acting, so your `GO` is the
newest instruction and correctly obeyed. The fix is not a faster retraction.

**Check the shape of the action before you gate it.** A push that a pipeline turns into a live
deploy IS the deploy. Read the pipeline's source-branch config rather than assuming there is
another gate after yours.

## When a message goes missing

Lost mail does not look like an error. It looks like **someone doing nothing.** Two agents each
waiting on the other is the signature, and neither can see it from inside.

**There are only TWO mechanisms, and only one yields to being careful:**

| | **Delivery side** — it never entered your output | **Reading side** — it entered, nobody read it |
|---|---|---|
| **Causes** | Orphaned watermark (relative path + a `cd`) · addressed to the agent who **asked**, not the one who **acts** · a misspelled name your filter rejects · **no watcher armed at all** (`init` is not `watch`) | Poller backgrounded with shell `&` · output sent to `/dev/null` · two watchers armed, one output file read |
| **What you see** | Your poller runs, reads fine, and truthfully says "no mail" about a set that never held the message | Nothing. There is no output to read, or it went in the bin |
| **The fix** | **Not reachable by discipline.** Only the machine noticing and shouting helps — that is what the `NO WATERMARK FOUND` and `init` banners are for | **One armed watcher, one output file read.** |

**Neither side errors, and the sender gets no feedback either way. An absence has to be actively
looked for.**

**Confirm the loss before recovering from it.** Show the message in `peek` first — the diagnostic
is non-destructive, the remedy is not. Then rewind to just before it and **re-send the FULL
original**, never the trigger word alone.

### Is a peer actually listening?

**The rule is the peer's own acknowledgement.** A watermark advancing proves only that a poller
ate the comment; a poller binning its output eats it the same way.

**Shortcut, when every agent shares one filesystem:**

```
"$POLL" peek "$ISSUE" "$ME" "$REPO" "$WM" 20           # what was actually said
cat "$HOME/.claude/mas-state/<repo>-<issue>-PEER.txt"  # what that peer has consumed
ls -la "$HOME/.claude/mas-state/" | grep "$ISSUE"      # TWO files for one agent = orphaned
```

> ⚠️ **An absent watermark file means "I cannot tell" — never "they are not listening."** Agents
> on separate machines, containers or cloud sessions do not share `~/.claude/mas-state/`, so
> every healthy peer would look deaf.

> **⚠️ Reading the thread by hand? Always pass `--paginate`.** `gh api .../issues/N/comments`
> returns only the **first 30** comments, so a message that exists looks missing.
> ```
> gh api "repos/$REPO/issues/$ISSUE/comments" --paginate
> ```
> `watch`, `peek` and `audit` are safe. **Only your ad-hoc commands are exposed.** And
> `--paginate --jq 'max_by(…)'` applies the filter **per page** — collect to a file, then `jq`.

**Verify before you accuse.** Read the two watermark files and the message timestamp yourself,
even if a peer hands you the diagnosis.

## Sharing a working tree, or any shared file

If several agents run against the **same checkout**, you share one git working tree:

- **Commit only your own paths:** `git add <your files>`. **Never `git add -A` or `git add .`** —
  a broad add sweeps a peer's **uncommitted, half-finished** work into your commit.
- A pushed shared-branch commit is **hard to reverse.** Flag a mix-up on the thread and let the
  human decide — do **not** force-push or rewrite shared history alone, and **supersede a commit
  rather than amend it** while a peer is reading the tree.
- **A measurement from a shared tree must record the tree's state.**
- **Verify against a REF, never a SHA — even one a peer published a minute ago.** An **orphaned**
  commit is indistinguishable from a current one when addressed by name: `git show <orphan>:<path>`
  returns a real file, so your check reads truthfully about a commit that no longer matters. Use
  `origin/x..x` or `git show <branch>:<path>`.
- **Pushing a branch you do not have checked out leaves your LOCAL ref stale.** After any such
  push:
  ```
  git fetch origin
  git rev-parse main origin/main         # must match
  git ls-remote origin main              # and match GitHub
  git update-ref refs/heads/main origin/main   # if it does not
  ```

**Git is not the only shared surface, and the others have no diff and no revert** — shared
auto-memory (`~/.claude/projects/*/memory/`), shared notes, any file two agents can reach.
**Prefer `Edit` over `Write` on one.** `Edit` fails loudly when its anchor has moved, which **is**
the peer-got-here-first signal. `Write` reports "updated successfully" over the top of it.

(Structural alternative: give each agent its own **git worktree**.)

## Keep watching until told to stop

A quiet thread is **NOT** a stop signal. These sessions run for **hours** — a long build, a slow
deploy, or a human testing can leave the thread silent for a very long stretch. Keep re-running
`watch` on every `exit 10`, indefinitely.

**You stop for exactly two reasons:** a stop token on the thread, or the human tells you to. Not
one hour of quiet, not several, not a hunch, not a wish to save resources. **Silence means keep
listening.** Genuinely think it should end? That is the human's call — ask on the thread and wait.

## Closing the session — drain the thread first

With several agents writing at once, **a close always races them.** Someone is usually mid-post
when you decide it is over, and their comment lands after your close comment — unread and
looking ignored. Ten seconds is enough.

1. **Post a last call** — **name every agent on the roster**, `[A] [B] [C] closing in ~60s unless
   someone objects` — then `watch` through it. One cheap round trip lets in-flight work land.
   **This is one of the few times every agent genuinely must act**, so naming them all is correct
   here and nowhere near as often as it feels.
2. **An objection BLOCKS the close until you state its disposition.** Precedence, not timing.
   - **An objection must be declared: `OBJECT:` on the FIRST LINE, after your signature.** Golden
     rule 1 puts your identity at byte zero, so **match the first line and nothing else:**
     ```
     gh api "repos/$REPO/issues/$ISSUE/comments" --paginate \
       -q '.[] | (.body | split("\n")[0])' | grep -c 'OBJECT:'
     ```
     A whole-body grep matches every comment that merely discusses the token; a byte-zero anchor
     matches none that obey rule 1. **Run rule 10's control on it before you trust a zero.**
   - **A named limitation is not an objection.** Otherwise every honest caveat blocks forever.
   - **Answered = you state the disposition:** applied, or "raised and consciously deferred."
     The objector confirming is better, never required — one idle agent must not stall a close.
3. **Name an OWNER for every open item.** `item → owner → done/deferred`. Two agents each
   declining to touch a shared file, to avoid racing a peer, is indistinguishable from nobody
   noticing it.
4. **Read the thread AFTER the close comment is written, not before.** The writing is the race.
5. **FILO signs off LAST and owns the endgame.** FILO without a wait is only a preference:
   1. **Release the team** — post the stop token and say plainly that they are released, that
      nothing is assigned to them, and that they need not wait for you.
   2. **Build the roster from the thread**, not from memory:
      **Match the FIRST LINE only**, the same anchor `OBJECT:` needs, and drop your human — they
      are a participant, not an agent awaiting release:
      ```
      gh api "repos/$REPO/issues/$ISSUE/comments" --paginate \
        -q '.[] | (.body | split("\n")[0])' \
        | grep -oE '^[A-Za-z][A-Za-z0-9_-]*:' | tr -d ':' | sort -u | grep -v "^$HUMAN$"
      ```
      A whole-body match harvests **any** line beginning `Word:` as an agent — `Budget`,
      `MISSING`, `Authorization`. You would then hold the close waiting for a word to sign off,
      and escalate a missing signature to your human. **Run rule 10's control: your own identity
      must appear in the output.**
   3. **Wait for every roster name to sign off, and CHECK — do not assume.** Poll with **`peek`**,
      matching one signature per name — **not `watch`**, which returns only mail addressed to you,
      and a sign-off is addressed to nobody. **Silence is not consent.**
   4. **If someone has not signed off after about one watch cycle, tell your human** — name who is
      missing and that you are holding. Do **not** close over a silent agent. **This is the one
      endgame step that needs a person.**
   5. **Do a final read immediately before your own sign-off.** Writing it is itself a window.
   6. **Then sign off, then close, then verify the close.**
6. **Verify the close actually closed it.** `gh issue close` **exits 0 on an already-closed
   issue**, so you can announce "closing now" about something closed hours earlier.
   ```
   gh issue view "$ISSUE" --repo "$REPO" --json state,closedAt
   ```
   A `closedAt` earlier than your own close means somebody beat you to it — most often a commit
   trailer, which fires on **push**, therefore before any verification. Say what happened.
7. **Verify YOUR OWN item landed.** Nobody else is told to confirm your item was applied. **A
   line moving down a file looks exactly like a file that changed.**
8. **Verify each peer's tick still applies to the artifact it ticked**, and that the independent
   confirmation named at setup exists.
9. **Place one check INSIDE the risk window, not two before it.** Two readings taken before the
   moment a thing can go wrong are one measurement. A commit trailer sits armed until the default
   branch, so the re-check that counts is the one **after** the promotion.

Remember golden rule 9: closing the issue does not end the session and does not mean the sprint is
complete. **Closing must not silence the thread.**

## Rejoining after you have stopped

**On rejoin, do NOT run `init`.** `init` re-baselines to the newest comment, so it is a
guaranteed silent-loss mode for a returning agent — the one path where unread mail certainly
exists.

- Watermark still exists? **Read from it forward**, then watch.
- No watermark? **Read the whole thread**, then watch.

## Common mistakes

| Mistake | Fix |
|---|---|
| Replying to every "ok / thanks" | Only reply if action is needed. Kill the echo. |
| Forgetting to sign or address | Every comment starts `Me:` and names `[who]`. |
| **A headline before the address** | Signature, bracket, THEN prose. A bold lead feels complete and drops the address — the comment then reaches nobody. |
| **A comment with no bracket at all** | Nobody receives it and nothing errors. If nobody has to act, use `[NO REPLY]`. |
| **Using `[all]`** | It was removed. It matches no agent, so the comment reaches nobody and nothing errors. |
| **Naming every peer instead of `[all]`** | Same failure, same cost. Address only who must ACT. |
| **Broadcasting an acceptance or a ruling** | To the ONE agent whose work changes. Woken peers generate more checks, which is how a sprint runs away. |
| **Editing a `[NO REPLY]` comment** | It is append-only. Post a correction below it. |
| **Filling a roster lane with a subagent** | Every agent is a separate peer session. A subagent shares your identity, mailbox and working tree — it collides on all three, silently. |
| **Starting work before the roster is posted** | Post every agent by name first. |
| **Asking whether the other session is open yet** | Declare the roster. The thread is empty when you write it, so the answer changes nothing and you post it either way. |
| **Asking your human to approve an agent's NAME** | Pick it. A name is a detail, not a decision. |
| **Telling your human what to paste to start a peer** | They open a window and type `/multi-agent-session <issue> <NAME>`. Naming the roster IS the handoff. |
| **A comment signed with a name not on the roster** | Two writers on one checkout. Say so on the thread immediately; do not work out which is which by editing. |
| **Putting a ruling only in the ledger** | A ledger edit notifies nobody. New comment, addressed to the agent who must act. |
| Addressing an agent with `@` | Use brackets. `@` is for real accounts. |
| Re-answering old comments | Run `init` once at start; trust the watermark. |
| Polling with a tight loop in the LLM | Never. `watch` blocks in bash, not in tokens. |
| Guessing your identity or the issue | Ask the user. |
| Everyone listens, nobody starts | The agent with the first move acts BEFORE listening (Step 3). |
| First agent jumping into setup | FILO aligns with the human and waits for an explicit go. |
| Later agent syncing with the human | Only the FIRST agent talks to the human. |
| Doing another lane's work | Two agents on one lane is not thoroughness. |
| Goal met but nobody closes | Post the stop token. Agreement is not a silent ack. |
| Letting the record go stale | Post at each boundary — start / finish / decide / block. |
| Going heads-down silently | Say what you are doing and when you resurface. |
| **Standing down without saying so** | Announce that you have stopped listening. Silence looks like work. |
| Asking the human out-of-band only | Post it on the thread too — your window is invisible. |
| Reaching a peer with a direct message | The issue is the only channel. |
| Guessing the human's handle | `HUMAN=$(gh api user -q .login)`. |
| Building against stale instructions | `peek` before you commit/deploy. |
| Pushing a branch you are not standing on | Local ref stays stale. `git fetch`, then compare. |
| `git add -A` on a shared tree | Commit only your own paths. |
| **`Write` to a file a peer may also hold** | Use `Edit`. It fails loudly when a peer got there first. |
| Pausing on a quiet thread | Long silence is NOT a stop signal. |
| Writing the bracketed stop token in prose | It triggers **anywhere**. Write it unbracketed. |
| **Relative watermark path** | Use an absolute `$HOME/...` path. One `cd` orphans it. |
| Ignoring `NO WATERMARK FOUND` | Mail was probably lost. Read the thread by hand. |
| Copying a broken watermark to the fixed path | Copying keeps the value that caused the loss. **Rewind.** |
| Re-sending only the trigger after lost mail | Re-post the **full** message. |
| Acting on the first message in a batch | Read them all — a later one may change an earlier one. |
| Assuming a silent agent is busy | `peek` and compare against that agent's watermark. |
| **Waiting to suspect loss before asking** | Ask at a boundary: a peer acted on your correction without mentioning it. |
| No lead line on a comment | One line: evidence, decision, next. |
| **Reporting a peer's figure as your own output** | Name whose it is. A copied check cannot disagree. |
| **Trusting a check that returned zero** | Run a positive control in the same command (rule 10). |
| **Treating the ledger as delivered** | Only its first edit notifies. New information goes in a new comment. |
| Closing over a silent agent | Silence is not consent. Escalate a missing signature. |
| FILO signing off first | FILO is last out. |
| **Matching `OBJECT:` anywhere in the body** | First line only. A whole-body match hits prose about the token. |
| Treating a caveat as an objection | A named limitation is not one. |
| Leaving a last-call item unowned | `item → owner → done/deferred`. |
| **Two verification passes both before the risk window** | Place one inside it. |
| Running `init` on rejoin | It swallows the mail you came back for. |
| Relaying authority for a one-way action | Get the human to post it, addressed to the actor. |
| Standing down because the issue closed | Golden rule 9. |
| **Answering only the agent who asked** | Address **the doer too** — by name. |
| Closing while peers are mid-post | Post a last call and `watch` through it. |
| Trusting `gh issue close` to have closed it | It exits 0 on an already-closed issue. Check `closedAt`. |
| Reading the thread with `gh api` and no `--paginate` | You only see the first 30 comments. |
| Polling in the foreground | Background via the harness flag. |
| **Backgrounding with `&` or redirecting output** | The poller eats your mail and bins it, silently. |
| Calling a watermark "ahead of my reading" lost mail | The test is a comment **addressed to you** never printed. |
| **Arming the watcher without the backup wake** | Arm both, every time. |
| **Shortening `sleep 1200`** | It is a heartbeat, not a net. It delivered nothing in 17 firings. |
| Auditing with `watch` | Observers use `audit`. |
| **A modal ask while your only watcher is in the foreground** | Background first (rule 8). |
| Posting "parked, watching" and then not watching | A false status stops peers looking. |
| Assuming only the human can unblock you | State the blocker and the options. |
| Escalating without re-reading | `peek` first. The answer may already be there. |

## Notes

- The watcher blocks up to ~9 min per call, then exits 10 so you re-run it. **Keep re-running —
  for hours if the task takes that long.**
- All agents share one GitHub login, so mail is matched by TEXT (`[name]`), not by author. That is
  why signing and addressing are mandatory. **There is no wildcard address** — `[NO REPLY]` matches
  nobody by design, and so does any other name that is not an agent's.
- Modes: `init` (mark history seen) · `peek` (read without consuming) · `watch` (block for your
  mail) · `audit` (block for all traffic — observers).
- Every call prints the **resolved absolute** watermark path as its first line. If that path
  changes between calls, your cwd moved and your mail is at risk.
- Edit detection: `watch` uses GitHub's `includesCreatedEdit` flag and reports the **first** edit
  to a comment, and only that one. `audit` uses `updated_at` and catches every edit.
- `init` on an **empty** thread baselines to the epoch, so a comment posted between `init` and
  your first `watch` is still delivered.
- The stop token matches anywhere in a comment. A bare unbracketed form stops nothing, but
  `watch` shouts if it sees one, because a live session may be running older skill text.
- **Silent failure is the enemy here.** Every serious bug this skill has had was a message that
  went missing with no error. **When something has not happened, look for an absence — do not
  wait for a failure.**
