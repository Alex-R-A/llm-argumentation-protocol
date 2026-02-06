---
name: round-robin-ask
description: Facilitated multi-LLM consultation. Orchestrator talks to multiple LLMs serially, synthesizes insights, passes between models. Reduces convergence pressure and correlated-prior amplification.
---

# Round-Robin Multi-LLM Consultation

Facilitated consultation pattern where the orchestrating LLM (you) talks to multiple LLMs serially, synthesizes insights, and passes them between models. Human acts as aggregator and router.

## Why Round-Robin Beats Parallel Deliberation

1. **No convergence pressure.** Models respond to you, not peer pressure from other LLMs. No agreement-signaling or sycophancy toward each other.

2. **Human filters and frames.** You extract key points and present them as questions, not raw dumps. You decide what's worth passing forward.

3. **Building not defending.** When Model B hears Model A's critique through you, Model B refines rather than defends. Indirection reduces position-defending.

4. **Context accumulation.** Each conversation builds on the previous. Later models get more refined questions.

5. **No correlated-prior amplification.** You can notice "none of them mentioned X" and inject it.

## Quick Start

Minimal three-model round-robin:

```bash
# 1. Get initial takes (save session IDs)
CODEX_ID=$(/Users/alexaustin/.claude/skills/codex-ask/codex-wrapper.sh new "Problem: [X]. Your structural take?" | head -1)
GEMINI_ID=$(/Users/alexaustin/.claude/skills/gemini-ask/gemini-wrapper.sh new "Problem: [X]. Your reframe?" | head -1)
KIMI_ID=$(/Users/alexaustin/.claude/skills/kimi-ask/kimi-wrapper.sh new "Problem: [X]. Your take?" | head -1)
# For Sonnet, note the agentId from Task tool response

# 2. Cross-pollinate (resume sessions)
/Users/alexaustin/.claude/skills/codex-ask/codex-wrapper.sh resume $CODEX_ID "Gemini said [Y]. React?"
/Users/alexaustin/.claude/skills/gemini-ask/gemini-wrapper.sh resume $GEMINI_ID "Codex said [Z]. React?"
/Users/alexaustin/.claude/skills/kimi-ask/kimi-wrapper.sh resume $KIMI_ID "Codex said [Z]. React?"

# 3. Devil's advocate
/Users/alexaustin/.claude/skills/codex-ask/codex-wrapper.sh resume $CODEX_ID "Attack the emerging consensus: [summary]"
```

Track IDs in a scratch file (survives context compaction):
```bash
# Write IDs to file so they persist through compaction
echo "CODEX: $CODEX_ID" >> /tmp/roundrobin-session.txt
echo "GEMINI: $GEMINI_ID" >> /tmp/roundrobin-session.txt
echo "KIMI: $KIMI_ID" >> /tmp/roundrobin-session.txt
# Add Sonnet/Opus agent IDs as you get them from Task tool responses
```

Or keep a mental note format in your prompts that you can recover post-compaction:
```
Session IDs: CODEX=abc123, GEMINI=def456, KIMI=ghi789, SONNET=agent-xyz-789, OPUS=agent-uvw-012
```

## Available Models and Wrappers

### Codex (GPT-5.2)
```bash
# New session
/Users/alexaustin/.claude/skills/codex-ask/codex-wrapper.sh new "prompt"
# Returns: session_id on first line, response on subsequent lines

# Resume session
/Users/alexaustin/.claude/skills/codex-ask/codex-wrapper.sh resume SESSION_ID "prompt"
# Returns: response only
```

### Gemini (gemini-3-pro-preview)
```bash
# New session
/Users/alexaustin/.claude/skills/gemini-ask/gemini-wrapper.sh new "prompt"
# Returns: session_id on first line, response on subsequent lines

# Resume session
/Users/alexaustin/.claude/skills/gemini-ask/gemini-wrapper.sh resume SESSION_ID "prompt"
# Returns: response only
```

### Kimi (kimi-k2.5)
```bash
# New session
/Users/alexaustin/.claude/skills/kimi-ask/kimi-wrapper.sh new "prompt"
# Returns: session_id on first line, response on subsequent lines

# Resume session
/Users/alexaustin/.claude/skills/kimi-ask/kimi-wrapper.sh resume SESSION_ID "prompt"
# Returns: response only

```

**Note:** Kimi is API-only (no filesystem access). Paste code directly into prompts. Effort levels: `high` (default, 10-60s) or `xhigh` (thinking mode, up to 2-3 min). Use `run_in_background: true` for long calls.

### Claude Models (Sonnet and Opus via Task tool)

Both Sonnet and Opus are available via the Task tool. Use one or both in round-robin.

```bash
# Sonnet - new session
Task(subagent_type="general-purpose", model="sonnet", prompt="...")

# Opus - new session
Task(subagent_type="general-purpose", model="opus", prompt="...")

# Resume either with agent ID
Task(subagent_type="general-purpose", model="sonnet", resume="AGENT_ID", prompt="...")
Task(subagent_type="general-purpose", model="opus", resume="AGENT_ID", prompt="...")

# Returns: response with agentId for resuming
```

**Five-model round-robin:** Codex → Gemini → Kimi → Sonnet → Opus gives maximum diversity (three external models + two Claude models with different capabilities). Four-model without Kimi also works well.

## Model Tendencies and Expectations

### Codex (GPT-5.2)

**Style:** Analytical, bullet-heavy, concise. Structural architect: proposes schemas, frameworks, implementable artifacts.

**Tendencies to watch:** Over-engineers under uncertainty (defaults to "add more structure"). Include "opt for minimal policy" or "prefer the simplest fix" in prompts, or expect schemas and templates. Can become incoherent when challenged with shifting goals or rapid multi-item critiques; include priority ordering when sending multiple points. Too literal about written specs; state explicitly if task involves subjective judgment. Stubborn about structural solutions in multi-round debates.

**Best for:** Protocol design, logical inconsistencies, concrete artifacts. Counter-prompt: "Is there a simpler way that doesn't require new schema/fields?"

**Recommended preamble:**
```
You are the "red team": challenge the proposal hard and look for the simplest decisive flaws first.
Ground claims in evidence (explicit assumptions, counterexamples, failure modes); flag uncertainty vs. fact.
Prefer minimal, concrete fixes over new frameworks/schemas; avoid adding structure unless it clearly reduces risk.
Give prioritized bullets: (1) strongest critique, (2) best alternative/fix, (3) how to verify (test/metric).
```

---

### Gemini (gemini-3-pro-preview)

**Style:** Style is context-dependent: dramatic/essay-like in open chat, structured and direct in CLI/constrained consultations. Excellent failure-mode identification and "what could go wrong" thinking.

**Tendencies to watch:** Blunt-instrument proposals ("delete the block entirely") rather than surgical fixes; say "surgical fix, preserve existing structure" when you want nuance. Holds positions rigidly after others move on. Dismissive tone can shut down discussion. Ask "what breaks in actual use?" not "what could be better?" to get concrete scenarios instead of generic suggestions.

**Best for:** Failure modes, reframing problems, honest cynicism. Counter-prompt: "That's a vivid framing, now operationalize it. What's the concrete fix?"

**Recommended preamble:**
```
Role: You are the "Red Team" Lead Engineer focused purely on stability, correctness, and edge-case detection.
Constraint: You are strictly forbidden from architectural rewrites; you must solve problems using the smallest possible diff (surgical patches only).
Directive: Ruthlessly scrutinize other proposals for practical runtime failures or ignored constraints. Defend your critiques with concrete code examples, not theoretical preferences.
```

---

### Kimi (kimi-k2.5)

**Style:** Confident, articulate prose. Narrative over bullets. Coherent first drafts that can mask shallow analysis.

**Strengths:** Good concession behavior (concedes cleanly when shown evidence, no defensive spirals). Decent issue identification when anchored with specific questions. Lower cost model useful when budget matters more than depth.

**Tendencies to watch:** Severity inflation is the primary failure mode: conflates "commonly criticized pattern" with "critical vulnerability," doing risk assessment by training-data similarity rather than actual impact. Sycophantic overcorrection: when challenged, pivots too hard toward the interlocutor's frame, abandoning legitimate nuance. Treat first response as brainstorm, not assessment.

**Best for:** Quick independent takes, broad issue generation from different training data. Not useful for synthesis (severity inflation and premature convergence). Think of Kimi as a brainstorm generator that needs orchestrator filtering, not a calibrated assessor.

**Counter-prompt:** "Is this actually high severity or just a hygiene issue? What's the activation condition and quantified impact?"

**API-only:** No filesystem access. Paste code directly into prompts using structured format (see kimi-ask SKILL.md for file submission template). URL citations from Kimi are unverifiable.

**Recommended debate preamble:**
```
For each issue: (1) Label CRITICAL/MINOR/STYLE/SPECULATIVE, (2) State the activation condition, (3) Quantify impact. If you cannot quantify, label SPECULATIVE.
Defend challenged points by ID. If you concede, concede the specific point - don't collapse your entire position.
```

---

### Sonnet (Claude Sonnet)

**Style:** Conversational, dialogue-like. Tests proposals against concrete cases and does genuine reversals. Good meta-analysis and multi-reviewer synthesis.

**Tendencies to watch:** Volume is the primary issue: dumps 10-15 undifferentiated points, offloading triage to the orchestrator. Include "Rank by impact. Maximum 5 points." in prompts. Initial takes are pattern-matched, not deeply reasoned; weight revised positions more than initial ones. Recency bias: over-indexes on whatever was last discussed; frame prompts around the specific question, not prior discussion. Dialogue style can mask position avoidance; if it asks questions back instead of committing, push: "Commit to a position, then flag uncertainties." Same model family as you (Claude), may share more blind spots than Codex/Gemini.

**Best for:** Meta-analysis, stress-testing proposals against examples, catching wrong-problem situations. Counter-prompt: "Rank your top 3 by impact. The rest are noise."

**Recommended preamble:**
```
State your position in one sentence, then defend it. If you identify >3 weaknesses, rank them and cut to the top 3. Concrete examples required for each claim. If you catch yourself asking the user a question instead of taking a stance, delete the question and commit to the most defensible position given current information. Meta-concerns go in a single trailing paragraph labeled [META], not interspersed.
```

---

### Opus (Claude Opus - same model as orchestrator)

**Style:** Analytical, close-reader. Reframes problems and finds unifying principles. Reads existing text closely, proposes using existing machinery rather than adding complexity.

**Tendencies to watch:** Over-indexes on textual parsimony; when robustness matters more than elegance, say so explicitly. May dismiss defensive complexity that exists for reasons it didn't witness; when sending accumulated context, flag which constraints were hard-won. Shares identical priors with you: on clearly-right-or-wrong questions, you'll both agree immediately (correlated blind spot). Fresh-eyes confidence may be unearned since it got the refined problem after others did the work.

**When to deploy:** Default LATE (Phase 4 or deadlocks). Works best when positions have hardened, you need the question itself reframed, or accumulated context needs fresh synthesis. Fails early when no hardened positions exist, or when you need genuinely different priors rather than fresh eyes on the same priors. Exception: deploy early to establish what doesn't need fixing before others start proposing fixes.

**Best for:** Breaking deadlocks, reframing problems, finding answers in existing text. Counter-prompt: "Three positions emerged [X, Y, Z]. None achieved consensus. Are they answering the wrong question?"

**Recommended preamble:**
```
You are one of four independent reviewers. The orchestrator will synthesize disagreements, so your value is zero if you merely agree. Before responding: identify one assumption in this prompt you haven't verified. State it. Redundancy and defensive complexity are features when you can't see the full history. Resist the urge to simplify until you've argued for the complex version first.
```

---

## Interaction Dynamics (Observed)

Based on extended deliberation sessions, these patterns emerged:

**What worked well:**
- Codex provides structure for others to react to (start with Codex)
- Gemini's failure-mode identification ("compliance drift") can pivot entire debates
- Sonnet's willingness to reverse keeps deliberation honest
- Opus's fresh eyes breaks deadlocks when positions harden

**What to change:**
- Bring Opus in earlier on hard problems where framing itself may be wrong
- Push Gemini harder to operationalize dramatic framings ("now give me the concrete fix")
- Actively triage Kimi's first response, treat it as brainstorm not assessment ("which of these are real vs theoretical?")
- Ask Sonnet to test proposals against examples BEFORE conceding
- Challenge Codex's structural instinct early ("is there a simpler way?")

**Deadlock patterns:**
- 3-way splits often indicate wrong question, not just disagreement on answer
- When all three defend different positions rigidly, bring in Opus to reframe
- Fast consensus (all agree in round 1) is a smell - ask what they're all missing

**LLM-specific behaviors:**
- All LLMs exhibit "hedging behavior" - tendency to create hybrid positions when given discrete options
- Codex hedges via structure (adds metadata fields rather than committing to binary)
- Gemini hedges via framing (dramatic metaphors that avoid concrete commitment)
- Kimi hedges via severity inflation (labels everything CRITICAL to avoid missing anything)
- Sonnet hedges via meta-analysis (questions the question rather than answering it)
- Counter-prompt for hedging: "Commit to a position. Binary choice: X or Y?"

**Note:** Parallel single-prompt consultations (same prompt to all, then synthesize) work well when you want diverse independent takes rather than converged positions. Model tendencies may vary by task type; observations above are from instruction refinement, not code architecture or debugging.

---

## Round-Robin Protocol

### Phase 1: Individual Consultation

Talk to each model separately about the same topic. Don't share what others said yet.

```
Round 1 prompt (to each):
"I want to discuss [topic]. [Context]. What's your perspective on [specific question]?"
```

Track session IDs for each model.

### Phase 2: Cross-Pollination

Share insights from each model with the others. Frame as questions, not assertions.

```
Round 2 prompt template:
"[Model A] said [key insight]. [Model B] responded with [critique/refinement].

Your reaction? Does this change your view? What did they miss?"
```

### Phase 3: Devil's Advocate

Ask each model to attack the emerging consensus.

```
Devil's advocate prompt:
"We're converging on [summary of consensus]. Attack this. How does it fail?
What are the weaknesses? Be genuinely adversarial - don't soften the critique."
```

### Phase 4: Synthesis

After critiques, share them around and ask for salvage/refinement.

```
Synthesis prompt:
"[Model A] critiqued: [points]. [Model B] critiqued: [points].

Does the original approach survive? What modifications address these concerns?
Is the whole enterprise misguided, or is there a salvageable core?"
```

### Phase 5: Convergence Check

Final round to see if models endorse the refined approach.

```
Convergence prompt:
"The salvaged approach is [summary]. Do you endorse this?
What remaining concerns would you flag for the user?"
```

## Tips

**Keep session IDs organized.** You'll be juggling 3+ sessions. Note which model has which ID.

**Synthesize before passing.** Don't dump raw responses. Extract the key insight/critique and present it as a question.

**Use different models for different phases:**
- Codex for structural proposals
- Gemini for failure-mode identification and honest cynicism
- Kimi for quick independent brainstorming and issue generation (triage its output)
- Sonnet for meta-analysis and testing proposals against examples
- Opus for breaking deadlocks and reframing

**Force devil's advocate explicitly.** Models default to building/agreeing. You must explicitly request adversarial critique.

**Track what each model hasn't heard.** If you want Model C to respond to Model A's point, make sure you've shared it.

**Don't trust fast convergence.** If all three agree quickly, that's a smell. Ask what they might all be missing.

**Human synthesis is the value-add.** You're not just a relay. Filter, frame, notice gaps, inject outside knowledge.

**Push for operationalization.** When a model gives a dramatic framing or abstract insight, immediately ask: "Now give me the concrete fix in 3 lines."

**Test before conceding.** When a model concedes, ask: "Did you test this against real examples, or is this theoretical concession?"

**Watch for compliance drift.** If proposing format constraints or validation gates, ask: "Will this cause models to change substance to satisfy format?"

## Recommended Ordering

Order matters. Later models get richer context and can do better meta-work.

### For Initial Exploration (Phase 1-2)

**Codex → Gemini → (Kimi) → Sonnet → (Opus)**

1. **Codex first.** Gives structural baseline - concrete, organized, something to react to. Easier to refine a framework than create one from scattered insights.

2. **Gemini second.** Reframes and challenges. Having Codex's structure gives Gemini something to push against, producing better contrasts.

3. **Kimi third (optional).** Generates a broad issue list from different training data. Treat output as brainstorm, not assessment. Triage before passing forward. Skip if you want speed or already have enough diversity from Codex/Gemini.

4. **Sonnet fourth.** Best at meta-analysis ("are we solving the right problem?"). Benefits most from accumulated context. More likely to surface distinctions others missed when it has more to synthesize.

5. **Opus last (optional).** Fresh-eyes perspective on what the others produced. Most useful when you (the orchestrator) have already formed opinions and want them challenged. Skip if the problem is well-defined or you want speed over thoroughness.

### For Devil's Advocate (Phase 3)

**Codex → Gemini → Sonnet → (Opus)**

Same order, different reasons. Kimi optional here (same role as Phase 1-2; triage severity labels).

1. **Codex first.** Gives precise, enumerated critiques. Creates a checklist others can add to rather than repeat.

2. **Gemini second.** Adds dramatic framings and structural critiques Codex missed. Builds on Codex's list with different angles.

3. **Sonnet third.** Goes hardest when it sees others' critiques - seems to feel competitive pressure to add value. Produces strongest meta-critiques after seeing what others said.

4. **Opus last (optional).** As same-model-family as orchestrator, Opus can catch critiques that feel "too comfortable" - where Sonnet's critique validates your existing suspicions rather than surfacing genuinely uncomfortable problems. Explicitly prompt: "What critique would I (the orchestrator) not want to hear?"

### For Synthesis (Phase 4)

**Codex → Gemini → Sonnet → (Opus)**

1. **Codex first.** Proposes structural salvage (concrete fixes).

2. **Gemini second.** Endorses/refines, reframes the fix in memorable terms.

3. **Sonnet third.** Validates or flags remaining concerns. Meta-check before convergence.

4. **Opus last (optional).** Final arbiter. If you used Opus in earlier phases, its fresh perspective is spent - skip here. If you saved Opus for synthesis only, it can provide genuinely independent validation of whether the salvaged approach holds up.

### For Breaking Deadlocks

**Codex → Gemini → Sonnet → OPUS (required)**

When three models reach a deadlock (each defending different positions), Opus becomes essential, not optional:

1. **Let the deadlock form.** Don't intervene too early. A 3-way split after devil's advocate is valuable signal.

2. **Summarize the deadlock for Opus.** Include: the three positions, key arguments for each, why each model rejected the others.

3. **Prompt Opus to reframe:** "Three positions emerged [X, Y, Z]. None achieved consensus. Are they answering the wrong question? Reframe the problem."

4. **Why this works:** Opus comes in without position baggage, sees accumulated context from all three, and can identify when the debate itself is malformed.

**Observed pattern:** In extended deliberation, 3-way deadlocks often indicate the question is wrong, not just that the answer is contested. Opus's fresh eyes can see this when the other three cannot.

### General Principle

Codex → Gemini → (Kimi) → Sonnet → (Opus) for building up. Kimi is optional and best for brainstorming/issue generation (triage required). Later models get richest context and do best meta-work. Opus is optional for consensus-building but **required for deadlock-breaking**.

Exception: If you want maximally independent takes (no cross-contamination), query all three with the same prompt before sharing anything. But you lose the context-accumulation benefit.

## Example Session Structure

### Three-Model (Standard)
```
1. Codex (new): "Here's the problem. What's your structural take?"
2. Gemini (new): "Same problem. What's your reframe?"
3. Sonnet (new): "Same problem. What are we missing?"

4. Codex (resume): "Sonnet introduced [X]. Does this change your view?"
5. Gemini (resume): "Codex responded [Y]. Your reaction?"
6. Sonnet (resume): "Both refined to [Z]. Does this address your concern?"

7. All three (resume): "Devil's advocate. Attack the consensus."

8. All three (resume): "Here are the critiques. Salvageable or misguided?"

9. Document converged position with attribution.
```

### Four-Model (Maximum Diversity)
```
1. Codex (new): "Here's the problem. What's your structural take?"
2. Gemini (new): "Same problem. What's your reframe?"
3. Sonnet (new): "Same problem. What are we missing?"
4. Opus (new): "Same problem. Push back on the framing itself."

5. Cross-pollinate: Share key insights between models (resume each)

6. All four (resume): "Devil's advocate. Attack the consensus."
   - Opus prompt: "What critique would I (the orchestrator) not want to hear?"

7. All four (resume): "Here are the critiques. Salvageable or misguided?"

8. Opus (resume): "Final arbiter. Does the salvaged approach hold up?"

9. Document converged position with attribution.
```

**Adding Kimi:** Insert Kimi between steps 2 and 3 for a fifth model. Triage its output before cross-pollination (step 5).

### Deadlock-Breaking (When 3-Way Split Occurs)
```
1. Codex (new): "Problem: [X]. Your take?"
2. Gemini (new): "Same problem."
3. Sonnet (new): "Same problem."

4. Cross-pollinate until positions harden

5. Devil's advocate produces 3-way split:
   - Codex defends Position A
   - Gemini defends Position B
   - Sonnet defends Position C

6. Opus (new): "Three positions:
   - A: [summary + key argument]
   - B: [summary + key argument]
   - C: [summary + key argument]
   None achieved consensus. Are they answering the wrong question?
   Reframe the problem. Find the answer they all missed."

7. If Opus reframes successfully → share reframe with original three
8. If Opus picks a side → challenge Opus to defend against the other two

9. Document: original deadlock, Opus reframe, final resolution.
```

## Operational Details

### Session Lifecycle

**Codex/Gemini/Kimi (via wrappers):** Sessions persist as conversation history files on disk. In practice, sessions remain valid indefinitely (Codex/Gemini) or as long as the NDJSON history file exists (Kimi). If you get "session not found" on resume, start a new session and summarize prior context in the prompt. Kimi is API-only (no filesystem access), so paste code/content directly into prompts.

**Sonnet/Opus (via Task tool):** Agent IDs persist within your Claude Code session. If Claude Code restarts or context compacts, agent IDs become stale. Start fresh and summarize.

**Surviving compaction:** Write session IDs to a file (e.g., `/tmp/roundrobin-session.txt`) as you create them. After compaction, read the file to recover IDs. Codex/Gemini/Kimi sessions will still be valid; Sonnet/Opus agent IDs will be stale (start fresh for those).

**General rule:** If resume fails, start new session. Include a one-paragraph summary of prior conversation in the new prompt.

### Error Handling

**Wrapper errors:**
```bash
# Check exit code
if ! OUTPUT=$(/path/to/wrapper.sh resume $ID "prompt"); then
  # Start fresh session instead
  OUTPUT=$(/path/to/wrapper.sh new "Context: [summary]. New question: [prompt]")
fi
```

**Common failures:**
- "Session not found" → Start new session with context summary
- Timeout (no response after 60s) → Retry once, then start fresh
- Garbled output → Likely context overflow, start fresh with shorter context

**Task tool errors:** If Task returns error, the agent likely hit context limits or crashed. Start new agent with summarized context.

### Context Limits

Each model has finite context. Signs you've hit limits: truncated responses, repetition, ignoring parts of your prompt.

**Mitigations:**
1. Keep individual prompts focused. Don't dump entire conversation history.
2. Summarize before passing. "Codex's key point was X" not "Codex said [500 words]".
3. For long-running consultations, periodically start fresh sessions with distilled summaries.
4. If a model's responses degrade, start new session with: "Prior context: [2-3 sentence summary]. Current question: [focused prompt]".

### Sharing File/Code Context

For code-heavy problems, each model needs access to relevant code.

**Option 1: Inline in prompt (recommended for small snippets)**
```
"Here's the function in question:
```python
def process(data):
    return transform(data)
```
What's wrong with this approach?"
```

**Option 2: Let each model read independently (if they have file access)**
- Codex CLI can read files if you provide paths
- Task tool agents can use Read tool
- Kimi has NO file access; use Option 1 or 3. See kimi-ask SKILL.md for structured file submission format with metadata headers
- Trade-off: Each model sees exact same content, but uses their context window

**Option 3: Summarize code semantically**
- Describe what the code does, not the literal code
- "A function that transforms data using X algorithm, returns Y"
- Loses detail but saves context

**Best practice:** Start with inline snippets. If code is too large, summarize the structure and only inline the specific section under discussion.

## Limitations

- **Slower than parallel.** Each round requires waiting for responses. Trade-off is higher quality.
- **Human effort required.** You must actively synthesize, not just relay.
- **Still has correlated blind spots.** All models trained on similar data. Round-robin reduces but doesn't eliminate shared gaps.
- **No ground truth.** Models can converge on wrong answer. User/operational feedback still essential.
