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

**Fix:** See `COMPACTION-RECOVERY.md` for full proposal. Fix is being worked on.

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

## Kimi Has No Filesystem Access

**Problem:** Unlike Codex and Gemini, which run as local CLIs with filesystem access, Kimi is accessed via HTTP API (`curl` to Moonshot's endpoint). It cannot read files from your machine. The orchestrator must include all relevant code and context inline in each prompt.

**Implications:** Deliberations involving large files or many files may hit the model's context window limit. kimi-ask works best when the code under review is small and focused, ideally a single file or a few short excerpts, rather than broad codebase-level analysis.

**Why it's different:** Codex CLI and Gemini CLI run locally and can scan your project directory. Kimi has no CLI; the wrapper script sends prompts and receives responses over HTTP, so anything Kimi needs to see must be pasted into the request payload.

**Workaround:** Scope kimi-ask questions narrowly. Extract the specific functions, classes, or config sections relevant to the question rather than passing entire files.

---

## Stale Task Notifications After Completion

**Problem:** After a background task (Codex/Gemini wrapper) completes and results are retrieved via `TaskOutput`, `<task-notification>` events continue to arrive for the same task.

**What's happening:**
- Wrapper runs with `run_in_background: true`
- LLM polls `TaskOutput` until complete, retrieves results
- Notification system runs independently, doesn't know results were already consumed
- Late notifications arrive after deliberation is done, sometimes after presenting to user

**Why `run_in_background: true`:**
Codex/Gemini response times are unpredictable: 1 second for simple questions, up to 20 minutes for complex code analysis requiring extensive scanning and reasoning. Standard bash timeout cannot accommodate this range. If timeout triggers mid-thinking, the LLM session is discarded and output is lost. Background execution with polling avoids this: the task runs without timeout pressure, and we poll until complete regardless of duration.

**Symptoms:**
- Random `<task-notification>` messages appear mid-conversation
- Notifications reference tasks that are already complete
- Can be confusing if they arrive after topic has moved on

**Why it happens:** The notification system and `TaskOutput` polling are decoupled. Polling retrieves results immediately when ready. Notifications are pushed asynchronously and may arrive later due to timing, queuing, or delivery delays.

**Workaround:** Silently ignore `<task-notification>` events for tasks whose results were already retrieved. Do not acknowledge to user.

**Fix:** None needed if workaround followed. This is expected async behavior, not a bug.
