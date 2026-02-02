# Known Issues

## Post-Compaction State Recovery

**Problem:** After context compaction, LLM cannot distinguish completed deliberations from interrupted ones. May re-present old results or resume wrong conversation's work.

**Root causes:**
- State files lack `status` field (no `in_progress` / `synthesized` / `presented`)
- State files lack `conversation_id` (cross-session contamination)
- Quick Mode writes no state file (can't survive compaction)
- System-reminder shows loaded skills, not completion status

**Symptoms:**
- LLM presents results user already saw
- LLM tries to resume another session's deliberation
- User has to correct: "that was already done"

**Workaround:** Always ask user before resuming/presenting from state files post-compaction.

**Fix:** See `COMPACTION-RECOVERY.md` for full proposal.

---

## Quick Mode Compaction Loss

**Problem:** Quick Mode is stateless. If compaction interrupts mid-Quick Mode, work is lost with no recovery path.

**Fix:** Quick Mode should write minimal state file: `{version, mode, status, question_excerpt, created_at}`

---

## State File Accumulation

**Problem:** Presented state files persist indefinitely. No automatic cleanup.

**Workaround:** Manual deletion when desired.

**Fix:** Auto-archive or retention policy (not yet implemented).

---

## Stale Task Notifications After Completion

**Problem:** After a background task (Codex/Gemini wrapper) completes and results are retrieved via `TaskOutput`, `<task-notification>` events continue to arrive for the same task.

**What's happening:**
- Wrapper runs with `run_in_background: true`
- LLM polls `TaskOutput` until complete, retrieves results
- Notification system runs independently, doesn't know results were already consumed
- Late notifications arrive after deliberation is done, sometimes after presenting to user

**Symptoms:**
- Random `<task-notification>` messages appear mid-conversation
- Notifications reference tasks that are already complete
- Can be confusing if they arrive after topic has moved on

**Why it happens:** The notification system and `TaskOutput` polling are decoupled. Polling retrieves results immediately when ready. Notifications are pushed asynchronously and may arrive later due to timing, queuing, or delivery delays.

**Workaround:** Silently ignore `<task-notification>` events for tasks whose results were already retrieved. Do not acknowledge to user.

**Fix:** None needed if workaround followed. This is expected async behavior, not a bug.
