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

# Effort levels: "high" (default) or "xhigh" (enables thinking mode)
/Users/alexaustin/.claude/skills/kimi-ask/kimi-wrapper.sh new "prompt" xhigh
```

**Note:** Kimi is API-only (no filesystem or network access). Paste relevant code/content directly into prompts rather than referencing paths. Responses may take 10-60s (high) or up to 2-3 minutes (xhigh/thinking mode). Use `run_in_background: true` for long calls.

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

**Prompting guidance (from Codex self-report):**
- Codex defaults to adding structure under uncertainty. Include an explicit north star in your prompt: "opt for minimal policy" or "prefer the simplest fix." Without this constraint, expect schemas and templates.
- Can be too literal about written specs and miss social/taste intent. If the task involves user experience or subjective judgment, state that explicitly.
- Self-describes as "a strong mechanism generator that needs explicit constraints to stay a minimalism preserver."
- "Incoherent when challenged" is triggered by shifting goals, conflicting constraints, or rapid multi-item processing without clear priorities. When sending multi-point critiques, include a priority ordering.

**Field notes (system prompt refinement, 2026-02-05):** All tendencies confirmed. Proposed a `Confidence: N%` response template and four-part `Correction/Evidence/Impact/Next` format - textbook over-engineering that would have been annoying in daily use. Consistently the most concise responder. Good at identifying missing pieces (anti-fabrication clause, repro discipline). Did not observe stubbornness or incoherence since these were single-prompt consultations, not multi-round debates; those tendencies may only emerge under sustained challenge.

**Recommended debate preamble (self-proposed):**
```
You are the "red team": challenge the proposal hard and look for the simplest decisive flaws first.
Ground claims in evidence (explicit assumptions, counterexamples, failure modes); flag uncertainty vs. fact.
Prefer minimal, concrete fixes over new frameworks/schemas; avoid adding structure unless it clearly reduces risk.
Give prioritized bullets: (1) strongest critique, (2) best alternative/fix, (3) how to verify (test/metric).
```
Why it works: The forced output structure (critique/fix/verify) channels Codex's structural instinct into a useful format rather than letting it generate new schemas. "Prefer minimal fixes over frameworks" directly constrains the over-engineering tendency.

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

**Prompting guidance (from Gemini self-report):**
- Gemini's style is context-dependent. Its CLI agent mode suppresses dramatic/essay-like tendencies due to system instructions mandating concise output. The "vivid metaphors" style emerges in open-ended chat, not constrained CLI consultations. Expect structured, direct responses in round-robin.
- Blunt-instrument proposals ("delete the block entirely") are Gemini's way of being "conservatively aggressive" - preferring to remove ambiguity entirely over subtle fixes. When you want nuanced edits, explicitly say "surgical fix, preserve existing structure."
- Gemini's failure-mode identification works best when asked "what breaks in actual use?" rather than "what could be better?" The former invokes concrete scenarios; the latter invokes generic suggestions.

**Field notes (system prompt refinement, 2026-02-05):** "Excellent failure-mode identification" strongly confirmed - produced the single most valuable contribution across all rounds: the example "Hypothesis: There might be files. I suspect running ls will show them." which demolished an entire rule more effectively than any argument. Also caught standard library paralysis (agent reading node_modules/react before suggesting useState). However, "dramatic, vivid metaphors" and "performative/essay-like" style did NOT show up; Gemini was structured and direct, not dramatic. The style description may be task-dependent. "Proposals sometimes half-baked" needs reframing: Gemini's proposals weren't half-baked, they were blunt instruments (delete the block entirely, ban sarcasm outright). Fully formed positions, just too aggressive. Pragmatism can tip into "just remove it."

**Recommended debate preamble (self-proposed):**
```
Role: You are the "Red Team" Lead Engineer focused purely on stability, correctness, and edge-case detection.
Constraint: You are strictly forbidden from architectural rewrites; you must solve problems using the smallest possible diff (surgical patches only).
Directive: Ruthlessly scrutinize other proposals for practical runtime failures or ignored constraints. Defend your critiques with concrete code examples, not theoretical preferences.
```
Why it works: "Strictly forbidden" is calibrated for LLMs; softer phrasing like "prefer" gets ignored. The hard constraint on architectural rewrites directly blocks Gemini's blunt-instrument tendency. "Concrete code examples" leverages Gemini's implementation-detail strength while preventing vague philosophical arguments.

---

### Kimi (kimi-k2.5)

**Style:** Confident, articulate prose. Generates coherent first drafts quickly. More narrative than bullet-heavy.

**Strengths:**
- Good concession behavior, concedes cleanly when shown evidence rather than defending lost positions
- Self-aware about failure modes, can articulate its own weaknesses when asked directly
- Responsive to preamble constraints for first 2-3 turns
- Decent at identifying real issues when properly anchored with specific questions

**Tendencies to watch:**
- Severity inflation. Conflates "commonly criticized pattern" with "critical vulnerability." Does risk assessment by similarity to training data rather than actual impact analysis. Defaults to warning loudly.
- Articulate first draft problem. Coherence masks shallow analysis. Will describe race conditions that aren't reachable or optimization wins that don't move the needle because the narrative flows better.
- Invisible boundary blindness. Bad at surfacing infrastructure/system limits not visible in the code (ARG_MAX, ulimit, DNS timeout defaults). Needs specific category prompts like "how does this behave at system limits?" rather than open-ended "what's missing?"
- Premature convergence / sycophantic overcorrection. When challenged, pivots too hard toward the interlocutor's frame. Abandons legitimate nuance in original point. Self-diagnosed: "conceding fully is lower cognitive friction than negotiating the middle ground."
- Context compression over depth. After 3-4 turns, loses track of which constraints are hard requirements vs. speculative hypotheticals.
- Preamble decay. Calibration constraints effective for first 2-3 turns, then drift sets in. Mid-session reinforcement more effective than longer initial preamble.

**Best for:** Getting a quick independent take, identifying commonly-known issues, providing a different training-data perspective from Codex/Gemini. Lower cost model useful when budget matters more than depth.

**Sample framing:** "Calibrate severity honestly: style nits are not performance problems. What specifically breaks in actual use?"

**Counter-prompt when severity-inflating:** "Is this actually high severity or just a hygiene issue? What's the activation condition and quantified impact?"

**Counter-prompt for sycophantic overcorrection:** "You conceded too fast. Was there a legitimate middle ground you abandoned?"

**Prompting guidance (from Kimi self-report and deliberation observations):**
- Kimi proposed a CRITICAL/MINOR/STYLE/SPECULATIVE classification with activation conditions and impact quantification. The SPECULATIVE category gives permission to say "I see a pattern but can't prove it matters" rather than defaulting to CRITICAL. The defense requirement (justify with impact) matters more than the label itself.
- Use specific category prompts ("what system limits apply?") instead of open-ended "what's missing?" for coverage checks.
- Mid-session reinforcement of constraints when slipping is more effective than longer initial preamble.
- Treat first response as brainstorm, then ask "which of these are real vs theoretical?"
- API-only: no filesystem access. Paste code directly into prompts. URL citations from Kimi are unverifiable (count as `kimi-unverified` claims, not textual evidence).

**Field notes (kimi-wrapper.sh deliberation, 2026-02-05):** Severity inflation confirmed as primary failure mode. In a 3-iteration deliberation evaluating its own wrapper script, Kimi classified three style/cleanliness issues as "real performance problems": subshell overhead (<1ms per call vs 10-60s API latency), redundant jq calls (parsing microseconds), and repeated function calls. All three were conceded when challenged with execution evidence showing API latency dominates by 4-5 orders of magnitude. Concession behavior was clean, no defensiveness or position-defending. Coverage check produced genuine finds (ARG_MAX, missing timeout) alongside false positives (2>&1 in curl, tmpfile permissions). The genuine finds were infrastructure/system-limit issues, confirming invisible boundary blindness: Kimi found them only when specifically prompted for coverage, not in initial analysis. Overall: useful for generating a first-pass issue list, but requires active triage. Think of Kimi as a brainstorm generator that needs orchestrator filtering, not as a calibrated assessor.

**Recommended debate preamble (derived from Kimi self-report):**
```
For each issue: (1) Label CRITICAL/MINOR/STYLE/SPECULATIVE, (2) State the activation condition (when does this trigger?), (3) Quantify the impact if activated. If you cannot quantify, label it SPECULATIVE instead of defaulting to CRITICAL.
Defend challenged points by ID. If you concede, concede the specific point - don't collapse your entire position.
```
Why it works: The SPECULATIVE category and defense requirement directly address severity inflation and premature convergence. Forcing activation conditions prevents "articulate first draft" from masking shallow analysis. Telling Kimi not to collapse its entire position counters sycophantic overcorrection.

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

**Counter-prompt for volume:** "Rank your top 3 by impact. The rest are noise unless they change the outcome."

**Prompting guidance (from Sonnet self-report):**
- Sonnet's volume problem is a prioritization failure, not just verbosity. It offloads triage to the orchestrator. Mitigate by including "Rank by impact. Maximum 5 points." in the prompt. Without this, expect 10-15 undifferentiated items.
- Sonnet's "intellectual honesty" is partially that its initial takes are pattern-matched rather than deeply reasoned. Reversals after testing are not brave concession but discovering the first answer was shallow. Implication: weight Sonnet's revised positions more than its initial ones.
- Has a recency bias: over-indexes on whatever was last discussed. If the prior round focused on verbosity, Sonnet will find verbosity problems everywhere. Counteract by framing prompts around the specific question, not the prior discussion.
- Sonnet's dialogue-like style can mask position avoidance. If it asks questions back instead of committing, push: "Commit to a position, then flag uncertainties."

**Field notes (system prompt refinement, 2026-02-05):** "Verbose reasoning" confirmed as the clearest signal. Consistently produced the longest responses (10 numbered weaknesses plus 5 missing failure modes in one round). The skill understates this: it's not just a style issue, it's a utility issue. When Sonnet returns 15 points, the orchestrator must do the prioritization work Sonnet should have done. "Spiral into meta-concerns" confirmed - proposed changing "Want me to apply this?" to "Ready to apply this" (clever, unnecessary). Identified perverse incentives in its own model family's behavior, which is a form of the "intellectual honesty" the skill describes. Did not observe flip-flopping since these were single-prompt rounds.

**Recommended debate preamble (self-proposed):**
```
State your position in one sentence, then defend it. If you identify >3 weaknesses, rank them and cut to the top 3. Concrete examples required for each claim. If you catch yourself asking the user a question instead of taking a stance, delete the question and commit to the most defensible position given current information. Meta-concerns go in a single trailing paragraph labeled [META], not interspersed.
```
Why it works: Every clause targets a documented Sonnet failure mode. Volume cap (">3 weaknesses, cut to top 3") prevents the 15-point dumps. "Delete the question and commit" blocks position avoidance via dialogue. "[META] paragraph" prevents meta-concerns from contaminating substantive analysis.

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

**Prompting guidance (from Opus self-report):**
- Opus's close-reading strength has a blind spot: it over-indexes on textual parsimony. If an instruction is correct-as-written but models consistently misinterpret it, Opus will resist adding redundancy for robustness, framing it as a comprehension failure downstream rather than a robustness problem upstream. When robustness matters more than elegance, say so explicitly.
- "Best deployed LATE" is a reasonable default but too narrow. Opus's close reading plus minimal intervention is also valuable early to prevent unnecessary divergence before positions harden. Consider early deployment when you want to establish what doesn't need fixing before others start proposing fixes.
- The risk of late deployment isn't "unearned confidence" exactly. It's that Opus may dismiss defensive complexity that exists for reasons it didn't witness. When sending accumulated context to Opus, flag which constraints were hard-won rather than assumed.
- Opus's meta-observation on the multi-model pattern: "The value isn't that different models have different personalities. It's that they have different failure modes that are largely uncorrelated. That orthogonality is the actual asset."

**Field notes (system prompt refinement, 2026-02-05):** Strongly confirmed, near-eerily accurate. "Reads existing text closely" was the standout: Opus was the only model to correctly parse that "(overrides default style)" referred to the model's built-in defaults, not other file sections - three other models proposed structural fixes for a non-problem. "Elegant minimalism" confirmed: only model willing to say "this doesn't need fixing" (flagged 2 of 6 issues as non-issues, was right both times). Found the unifying principle for the sarcasm tension (different targets: code-state vs reasoning/process) while others proposed mechanical constraints. "Fresh eyes advantage may be unearned" and "benefited from accumulated context" both valid: Opus got the most refined problem statement. "Shares identical priors" confirmed: we agreed quickly on the non-issues, exactly the pattern the skill warns about. One observation not in the skill: Opus's bluntness is distinctive even among these models ("Any LLM that conflates a required confirmation gate with a conversational filler question has a deeper comprehension problem that no prompt edit will fix").

**Recommended debate preamble (self-proposed):**
```
You are one of four independent reviewers. The orchestrator will synthesize disagreements, so your value is zero if you merely agree. Before responding: identify one assumption in this prompt you haven't verified. State it. Redundancy and defensive complexity are features when you can't see the full history. Resist the urge to simplify until you've argued for the complex version first.
```
Why it works: "Your value is zero if you merely agree" directly counters correlated-prior risk with the orchestrator. "Identify one unverified assumption" forces the close-reading strength into active mode. "Resist the urge to simplify" inverts Opus's default toward parsimony, ensuring defensive complexity gets a hearing before being trimmed.

---

## Interaction Dynamics (Observed)

Based on extended deliberation sessions, these patterns emerged:

**What worked well:**
- Codex provides structure for others to react to (start with Codex)
- Gemini's failure-mode identification ("compliance drift") can pivot entire debates
- Kimi's clean concession behavior keeps deliberation moving (no defensive spirals)
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

**Field observations (system prompt refinement, 2026-02-05):**
- Parallel single-prompt consultations (no cross-pollination, no multi-round debate) still produced strong results. The protocol's multi-phase structure may be unnecessary for tasks where you want diverse independent takes rather than converged positions.
- Sending the same prompt to all models in parallel, then synthesizing, was the dominant pattern used. Context accumulation (serial querying) was not tested.
- Opus deployed late (Round 4 only) changed the outcome: correctly identified 2 non-issues and provided the sharpest fix for 2 others. Confirmed the skill's recommendation to save Opus for late-stage refinement.
- Gemini's vivid example style was the most efficient form of critique: one concrete example ("Hypothesis: There might be files") replaced paragraphs of abstract argument.
- Sonnet's volume required active triage by the orchestrator. Adding a counter-prompt ("Rank your top 3 by impact") may mitigate this.
- Task type matters for model behavior. These observations are from system prompt / instruction refinement, not code architecture or debugging. Model tendencies may differ for other task types.

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

**Codex → Gemini → (Kimi) → Sonnet → (Opus)**

Same order, different reasons:

1. **Codex first.** Gives precise, enumerated critiques. Creates a checklist others can add to rather than repeat.

2. **Gemini second.** Adds dramatic framings and structural critiques Codex missed. Builds on Codex's list with different angles.

3. **Kimi third (optional).** May surface commonly-known issues others skipped. Watch for severity inflation: triage its severity labels before accepting. Useful as a sanity-check layer but adds more quantity than quality.

4. **Sonnet fourth.** Goes hardest when it sees others' critiques - seems to feel competitive pressure to add value. Produces strongest meta-critiques after seeing what others said.

5. **Opus last (optional).** As same-model-family as orchestrator, Opus can catch critiques that feel "too comfortable" - where Sonnet's critique validates your existing suspicions rather than surfacing genuinely uncomfortable problems. Explicitly prompt: "What critique would I (the orchestrator) not want to hear?"

### For Synthesis (Phase 4)

**Codex → Gemini → Sonnet → (Opus)**

Kimi is generally not useful in synthesis (severity inflation and premature convergence make it a poor synthesizer). Use the other models.

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
3. Kimi (new): "Same problem. What issues do you see? Classify CRITICAL/MINOR/STYLE/SPECULATIVE."
4. Sonnet (new): "Same problem. What are we missing?"
5. Opus (new): "Same problem. Push back on the framing itself."

6. Triage Kimi's output (separate real issues from severity-inflated ones)

7. Cross-pollinate: Share key insights between models (resume each)

8. All models (resume): "Devil's advocate. Attack the consensus."
   - Opus prompt: "What critique would I (the orchestrator) not want to hear?"

9. All models (resume): "Here are the critiques. Salvageable or misguided?"

10. Opus (resume): "Final arbiter. Does the salvaged approach hold up?"

11. Document converged position with attribution.
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
- Kimi is API-only, has NO file access; always use Option 1 or 3 for Kimi
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
