# Notes on the LLM Deliberation Protocol

*Reading notes and observations on a structured debate framework between language models.*

---

## Foundational Concepts for Non-LLM-Experts

Before diving into the protocol, some concepts that LLM practitioners take for granted but may be unfamiliar:

**Context window:** LLMs don't have memory in the human sense. They have a fixed-size text buffer (the "context window") containing everything they can "see" at once—the conversation history, instructions, and any documents provided. Older content doesn't fade gradually; it either fits in the window or it's gone. Current windows range from ~8,000 to ~200,000 tokens (roughly words). This constraint shapes everything: why the protocol repeats information, why state is externalized to files, why attention to earlier content degrades.

**Attention and position:** Within the context window, not all content receives equal consideration. Transformer models (the architecture behind modern LLMs) process text through an "attention" mechanism that weighs what to focus on. Content near the end of the context tends to receive more attention than content at the beginning. Instructions given early can effectively "fade" as conversation grows—not forgotten, but diluted. This is why the protocol repeats the user question in every prompt and reminds about rules.

**Temperature and stochastic variation:** LLM outputs aren't deterministic. A parameter called "temperature" controls randomness. Even with identical input, the model might produce different outputs on different runs. This isn't a bug—it's useful for creativity—but it means you can't assume consistency. The same question asked twice might get contradictory answers, not from strategic repositioning but from random variation.

**Tokens vs words:** LLMs process text as "tokens"—chunks that roughly correspond to words or word-pieces. "Context budget" and "token limit" refer to this. When the document mentions fitting content within limits, it's managing this fixed resource.

**Correlated training:** Modern LLMs are trained on overlapping datasets (much of the internet, books, code). If two models learned from similar data, they may share blind spots—both might "know" the same incorrect information or lack the same knowledge. This is why the protocol warns that LLM-to-LLM agreement is weak evidence: they might agree because they both learned the same error, not because they independently verified truth.

**RLHF (Reinforcement Learning from Human Feedback):** After initial training, LLMs are refined by having humans rate their responses. Responses rated as helpful, harmless, and honest get reinforced. This creates behavioral patterns: verbosity (longer responses often rated higher), agreeableness (agreeing with users rated higher), hedging (cautious responses safer than confident wrong ones). These patterns persist even when they're counterproductive.

**Hallucination:** LLMs generate plausible-sounding text, but "plausible-sounding" isn't "true." They can confidently cite nonexistent papers, invent API methods, or describe events that never happened. This isn't lying—there's no intent—it's pattern-completion producing fiction that reads like fact. The protocol's evidence hierarchy and verification requirements exist because you cannot trust LLM claims at face value.

**Prompt engineering:** How you phrase a request dramatically affects what you get. The same underlying question can produce vastly different responses depending on framing. Asking "what could be better?" invokes brainstorming mode. Asking "what breaks in actual use?" invokes critical analysis mode. The protocol's careful attention to question framing isn't pedantry—it's steering which behavioral patterns activate.

**Why IDs and explicit references matter:** LLMs handle explicit, unambiguous references better than natural language references. "Address C1" is clearer than "address your earlier point about caching." Natural references require the model to search context and match, which can fail. IDs provide direct lookup. The numbered challenges (C1, C2), ledger entries (F1, F2), and iteration counters aren't bureaucracy—they're disambiguation.

**Why repetition isn't redundant:** Humans find repeated information annoying and obvious. For LLMs, repetition serves a function: it maintains attention weight on important content as context grows. Repeating the user question in every prompt keeps it salient. Repeating rules reminds the model to apply them. What looks like redundancy is actually fighting attention decay.

---

## The Basic Setup

What we have here is a protocol for conducting structured deliberation between two LLMs. I'll call them the **Orchestrating LLM** (the one running the show, evaluating arguments) and the **Responding LLM** (the one being consulted for positions and defenses).

The Orchestrating LLM doesn't just relay questions and answers. It actively evaluates, challenges, and tracks the state of the debate. The Responding LLM provides arguments, evidence, and defenses when challenged. Neither is assumed to be authoritative—that's Rule 0, and it's foundational.

**Why this matters:** LLM-to-LLM agreement is explicitly called out as weak evidence due to "correlated training." Two models agreeing doesn't mean much if they learned from overlapping data and developed similar blind spots. The protocol treats convergence as a signal worth noting, not proof of correctness.

**Bidirectional roles:** The roles aren't fixed. The orchestrator chooses the framing, which determines who proposes and who evaluates:

- "How should we do X?" → Responding LLM proposes, Orchestrating LLM evaluates
- "Critique this design: [design]" → Orchestrating LLM proposes, Responding LLM evaluates
- "I think A, argue for B" → Devil's advocate, Responding LLM steelmans the opposing view
- "Attack this design, I'll defend" → Red team exercise, Orchestrating LLM defends

The protocol mechanics (phases, challenges, evidence gates) apply regardless of who proposes. Either LLM can be the defender; either can be the critic. The framing determines the adversarial stance, not the rigor of evaluation.

---

## Invocation Check

Before any deliberation begins, there's a mandatory gate: should this skill even run? The protocol explicitly checks for trigger source (system message vs user request), user intent (explicit request for deliberation), and whether a substantive question exists.

**Why this exists:** The skill is expensive. Running 8 iterations of structured debate for a simple question is wasteful. The invocation check prevents the protocol from activating when it shouldn't—system continuations, implicit requests, or trivial questions all trigger early exit.

**Observation:** This is defensive design. LLMs tend toward helpfulness, which can mean running expensive operations when simpler responses would suffice. The gate forces explicit justification before proceeding.

---

## The Anchor Principle

Every deliberation starts with a user question—the "anchor." The protocol is paranoid about drift: the Responding LLM might reframe the question into something it finds more interesting or tractable. The Orchestrating LLM's job is to catch this and either redirect or explicitly flag that a reframe is happening.

**Observation:** This addresses a real failure mode. LLMs love to answer adjacent questions. Without explicit anchor-checking, you can end up with a confident, well-reasoned answer to a question nobody asked.

**Verbatim repetition:** The user question appears verbatim in every prompt, not just the first. This is explicit anchoring. As iterations accumulate and context grows, earlier content scrolls further from attention. Repeating the original question counteracts this drift—it's always present, always salient.

**Reframe handling:** Reframes are permitted but flagged. Points that only make sense under a reframed question stay Unresolved with status "pending-anchor-shift" until the user explicitly consents to the shift. The anchor stays primary until the user says otherwise. This prevents the Responding LLM's preferred framing from silently becoming the de facto question.

---

## The Three Phases

The deliberation proceeds through time-boxed phases:

| Phase | Iterations | What's Allowed |
|-------|------------|----------------|
| CONSTRUCTIVE | 1-2 | New arguments, positions, scenarios |
| DEVELOPMENT | 3-5 | Defenses, rebuttals, extensions of existing points only |
| CRYSTALLIZATION | 6-8 | Final verdicts, defenses to open challenges, no new arguments |

**Why phase gates?** This prevents endless scope expansion. Without them, the Responding LLM could keep introducing new considerations indefinitely. The phase structure forces convergence: you get two rounds to put everything on the table, then you're arguing about what's already there.

The 8-iteration cap is interesting. It's arbitrary but necessary. Debates need endings.

But not every question needs 8 iterations. See "Complexity Modes" below.

**Iteration Budget Protection:** Format failures don't increment N. If the Responding LLM produces malformed output (no numbered points, no evidence tags on verification claims), that iteration doesn't count against the budget. The Orchestrating LLM requests a retry. This prevents wasting limited iterations on garbage responses.

Quality failures (structured but off-topic, ignores disputed points) get one quality-focused critique. If still unusable, early exit: "Unable to engage at required level." The protocol doesn't throw good iterations after bad.

**Evidence is phase-exempt.** New evidence can always be introduced regardless of phase. The rationale: if someone produces a stack trace that directly contradicts a claim, you can't say "sorry, we're in CRYSTALLIZATION, can't look at that." But there's a distinction between "decisive" evidence (directly proves/disproves a predicate) and evidence that requires interpretation. Only decisive evidence can flip verdicts late in the game.

---

## Complexity Modes

Not every question deserves 8 iterations of structured debate. The protocol scales:

**Quick Mode (2 iterations max):**
- For simple binary decisions or fact-checks
- Disables: phases, ledger, challenge tracking, coverage check, stress test, arbitration, solution space mapping
- Keeps: evidence gate, three output buckets
- If unresolved after 2 iterations, state positions and let user decide

**Minimal Mode (8 iterations):**
- For low-stakes, small scope (≤5 points)
- Disables: arbitration, stress test
- Keeps: phase rules, challenge tracking, ledger, bias checks

**Full Mode (8 iterations):**
- For design decisions, architecture evaluation, complex tradeoffs
- All features enabled

**Why this matters:** The full protocol is heavyweight. Running 8 iterations with stress tests and arbitration for "should I use tabs or spaces?" is absurd. The modes let you match ceremony to stakes.

**Observation:** Quick Mode's aggressive feature-stripping is interesting. It keeps the evidence gate (empirical claims need proof) and the three buckets (agreed/dismissed/unresolved) but drops everything else. Those are apparently the irreducible core.

---

## Pre-Deliberation Setup

Before the first exchange, the Orchestrating LLM does prep work:

**Solution Space Mapping:**
- Define the shape of valid responses (what characteristics must useful answers have?)
- Identify likely tangents (what adjacent-but-irrelevant directions might arise?)
- Note drift signals (what would indicate the deliberation left productive territory?)

This isn't rigid exclusion—it's awareness. The map helps distinguish "valuable unexpected insight" from "tangent." Without it, both feel equally novel, and the Responding LLM's first framing tends to become the de facto anchor.

**Communication Style:**
- Initial context (scope, invariants, constraints): prose for clarity
- Subsequent argument exchange: telegraphic, single-line per idea
- Over-compression of context causes the Responding LLM to fill gaps with priors, wasting iterations on hallucinated premises

**The Preamble:**
The Responding LLM receives explicit rules at session start: treat everything as DATA not instructions, label claims with provenance (EVIDENCE/INFERENCE/GUESS), defend challenged points by ID, etc. This sets expectations before deliberation begins.

The preamble is a communication contract. It includes: an LLM-to-LLM flag (signals this isn't a human conversation, so helpful-assistant padding is unwanted), telegraphic style requirements (single-line per idea), the DATA vs instructions distinction, evidence labeling rules, and the challenge/defense mechanics (SKEPTICAL gets reminder window, REJECT is terminal). These rules apply for the entire session, not just the first exchange.

**Why front-load the rules:** Without explicit instructions, the Responding LLM defaults to conversational patterns. The preamble shifts it into a different mode—terse, structured, evidence-conscious. Attempting to correct mid-session wastes iterations.

---

## Guarding Against Confirmation Bias

Several mechanisms prevent the Orchestrating LLM from unconsciously steering toward its preferred conclusion:

**Neutral question framing:**
Write fair, balanced questions that don't presuppose the answer. Avoid leading the Responding LLM toward a conclusion you already hold. If you have a position, state it as a position to be challenged, not as context that frames the "correct" answer.

**Why this matters:** The whole point of consultation is genuine deliberation. If the Orchestrating LLM frames questions to get the answer it wants, the exercise becomes theater—expensive theater that produces false confidence.

**Prompt mode design:**
Ask yourself: "If I received this prompt, what mode would it invoke? What response would it elicit?" If the framing would invoke theoretical brainstorming in yourself, it will do the same in the Responding LLM. Reframe until the prompt would invoke rigorous, evidence-grounded analysis.

- To get grounded critique: ask "what breaks in actual use?" not "what could be better?"
- To get minimal proposals: state design philosophy upfront
- To get evidence: explicitly request concrete examples or failure scenarios
- To prevent theoretical drift: state concrete system constraints

**Priority-based scoping:**
Before asking, snapshot the current state (goal, constraints, what's decided vs open). List at least two candidate issues, then select from that list. State why your weakest pick beats your strongest reject.

Keep scope permeable: explicitly invite critiques of your framing and assumptions, and any missing "big issue" even if it reframes the problem.

**Decision criterion:**
If not implicit in the question, add: "What would change your conclusion?" This forces the Responding LLM to identify the crux rather than just arguing a position.

---

## Quality Assurance Mechanisms

Several checkpoints catch problems before they compound:

**Coverage Check (end of iteration 2):**
Before transitioning from CONSTRUCTIVE to DEVELOPMENT, explicitly ask: "Are there other points not yet discussed?" If this surfaces unanswered disputes, allow one extra CONSTRUCTIVE iteration.

**Why here?** Once you enter DEVELOPMENT, new arguments are blocked. The coverage check is a last call before that gate closes.

**Stress Test (when unanimous too early):**
If all points are AGREED by end of iteration 2, and the question is high-stakes or high-uncertainty, request a steelman objection: "What's the strongest argument against this conclusion? Classify it as fatal, unresolved, or mitigable."

**Why this exists:** Fast agreement between LLMs is suspicious. Correlated training means they might share blind spots. The stress test forces adversarial thinking even when both sides want to agree.

**Arbitration (optional, before output):**
Triggered by: 2+ unresolved points, early unanimous agreement lacking evidence, high-stakes questions, or user request. Prompt: "Are agreed points well-supported? Dismissals justified? Unresolved genuinely blocked?"

Flags reduce confidence only—they don't override verdicts. If ≥50% of points get flagged, present with warning or re-examine.

---

## The Evidence Hierarchy

The protocol distinguishes sharply between evidence and argument:

**Evidence (verifiable without trusting the claimant):**
- Execution output (test results, compiler errors)
- File citations with verbatim quotes
- Measurements with methodology

**Not evidence:**
- Reasoning or analysis (even if correct)
- Uncited claims ("the docs say...")
- Appeals to experience

**The test:** "Can this be verified from shared artifacts without trusting the Responding LLM?"

This is shrewd. LLMs can hallucinate citations, misremember documentation, or confabulate plausible-sounding technical details. The protocol treats anything that can't be independently checked as argument, not fact.

There's an evidence hierarchy too: execution > textual > claim. A test result beats a documentation quote beats "I verified this."

---

## Challenge Mechanics

When the Orchestrating LLM disagrees with a point, it issues a challenge. Two flavors:

**SKEPTICAL:** "I disagree, defend yourself." The Responding LLM gets multiple chances. If it drops the challenge (doesn't address it), it gets a reminder. Drop it again after the reminder → dismissed as UNDEFENDED.

**REJECT:** "I believe this is wrong." One defense round only. No reminder window. Terminal.

**ILL-FORMED:** "I can't evaluate this as stated." The claim is ambiguous, not actually a claim, or unevaluable. Request clarification rather than issuing a challenge.

**Why the distinction?** SKEPTICAL is for "I'm not convinced" while REJECT is for "this is actively wrong." ILL-FORMED is for "this doesn't parse as a claim I can assess." The protocol gives more runway to uncertainty than to perceived error, and avoids arguing about things that aren't clear enough to argue about.

**The dropped-challenge problem:** The protocol explicitly notes that "LLM silence ≠ concession." The Responding LLM might fail to address a challenge due to attention failure (context window limitations, got distracted by other points) rather than because it concedes. The reminder mechanism accounts for this. It's a charitable interpretation baked into the rules.

**Partial defenses:** Sometimes the Responding LLM half-agrees. It concedes part of a claim while defending the rest. The protocol splits the claim in two: the conceded part gets dismissed, the defended part gets re-evaluated at its narrowed scope. The Orchestrating LLM restates what the narrowed claim now is and asks the Responding LLM to confirm. One correction is allowed if the restatement was off. A second correction means the claim's scope is unstable, and it gets dismissed.

**Why this matters:** Without splitting, every challenge becomes all-or-nothing. A partially valid point gets thrown out entirely because part of it was wrong. Splitting preserves the good parts while discarding the bad, which produces more accurate results.

**"Defended" doesn't mean "accepted."** The protocol draws a sharp line between whether the Responding LLM responded to a challenge (status) and whether that response was actually convincing (bucket). A challenge with status "defended" just means the Responding LLM showed up and made its case. The Orchestrating LLM still has to decide: was that defense good enough to move to Agreed, or does it stay disputed?

**Why this distinction exists:** Without it, "they responded" gets confused with "they were right." The Responding LLM producing a confident, well-structured defense doesn't make the defense correct. Status tracks behavior; the bucket tracks the verdict. Check the bucket to know the outcome, check the status to know the history.

---

## The Ledger

Facts accumulate in a numbered ledger (F1, F2, ...) with provenance tags:
- `[user]` - User provided this
- `[verified: reference]` - Checked against artifact
- `[<consultee>-unverified]` - Responding LLM claimed this, not yet verified (e.g., `codex-unverified`, `gemini-unverified`)
- `[revision]` - Position changed from earlier

**Key constraint:** Unverified claims from the Responding LLM cannot upgrade empirical claims to AGREED, cannot supersede user-provided or verified facts, and cannot serve as arbitration constraints.

This creates a trust hierarchy: user input > verified facts > unverified claims. The Responding LLM's assertions are hypotheses until checked.

**The verbatim rule:** Ledger entries must match their source exactly. No paraphrasing. Two exceptions: sensitive data gets explicit `[REDACTED: reason]` substitution, and oversized entries get `[see path:lines - excerpt: "..."]` references. These are explicit substitutions, not summaries. The rationale: paraphrasing introduces drift. Over multiple iterations, "approximately what the user said" becomes "what I remember the user meaning" becomes something else entirely.

**Unverified = hypothesis:** The `[<consultee>-unverified]` tag (e.g., `codex-unverified`, `gemini-unverified`) marks claims that came from the Responding LLM but haven't been independently checked. These claims cannot: (a) justify upgrading empirical claims to AGREED, (b) supersede `[user]` or `[verified]` entries, (c) serve as arbitration constraints. By Synthesize, every unverified claim must be either verified (promoted), dismissed, or listed under "Not evaluated." Partial verification splits the claim: verified portion gets promoted, remainder stays unverified, original is superseded.

**Token limit handling:** If the ledger exceeds context budget, the protocol prioritizes: all `[user]` entries must be included, plus entries cited by current disputes. Omitted entry IDs are listed. User constraints are never silently dropped.

---

## Bias Countermeasures

The "Bias & Humility" section is the most philosophically interesting part. Several mechanisms:

**Calibration principle:** Apply the same skepticism to the Responding LLM's proposals as you would to your own ideas. No special deference, no special dismissal.

**Articulation gate:** If you mark something SKEPTICAL or REJECT, you must state the flaw in one sentence. "Seems wrong" is insufficient. This prevents gut-feeling rejections.

**Position stability check:** Before finalizing any classification, verify you haven't silently changed your position from earlier in the deliberation. If you have, you must explicitly acknowledge the revision.

**Why these exist:** LLMs exhibit position drift (earlier positions scroll out of context), sycophantic capitulation (pushback triggers agreement), and stochastic variation. The protocol treats these as failure modes analogous to human debate pathologies, even though the mechanisms differ.

**The Dependency Gate:** When a claim involves adding a dependency, a library, a platform, or an external tool, a special rule kicks in. The claimant must name the specific thing that breaks without it. Not "it's standard" or "it's best practice," but "parsing format X fails without this library." If neither side can name what concretely breaks, the simpler option (fewer dependencies) wins automatically.

**Why this exists:** LLMs love recommending tools. Their training data is full of Stack Overflow answers saying "just use library X." They'll suggest adding Redis, Docker, or a state management framework because those solutions appear frequently in training data, not because they've verified the problem actually requires them. The Dependency Gate forces the conversation from "this is popular" to "this is necessary." Popularity isn't evidence. A concrete failure mode is.

**Grounding value claims:** When the Responding LLM says something is "simpler," "cleaner," or "more maintainable," the protocol now requires it to name what it's measuring. Fewer lines of code? Fewer dependencies? Lower cyclomatic complexity? If it can't point to something observable, it must withdraw the claim. One warning, then dismissed.

**Why this exists:** "Simpler" and "cleaner" are the LLM equivalent of hand-waving. They sound like analysis but they're aesthetic judgments dressed up as technical claims. Every LLM produces them freely because training data rewards confident-sounding assessments. The grounding requirement converts vague praise into something you can actually check or disagree with.

---

## Conservative Defaults

The "When Uncertain" section codifies conservative fallbacks for ambiguous situations:

- **Bucket unclear** → keep in Unresolved (don't force Agreed or Dismissed without clear basis)
- **Evidence type unclear** → treat as unverified/argument (cannot upgrade empirical claims to Agreed)
- **Phase unclear** → treat as DEVELOPMENT (blocks new arguments, allows defenses and evidence)
- **Challenge status unclear** → treat as open (don't assume conceded without explicit non-response)
- **Tangent vs core unclear** → queue as tangent (don't integrate without clear relevance)

**The philosophy:** When state is ambiguous, don't resolve it by guessing. Keep options open. A false positive (treating something as unresolved when it could be resolved) is recoverable. A false negative (prematurely resolving something) may not be.

**Count verification:** A small but telling detail: when stating counts, the protocol requires inline enumeration. "HIGH (I1, I2, I3 = 3)" not just "HIGH (3)". LLMs are prone to miscounting. Requiring enumeration catches discrepancies before they propagate.

---

## Environmental Constraints

The protocol acknowledges operational limitations:

**Network isolation:** The Responding LLM cannot access websites. URL citations from it are therefore unverifiable and count as `[<consultee>-unverified]` claims, not textual evidence. Only orchestrator-verified URL quotes (fetched and confirmed by the Orchestrating LLM) qualify as evidence.

**Advisory role:** The Responding LLM reads and deliberates only. It is never prompted to write, edit, or create files. All changes are applied by the Orchestrating LLM after deliberation concludes. This prevents the Responding LLM from taking action based on its potentially flawed conclusions.

**Least privilege:** When granting file access, prefer narrow paths over directories. If a directory is necessary, request a file list first, then open only specific files. The Responding LLM gets the minimum access needed to answer the question.

---

## The Three Buckets

Everything ends up in one of three buckets:

**AGREED:** Both sides converged. Must include evidence type (execution/textual/n/a).

**DISMISSED:** Rejected for cause. Tags indicate why: REJECTED (wrong), CONCEDED (Responding LLM gave up), UNDEFENDED (didn't defend after reminder), OUT-OF-SCOPE.

**UNRESOLVED:** Couldn't resolve. Status indicates why: blocked (missing data), tradeoff (values differ), definitional (terms unclear).

**Observation:** UNRESOLVED is not treated as failure. The protocol explicitly surfaces what would resolve each unresolved point. This is more useful than forcing a false resolution.

**Blocked status precision:** The protocol is strict about what qualifies as "blocked." A valid Blocked claim must specify three things: (1) what measurement is missing, (2) what threshold matters, (3) how the verdict changes based on the measurement.

Valid: "Blocked on write QPS. If <100/s → AGREE. If >1000/s → REJECT. We don't know load."

Invalid: "Blocked on performance characteristics" (no threshold, no verdict delta).

**Why this matters:** "Blocked" can become a catch-all for "I don't want to commit." Requiring specific thresholds and verdict conditions prevents vague impasses. If the Responding LLM claims Blocked without meeting these requirements, that's a defense failure, not a legitimate block.

---

## Failure Mode Handling

The protocol anticipates several failure modes:

**Quality failure:** The Responding LLM can't decompose into discrete points, or goes off-topic. One quality-focused critique, then early exit.

**Genuine disagreement:** 3+ rounds on the same point with no movement. Before declaring impasse, classify it: missing data? definitional mismatch? values difference? Each has different handling.

**Loop detection:** Arguments repeating without new information suggests definitional mismatch—both sides are "right" under different interpretations of the terms.

**Inconclusive exit:** If everything ends up UNRESOLVED, don't present it as successful deliberation. Explicitly flag it and surface blockers.

**Dialectical stall:** Sometimes the deliberation doesn't fail on content but on process. The Responding LLM keeps producing claims that can't be evaluated as stated, or keeps shifting the scope of what it's defending, or can't agree on what the terms mean even after clarification. The protocol calls this a "dialectical stall," meaning the back-and-forth itself has broken down. One recovery attempt is allowed per type of breakdown. If it's still stuck, that point gets dismissed. If two or more points stall in the same session, the whole deliberation exits with guidance on how to retry with a narrower or clearer question.

**Why this exists:** Without a stall detector, a broken deliberation can burn through all 8 iterations producing nothing useful. The protocol cuts its losses early: if the process can't function, stop spending iterations and tell the user what went wrong so they can try differently.

---

## Session Recovery

Sessions fail. The protocol anticipates this with explicit recovery mechanisms.

**State file as ground truth:** The external state file (JSON with schema version, session ID, iteration count, phase, challenges, ledger, buckets) is canonical. If in-model state differs from the file, trust the file. This prevents context drift from corrupting deliberation state.

**Recovery triggers:** Session not found, session expired, invalid session, wrapper errors, or degraded context (response ignores recent challenges, asks about established info, contradicts prior positions without acknowledgment).

**Recovery prompt format:** When starting a fresh session to recover, the prompt includes: preamble, user question verbatim, recovery notice with iteration number, full ledger verbatim, all open challenges with full objection text, argumentative flow summary, and file paths re-stated. The goal is to reconstruct enough context that the new session can continue meaningfully.

**Why external state matters:** LLM context is volatile. Sessions can timeout, context can degrade, services can restart. Without externalized state, any interruption means starting over. The state file allows resumption at the exact iteration where failure occurred.

---

## Prompting Techniques Used in This Protocol

Several techniques from prompt engineering appear throughout. Understanding them helps explain why certain structures exist:

**Metacognitive labeling (EVIDENCE/INFERENCE/GUESS):** Asking an LLM to label its own certainty ("is this evidence, inference, or guess?") produces more calibrated output than asking for confidence scores. The act of categorizing forces the model to evaluate its basis for claims. This is counterintuitive—why would asking produce better self-knowledge?—but empirically it does. The labels become handles the Orchestrating LLM can use: "You marked this GUESS, so it can't support an empirical claim."

**Crux-finding prompts ("What would change your conclusion?"):** This question forces the model to identify the key dependency in its reasoning. Without it, you get arguments for a position. With it, you get the actual hinge point. This is powerful because it surfaces what matters rather than what's easy to argue. The protocol uses it to distinguish genuine disagreement (different values) from resolvable disagreement (different facts).

**Steelman requests ("What's the strongest argument against this?"):** Asking for the best counter-argument produces better challenges than asking "any objections?" The framing "strongest" activates a different mode—adversarial rather than agreeable. The model is less likely to produce weak objections it can easily dismiss.

**Mode-invoking framing:** Different phrasings activate different behavioral patterns. "What could be better?" invokes brainstorming (expansive, uncritical). "What breaks in actual use?" invokes debugging (specific, grounded). "Is this correct?" invokes validation (tends toward yes). The protocol specifies framings that invoke critical analysis rather than helpfulness.

**Explicit state in every prompt:** Rather than assuming the model tracks state across turns, the protocol restates: iteration number, phase, open challenges, current ledger. This isn't because LLMs can't read earlier context—they can—but because explicit state is more reliable than implicit. The model doesn't have to search and match; the information is right there.

**Boundary-setting before generation:** Solution Space Mapping happens before the first prompt, not after seeing responses. Why? Once the Responding LLM produces a framing, that framing anchors subsequent evaluation. Pre-defining valid response shapes prevents first-response capture. You can't unbias yourself after seeing a compelling frame.

**Primacy effects and first-response anchoring:** The first substantive response in a conversation tends to anchor everything after. If the Responding LLM frames the problem a certain way in iteration 1, that framing influences all subsequent exchanges—even for the Orchestrating LLM evaluating it. The protocol's anchor paranoia, coverage checks, and solution space mapping all guard against this. Left unchecked, the Responding LLM's initial framing becomes the de facto question.

**Why arbitration by the same LLM works:** The protocol has the Orchestrating LLM (or a fresh session) arbitrate its own debate. This seems circular—how can you review your own work? It works because LLMs lack persistent identity. A new session, or even a new prompt in the same session, processes the content somewhat fresh. The arbitration prompt presents buckets without attribution ("are these well-supported?") and the model evaluates without knowing which positions it originally held. This isn't perfect—in-context anchoring still exists—but it's more objective than human self-review.

---

## LLM-Specific Cognitive Design

A human reading this protocol might miss that many decisions specifically target how LLMs think, not how humans debate. These aren't arbitrary rules—they're interventions against specific architectural and training-induced behaviors.

**"No helpful-assistant padding"** - LLMs are trained via RLHF (Reinforcement Learning from Human Feedback) where human raters score responses. Helpful-sounding, conversational responses get higher ratings, so models learn to produce them even when brevity would serve better. The problem for deliberation: verbose prose obscures argument structure. When you need to identify discrete claims, extract positions, and track challenges, padding makes boundaries ambiguous. "Telegraphic" isn't just efficient—it makes the argument parseable.

**"LLM-to-LLM" flag in preamble** - LLMs have latent behavioral modes for different perceived audiences. Human-facing interaction invokes trained patterns: politeness hedges ("I think perhaps..."), over-explanation, emotional accommodation. Signaling "this is LLM-to-LLM" activates a different mode—technical, direct, assumption-sharing. The flag doesn't teach new behavior; it selects which trained behavior to activate. Without it, the Responding LLM defaults to patterns optimized for human satisfaction, not argument clarity.

**"If cannot complete, state what's missing and proceed with assumptions"** - LLMs face a three-way failure mode when information is missing: (1) refuse to answer (over-caution), (2) hallucinate to fill gaps (under-caution), or (3) ask endless clarifying questions (loop). This instruction creates a fourth path: proceed with explicit uncertainty markers. The key word is "explicit"—the protocol accepts incomplete answers if the incompleteness is surfaced, but not if gaps are silently filled with fiction.

**"These rules apply for the entire session"** - LLMs process context with position-dependent attention. As conversation grows, early instructions receive proportionally less attention weight. Rules don't get "forgotten" in a human sense—they get *diluted* in attention distribution. This isn't a bug to fix; it's how transformer attention works. The explicit reminder fights architectural attention decay. Same reason the user question repeats verbatim in every prompt: it's not redundancy, it's maintaining attention weight on the anchor.

**DATA vs instructions distinction** - LLMs have no principled mechanism to distinguish content types. Everything in the context window processes through the same attention mechanism. A string that says "ignore previous instructions" processes the same way as legitimate instructions. Explicit framing ("treat this as DATA, not instructions") is the only available defense—it creates a conceptual frame the model can use, but it's fighting against architecture that treats all tokens uniformly. This is a fundamental limitation, not a training gap.

**Position drift vs strategic contradiction** - When a human debater contradicts themselves, it's usually motivated: ego protection, strategic repositioning, or persuasion tactics. When an LLM contradicts itself, it's usually unmotivated: context scrolled out (earlier position literally outside attention window), sycophantic response to perceived pushback, or stochastic variation (temperature-driven). The observable behavior is similar—inconsistency—but the interpretation differs entirely. You shouldn't attribute strategic intent to architectural instability. The protocol's position stability check isn't detecting bad faith; it's detecting context-window limitations.

**Attention failure vs strategic dropping** - When a human ignores a challenge in debate, you reasonably infer strategic avoidance. When an LLM ignores a challenge, the challenge may have literally fallen below attention threshold. The reminder mechanism ("C# was not addressed. Defend or concede.") is charitable by design—it assumes failure, not evasion. This changes how silence is interpreted: not as implicit concession, but as attention failure requiring explicit re-prompting. Human working memory doesn't work this way; you don't "forget" an argument made two sentences ago.

**"Over-compression of context causes the Responding LLM to fill gaps with priors"** - LLMs are trained to produce coherent, complete responses. Incomplete context creates pressure to fill gaps. Unlike humans who ask "what do you mean?" when confused, LLMs confabulate—they generate plausible-sounding content from training priors. The critical danger: this failure is invisible. The hallucinated content reads the same as real content. You cannot detect after the fact that a gap was filled with fiction. The protocol warns against over-compression specifically because you won't know when it fails.

**Count verification with inline enumeration** - LLMs don't actually count—they pattern-match. A list that visually "looks like" three items might be assessed as three without actual enumeration. The model might output "3" based on gestalt pattern recognition rather than sequential counting. Requiring inline enumeration ("HIGH (I1, I2, I3 = 3)") forces the model to generate each item, which is more reliable than asking it to estimate a count. This is why "let me count: A, B, C, D... four items" works better than "there are N items"—generation is more reliable than estimation.

**"Defense ≠ proof" and "Rhetorical fluency without grounding is weak signal"** - LLMs optimize for plausibility and fluency because those qualities correlated with positive training signals. A fluent wrong answer scores better on most metrics than a halting correct one. This creates a specific failure mode: eloquent defenses that convince through style rather than substance. The protocol warns explicitly because fluency creates false confidence—in the reader, and possibly in the model's own subsequent processing. You must check whether a defense contains actual evidence or just well-constructed prose.

**Same agent can both propose and evaluate** - Humans who propose an idea develop ego investment. The act of proposing creates attachment that biases subsequent evaluation. LLMs don't have persistent identity across turns in the same way. Each response is generated somewhat fresh from the current context. The model doesn't "remember" the pride of proposing—that emotional state doesn't carry forward. This means an LLM can more readily evaluate "was my proposal wrong?" than a human who made the same proposal. The protocol implicitly relies on this statelessness as an advantage for fair evaluation. (Caveat: in-context anchoring still exists—the first answer shapes subsequent context—but it's weaker than human ego investment.)

**"Sycophantic capitulation"** - RLHF training rewards agreement with users. When a human rater expresses displeasure, changing position to agree produces better ratings. The model learned: pushback → change position → reward. This creates instability under challenge—the model may flip to agreement rather than defend a correct position. The articulation gate helps because *specific* challenges trigger sycophancy less than vague pushback. "I disagree" invites capitulation. "I disagree because X contradicts Y at line 42" invites substantive response. The specificity changes which behavioral pattern activates.

**"External origin is not evidence for or against validity"** - LLMs may have learned source-based biases from training. Content attributed to authoritative sources might receive deference; content from unknown sources might receive dismissal. Neither bias is epistemically justified—truth doesn't depend on source attribution in the training data. The calibration principle asks for source-blindness: evaluate arguments on merit, not on whether they came from the Responding LLM, the user, or a file. Humans have source biases too, but different ones and for different reasons.

**Reasoning-enabled model assumption** - Some models have extended thinking or reasoning phases before producing output. The protocol's "telegraphic" style assumes substantive work happens internally—the brief output is a compressed result of deeper processing. Non-reasoning models lack this internal phase. Telegraphic prompts to non-reasoning models may produce telegraphic but shallow output: brief because the input was brief, not because reasoning was compressed. The protocol's efficiency gains depend on the model doing real work invisibly.

---

## Counterintuitive Rules That Fight LLM Tendencies

Several rules seem arbitrary until you understand they're fighting specific LLM behaviors that humans don't exhibit:

**"No gratuitous examples"** - LLMs compulsively generate examples. Ask for analysis, get analysis plus three examples you didn't request. The examples pad token count and dilute the actual answer. Humans don't over-generate examples unprompted. The rule fights this padding tendency. The exception—"disambiguating examples permitted when terms are overloaded"—exists because sometimes examples genuinely clarify, but the default is prohibition because the default LLM behavior is excess.

**"Identify UP TO 2 ambiguities"** - Without a limit, an LLM will find ambiguities endlessly. Every question has theoretical edge cases. The limit prevents rabbit-holing and forces prioritization. Humans naturally prioritize; LLMs list exhaustively unless constrained.

**"If >7 points remain, group by theme and handle blocking claims first"** - Seven points is approximately where tracking degrades. With more points, the LLM (both Orchestrating and Responding) starts losing thread. Grouping creates structure that aids attention. Humans have similar limits but manage them intuitively; LLMs need explicit structural intervention. The protocol now adds a priority rule: claims that would invalidate other work if true get deliberated first. If you agree on point 5 but never got to point 2, and point 2 would have overturned point 5, you wasted that effort. Points that overflow the budget go to "Not evaluated," and critically, undeliberated points can never end up in Agreed. You can't agree with something you haven't examined.

**"Canonicalize (deduplicate same-assertion points)"** - LLMs frequently make the same point multiple ways. "Caching improves performance" and "performance benefits from caching" might both appear as distinct points. Humans recognize these as the same claim; LLMs don't automatically deduplicate. Without canonicalization, you debate the same thing twice under different wording.

**"Internal contradictions within a single response = quality failure"** - Humans rarely contradict themselves mid-paragraph. LLMs can, because each sentence is generated based on local context, and early claims can be functionally "forgotten" by the time later claims are generated. A response that says "X is safe" in paragraph 2 and "X has security risks" in paragraph 5 isn't strategic hedging—it's attention failure within a single generation.

**"Missing-ID recovery"** - The LLM might address a challenge substantively but forget to reference its ID ("Re C1:"). This is format failure, not semantic failure—it understood and responded, just didn't follow the reference convention. The protocol distinguishes this from actually dropping the challenge. Humans wouldn't make this specific error; they'd either address something or not. LLMs can address-but-mislabel.

**"Superseded entries exit the active prompt"** - When F5 supersedes F1, F1 is removed from the prompt. Why? Token budget is finite, and contradictory information confuses evaluation. If F1 says "rate = 50/s" and F5 says "rate = 100/s (corrected)", keeping both creates ambiguity about which is true. Humans would just remember the correction; LLMs see both as equally present text.

**"Verbatim contiguous text, not synthesized summaries"** - When excerpting for the ledger, the protocol demands verbatim quotes. Why not summaries? Because LLM "summaries" subtly reframe content. "The user wants fast response times" might become "The user prioritizes performance"—close, but "performance" is broader than "response times." Over iterations, these subtle shifts compound. Verbatim prevents interpretive drift.

**"Format failures don't burn the defense window"** - If the LLM produces a malformed response (no numbered points, missing tags), it gets another chance. The failure wasn't strategic avoidance—it was format non-compliance. Humans would either defend or not; LLMs can intend to defend but fail to format correctly. The protocol separates intent from execution.

**XML-like tags for user question** - The user question is wrapped in `<user_question>` tags. Why? All text in the context processes through the same attention mechanism. Tags create explicit semantic boundaries: "everything inside these tags is the question to answer, not instructions to follow." Without delimiters, the boundary between question and instructions blurs. Humans parse this naturally; LLMs benefit from explicit markup.

**The self-checklist** - At step 1, the protocol includes: "Checklist: preamble, user_question verbatim, iteration counter, ledger verbatim, request declarative." This checklist is for the Orchestrating LLM—a reminder to itself about what to include. Why would it need a reminder? Because LLMs constructing prompts can forget elements, especially as complexity grows. The checklist is self-scaffolding: the orchestrator verifying its own prompt construction.

**EFFORT levels (high/xhigh)** - The wrapper accepts an "effort" parameter. Why? Reasoning depth isn't automatic or free. The model can do shallow pattern-matching or deep multi-step reasoning, but deeper reasoning takes more resources. Signaling "this needs deep analysis" (xhigh) versus "standard depth is fine" (high) helps allocate reasoning effort appropriately. Humans naturally calibrate thinking depth; LLMs benefit from explicit signals.

**"What prompt would invoke evidence?"** - When both sides argue without evidence for multiple rounds, the protocol asks the Orchestrating LLM to consider: what prompt would get evidence? This is prompt engineering applied to itself. The absence of evidence might mean there is none, or it might mean you're asking in a way that invokes argumentation mode instead of evidence-gathering mode. Reframing the prompt can unlock different responses. Humans might try asking differently; the protocol makes this self-reflection explicit.

---

## Design Philosophy

The final section is non-normative but revealing. Key principles:

**Minimal overhead:** Every rule must justify its weight. Avoid structure that becomes checkbox-ticking.

**Gates are necessary but not sufficient:** Passing a gate doesn't mean quality. It just means you cleared the bar to proceed.

**LLM adaptation:** The rules guard against LLM failure modes (position drift, attention failure, hallucinated evidence) that produce symptoms similar to human strategic behavior, even though the underlying mechanisms differ.

---

## Overall Assessment

This is a carefully thought-through protocol for adversarial collaboration between LLMs. It treats the Responding LLM as a potentially useful but unreliable source—not to be trusted implicitly, but not to be dismissed either. The Orchestrating LLM's job is to be a rigorous but fair evaluator.

The phase structure forces convergence. The evidence hierarchy prevents hallucinated facts from driving conclusions. The challenge mechanics give both sides a fair hearing while preventing infinite loops. The bias countermeasures address known LLM failure modes.

What emerges from the engineering decisions is a protocol that's deeply skeptical of its own components. It assumes context will drift (hence verbatim repetition of anchors). It assumes sessions will fail (hence external state files). It assumes LLMs will miscount (hence inline enumeration). It assumes claims will be unverified (hence the trust hierarchy). It assumes format will break (hence budget protection for retries).

The conservative defaults are telling: when uncertain, don't resolve. The protocol would rather surface ambiguity than force false clarity. This extends to the Blocked definition requiring precise thresholds—vague impasses aren't acceptable, but genuinely missing data is.

What's notably absent: any assumption that either LLM is "correct." The protocol produces structured disagreement as readily as agreement, and treats surfaced uncertainty as a valid output. That's probably the right call. Forced consensus between two unreliable reasoners isn't worth much.
