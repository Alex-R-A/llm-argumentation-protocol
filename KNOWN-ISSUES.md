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
