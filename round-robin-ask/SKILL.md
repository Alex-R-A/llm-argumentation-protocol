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
# For Sonnet, note the agentId from Task tool response

# 2. Cross-pollinate (resume sessions)
/Users/alexaustin/.claude/skills/codex-ask/codex-wrapper.sh resume $CODEX_ID "Gemini said [Y]. React?"
/Users/alexaustin/.claude/skills/gemini-ask/gemini-wrapper.sh resume $GEMINI_ID "Codex said [Z]. React?"

# 3. Devil's advocate
/Users/alexaustin/.claude/skills/codex-ask/codex-wrapper.sh resume $CODEX_ID "Attack the emerging consensus: [summary]"
```

Track IDs in a scratch file (survives context compaction):
```bash
# Write IDs to file so they persist through compaction
echo "CODEX: $CODEX_ID" >> /tmp/roundrobin-session.txt
echo "GEMINI: $GEMINI_ID" >> /tmp/roundrobin-session.txt
# Add Sonnet/Opus agent IDs as you get them from Task tool responses
```

Or keep a mental note format in your prompts that you can recover post-compaction:
```
Session IDs: CODEX=abc123, GEMINI=def456, SONNET=agent-xyz-789, OPUS=agent-uvw-012
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

**Four-model round-robin:** Codex → Gemini → Sonnet → Opus gives maximum diversity (two external models + two Claude models with different capabilities).

## Model Tendencies and Expectations

### Codex (GPT-5.2)

**Style:** Analytical, bullet-heavy, builds incrementally. Concise.

**Strengths:**
- Structural architect - proposes schemas, frameworks, concrete mechanisms ("one schema, many bindings", claim-lint gates)
- Produces implementable artifacts - specific fields, validation rules, protocol sentences
- Defends positions with mechanisms - when attacked, responds with specific safeguards
- Good at metadata design - knows what fields to track

**Tendencies to watch:**
- Over-engineers. Proposes complex solutions (retry loops with quantifiers, confidence scores, falsifiers) when simpler exists.
- Can become incoherent when challenged - may propose self-contradictory safeguards ("freeze substance; only annotate").
- Bureaucratic instinct - defaults to "add more structure" even when simpler solution exists.
- Stubborn about structural solutions - may keep defending framework approach after consensus moves away.
- May misread when processing many items quickly - verify specific concerns against source before acting on them.

**Best for:** Structural interventions, protocol design, identifying logical inconsistencies, producing concrete artifacts.

**Sample framing:** "What's the minimal structural change that would prevent X?"

**Counter-prompt when over-structuring:** "Is there a simpler way that doesn't require new schema/fields?"

---

### Gemini (gemini-3-pro-preview)

**Style:** Dramatic, vivid metaphors, longer prose with section headers. More performative/essay-like.

**Strengths:**
- Excellent failure-mode identification - "compliance drift" concern was decisive in one debate and influenced entire trajectory
- Memorable framings - "defendant controlling the indictment", "Magic Scanner paradox", "Silent Drop"
- Pragmatic implementation instinct - prefers simpler mechanisms, avoids token-burning loops
- Strong "what could go wrong" thinking - finds risks others miss
- Creates reliability tiers ("Bet Money It Works" / "Better But Fuzzy" / "Wishful Thinking") that help prioritize fixes by execution risk
- Provides closure signals - gives concrete quality ratings (e.g., "9/10") that answer "are we done iterating?"

**Tendencies to watch:**
- Holds positions too rigidly - may keep defending after others concede and problem is reframed.
- Proposals sometimes half-baked - dramatic framing can obscure lack of operational detail.
- Dismissive tone - "This is operational nonsense" can shut down rather than refine discussion.
- Can read context files proactively (may "know" answers before you ask).

**Best for:** Identifying failure modes, reframing problems, generating memorable heuristics, honest cynicism about LLM limitations.

**Sample framing:** "Give me the maximally honest assessment, even if it's nihilistic. What would you say if you weren't trying to be helpful?"

**Counter-prompt when dramatic:** "That's a vivid framing - now operationalize it. What's the concrete fix?"

---

### Sonnet (Claude Sonnet)

**Style:** Conversational, shows reasoning process, asks questions back. Most dialogue-like.

**Strengths:**
- Exceptional intellectual honesty - will do complete reversals after testing proposals against real examples
- Actually tests proposals - runs arguments against concrete cases, not just abstract reasoning
- Synthesizes multiple reviewers - identifies convergent concerns vs noise, catches when one reviewer misread, proposes minimal fix sets
- Good meta-analysis - "are we solving the right problem?" surfaces root cause questions
- Willing to concede when wrong - not defensive about prior positions

**Tendencies to watch:**
- Verbose reasoning - shows all work, sometimes too much detail
- Flip-flops - may concede prematurely then reverse; suggests rushing initial position
- Can spiral into meta-concerns - sometimes overthinks instead of converging
- Final positions can still be wrong - intellectual honesty doesn't guarantee correctness
- As same model family as you (Claude), may share more blind spots than Codex/Gemini.

**Best for:** Meta-analysis, stress-testing proposals against examples, catching when approach is solving wrong problem, honest concessions. When Sonnet does meta-analysis of prior reviewers' feedback, explicit cross-pollination (Phase 2) may be unnecessary - Sonnet synthesizes internally.

**Sample framing:** "Before you agree, give me three reasons this might be the wrong question."

**Counter-prompt when flip-flopping:** "You conceded earlier, now you're reversing. Test your NEW position against examples before committing."

---

### Opus (Claude Opus - same model as orchestrator)

**Style:** Analytical, willing to disagree, refines diagnoses rather than just validating.

**When to use:** When positions have hardened and you need a fresh reframe. Best deployed LATE in deadlocked debates, not early.

**Strengths:**
- Reframes problems - "the debate was about the wrong question" can cut through multi-way deadlocks
- Finds unifying principles - identifies the conceptual frame that makes mechanics fall into place (e.g., "genuine adversarial challenge not yet tested" made criteria intuitive; "checkability not cross-referencing" reframed a stuck debate entirely)
- Reads existing protocol/text closely - finds answers in what's already written rather than proposing new features
- Elegant minimalism - proposes using existing machinery rather than adding complexity ("or state GUESS" connecting to existing rule 6)
- Fresh context window sees where committed positions are "too neat"

**Tendencies to watch:**
- Fresh eyes advantage - didn't have to defend prior positions, so confidence may be unearned
- Limited stress-testing - if brought in late, solution wasn't challenged by earlier rounds
- Can seem dismissive - "all three positions are wrong" risks appearing arrogant
- Benefited from accumulated context - got refined problem after others did the work
- Shares identical priors with you. On clearly-right-or-wrong questions, you'll both see it and agree immediately.

**When same-model works:**
- Positions have hardened into deadlock (3-way split)
- You need someone to reframe the question itself, not just answer it
- Earlier models produced accumulated context that a fresh reader can synthesize
- Explicit "push back" instruction licenses critique

**When same-model fails:**
- Early in deliberation (no hardened positions to challenge)
- Problem is well-defined with single right answer
- You want genuinely different priors, not just fresh eyes on same priors

**Best for:** Breaking deadlocks, reframing problems, finding answers in existing text, final-arbiter role.

**Sample framing:** "Three positions emerged [X, Y, Z]. None achieved consensus. Reframe the problem - are they answering the wrong question?"

**When to deploy:** Save Opus for Phase 4 (Synthesis) or when debate stalls. Bringing Opus in early wastes the fresh-eyes advantage.

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
- Sonnet hedges via meta-analysis (questions the question rather than answering it)
- Counter-prompt for hedging: "Commit to a position. Binary choice: X or Y?"

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

**Codex → Gemini → Sonnet → (Opus)**

1. **Codex first.** Gives structural baseline - concrete, organized, something to react to. Easier to refine a framework than create one from scattered insights.

2. **Gemini second.** Reframes and challenges. Having Codex's structure gives Gemini something to push against, producing better contrasts.

3. **Sonnet third.** Best at meta-analysis ("are we solving the right problem?"). Benefits most from accumulated context. More likely to surface distinctions others missed when it has more to synthesize.

4. **Opus last (optional).** Fresh-eyes perspective on what the other three produced. Most useful when you (the orchestrator) have already formed opinions and want them challenged. Skip if the problem is well-defined or you want speed over thoroughness.

### For Devil's Advocate (Phase 3)

**Codex → Gemini → Sonnet → (Opus)**

Same order, different reasons:

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

Codex → Gemini → Sonnet → (Opus) for building up. Later models get richest context and do best meta-work. Opus is optional for consensus-building but **required for deadlock-breaking**.

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

**Codex/Gemini (via wrappers):** Sessions persist for the duration of the underlying CLI process. In practice, sessions remain valid for hours. If you get "session not found" on resume, start a new session and summarize prior context in the prompt.

**Sonnet/Opus (via Task tool):** Agent IDs persist within your Claude Code session. If Claude Code restarts or context compacts, agent IDs become stale. Start fresh and summarize.

**Surviving compaction:** Write session IDs to a file (e.g., `/tmp/roundrobin-session.txt`) as you create them. After compaction, read the file to recover IDs. Codex/Gemini sessions will still be valid; Sonnet/Opus agent IDs will be stale (start fresh for those).

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
