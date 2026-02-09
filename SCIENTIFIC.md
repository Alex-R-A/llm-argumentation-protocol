# Argumentation Protocol: Technical Specification

A bounded multi-agent deliberation protocol implementing structured argumentation semantics for LLM-to-LLM consultation.

## Abstract

This protocol formalizes adversarial deliberation between a primary agent (orchestrator) and a secondary agent (consultee) under epistemic constraints. The system employs attack/defense mechanics inspired by abstract argumentation frameworks, with acceptance semantics that partition claims into terminal states. Deliberation proceeds through scope-restricted phases with bounded iteration, ensuring termination while preserving coverage of raised arguments.

## Motivation

Naive LLM consultation suffers from several failure modes:

1. **Epistemic inflation**: LLM-to-LLM agreement is weak evidence due to correlated training data. Mutual reinforcement can amplify unfounded claims.
2. **Authority confusion**: Treating consultee output as authoritative bypasses critical evaluation.
3. **Scope creep**: Unbounded deliberation drifts from the original query.
4. **Sycophantic collapse**: Under pushback, LLMs may capitulate rather than defend valid positions.
5. **Silent position drift**: Context decay causes unacknowledged contradictions across iterations.

This protocol addresses each through explicit mechanisms: epistemic gates, anti-authority invariants, phase restrictions, defense obligations, and position stability checks.

## Theoretical Foundations

The protocol draws from several formal traditions:

**Abstract Argumentation Theory.** Following Dung's seminal work on abstract argumentation frameworks (1995), arguments exist in attack relations. A claim under challenge must be defended or concedes defeat. The acceptance semantics (Agreed/Dismissed/Unresolved) partition the argument space, though the computation is procedural rather than fixpoint-based.

**Epistemic Constraints.** Empirical claims require verification against shared artifacts. The evidence hierarchy distinguishes execution traces (strongest), textual citations, and unverified assertions. Claims lacking grounding cannot achieve acceptance regardless of rhetorical force.

**Phased Scope Restriction.** Content introduction is progressively restricted: CONSTRUCTIVE admits new arguments; DEVELOPMENT permits extensions, defenses, and rebuttals; CRYSTALLIZATION allows only defenses to open challenges. This staged restriction forces convergence by eliminating late-stage scope expansion.

## Computational Model

The protocol assumes agents with the following architectural properties:

**Bounded context.** Agents process a finite token window. Content exceeding this bound is inaccessible. The protocol externalizes state to files rather than relying on agent memory, and repeats critical content (user question, ledger) in each prompt.

**Position-dependent attention.** Within the context window, attention weight on content decreases with distance from the current generation point. Early instructions receive diminishing consideration as context grows. The protocol counteracts this through explicit anchoring: verbatim repetition of the user question, numbered challenge IDs, and structured prompt formats that place critical information at predictable positions.

**Stochastic generation.** Agent outputs are non-deterministic. Identical inputs may produce different outputs across runs. The protocol does not assume reproducibility; it tracks positions explicitly and requires acknowledged revisions for any change.

**Behavioral mode selection.** Prompt structure activates different learned behavioral patterns. "What could be better?" invokes expansive brainstorming; "what breaks in actual use?" invokes grounded critique. The protocol specifies framings that induce critical analysis rather than agreeableness or theoretical exploration.

**Correlated priors.** Agents trained on overlapping data share systematic biases. Agreement between such agents provides weaker epistemic support than agreement between independent reasoners. The protocol treats convergence as signal, not proof, and requires artifact-grounded evidence for empirical claims.

These assumptions hold for current transformer-based LLMs. Protocols targeting agents with different architectures (persistent memory, deterministic outputs, independent training) may relax corresponding constraints.

## Non-goals

This protocol explicitly does not attempt:

1. **Computing Dung extensions**: The acceptance semantics are procedural, not fixpoint-based. Agreed/Dismissed/Unresolved partitions do not correspond to grounded, preferred, or stable extensions. The protocol prioritizes practical termination over semantic completeness.

2. **Replacing human judgment**: Unresolved outcomes surface genuine uncertainty for human decision. The protocol identifies where evidence is missing or criteria diverge; it does not force artificial consensus.

3. **Training or fine-tuning**: This is a runtime governance protocol, not a training signal. Unlike debate-as-training approaches, the goal is immediate decision quality, not model improvement.

4. **Guaranteeing correctness**: Two LLMs with correlated training cannot provide independent verification. The protocol reduces but cannot eliminate shared blind spots.

## Protocol Specification

### State Space

```
S = (L, C, B, φ, n, M)

L : Ledger       : Append-only fact base with provenance tags
C : Challenges   : Map of attack relations {id → (claim, objection, status)}
B : Buckets      : Partitioned acceptance states (Agreed | Dismissed | Unresolved)
φ : Phase        : Current protocol phase ∈ {CONSTRUCTIVE, DEVELOPMENT, CRYSTALLIZATION}
n : Iteration    : Current round ∈ [1, 8]
M : SSM          : Solution Space Map (shape, tangents, drift_signals)
```

**Solution Space Mapping (M)** establishes deliberation boundaries before engagement:
- **shape**: Characteristics valid responses must have
- **tangents**: Likely unproductive directions to detect
- **drift_signals**: Indicators deliberation has left productive territory

This enables distinguishing valuable unexpected insights from scope drift.

### Ledger Provenance

Each ledger entry carries a provenance tag determining its epistemic weight:

| Tag | Source | Weight |
|-----|--------|--------|
| `user` | User-provided constraint | Authoritative; cannot be superseded |
| `verified` | Confirmed against artifact | Strong; includes file:line reference |
| `<consultee>-unverified` | Consultee claim, unverified | Hypothesis only; cannot upgrade empirical claims |
| `orchestrator-unverified` | Orchestrator inference, unverified | Same constraints as consultee-unverified |
| `revision` | Position change | Requires explicit justification |

**Critical constraint:** `<consultee>-unverified` entries cannot: (a) justify upgrading empirical claims to Agreed, (b) supersede `user` or `verified` entries, (c) serve as arbitration constraints.

**Claim-level provenance.** Within individual responses, claims carry epistemic status markers:

| Marker | Meaning | Downstream effect |
|--------|---------|-------------------|
| `EVIDENCE` | Verifiable from shared artifacts | Can support empirical claims |
| `INFERENCE` | Derived from evidence | Requires validation of derivation |
| `GUESS` | Speculative, no grounding | Cannot support empirical claims |

These markers enable filtering: claims marked GUESS cannot justify upgrading disputed points to Agreed. The orchestrator may request re-labeling if markers appear miscalibrated.

### Phase Transition Function

```
φ(n, ext) = CONSTRUCTIVE     if n ≤ 2 + ext,  ext ∈ {0, 1, 2}
          | DEVELOPMENT      if 2 + ext < n ≤ 5 + ext
          | CRYSTALLIZATION  if n > 5 + ext
          where n ∈ [1, 8]
```

**Extension triggers** (evaluated at end of iter 2):
- **Coverage check (ext += 1):** Consultee response cites artifacts not previously referenced that contradict or gap existing conclusions
- **Stress test (ext += 1):** Early unanimous agreement under high-stakes/high-uncertainty conditions; steelman strongest objection

Extension borrows from DEVELOPMENT budget; total cap remains 8. When both trigger, coverage check runs first (constructive goal), then stress test (adversarial goal). The two goals are never combined in a single prompt.

### Phase Content Restrictions

Phase φ determines which content types may be introduced:

| Phase | Permitted | Prohibited | Violation routing |
|-------|-----------|------------|-------------------|
| CONSTRUCTIVE | New arguments, scenarios, positions | — | — |
| DEVELOPMENT | Extensions, defenses, rebuttals | New independent arguments | → NOT EVALUATED (tag: phase violation) |
| CRYSTALLIZATION | Defenses to open challenges only | New arguments, non-decisive evidence | → NOT EVALUATED (tag: phase closed) |

**Evidence exemption.** New evidence is always admissible regardless of phase, but its effect depends on whether it is decisive:

```
Decisive evidence test:
  Does evidence directly match or contradict the exact predicate in the claim?
    YES → decisive: updates bucket immediately regardless of phase
    NO  → non-decisive: requires interpretive reasoning

Phase-dependent routing for non-decisive evidence:
  CONSTRUCTIVE / DEVELOPMENT → evaluate normally
  CRYSTALLIZATION            → NOT EVALUATED (interpretation = new reasoning)
```

**Decisiveness heuristic:** "If you must explain *why* the evidence matters, it's not decisive." Example: "X never throws" + stack trace of X throwing = decisive. "Fast enough" + 10ms benchmark = non-decisive (requires threshold reasoning).

### Adversarial Safeguards

Two mechanisms guard against premature convergence, evaluated at end of iteration 2:

#### Coverage Check

**Trigger:** ≥1 dispute not yet addressed at end of iter 2.

**Prompt:** "What's missing from this analysis?"

**Extension condition:** Response cites artifacts not previously referenced in this deliberation AND (contradicts existing Agreed item OR reveals gap invalidating current conclusions).

```
Verification: Scan iter 1-2 transcripts for cited artifact.
  Found    → not new evidence, do not extend
  Not found → new evidence; apply ATTACK test:
    Contradicts existing item    → extend CONSTRUCTIVE (+1 iter)
    Generic addition ("also...")  → do not extend
```

#### Stress Test

**Trigger:** All points AGREE by end of iter 2 AND (high stakes ∨ high uncertainty ∨ unusually fast agreement).

**Prompt:** "Steelman the strongest objection to [conclusion]. Classify: (i) fatal flaw, (ii) open question, (iii) mitigable concern."

**Dual-Veto routing:** Consultee must specify impact set I ⊆ Agreed point IDs. If omitted, I defaults to all Agreed IDs.

```
Classification routing:
  Fatal ∨ Unresolved ∨ Inconclusive → I to Unresolved
  Mitigable (both parties agree + mitigation text) → rewrite affected points (tag: conditional)
  Refuted (orchestrator evidence + consultee confirms) → Agreed unchanged, objection Dismissed
```

**Bounded:** One objection + one response. Does not recurse. Neither party can unilaterally force acceptance; both must agree on mitigation or affected claims become Unresolved.

### Workflow

Execution proceeds through eight stages:

```
0. Invoke     : Gate check (explicit request, substantive question)
1. Ask        : Construct SSM (shape, tangents, drift_signals), then initial prompt with preamble, user question, ledger
2. Triage     : Classify points: in-scope → Evaluate, out-of-scope → Dismissed
3. Evaluate   : Assign: AGREE | SKEPTICAL | REJECT | ILL-FORMED
4. Critique   : Issue challenges for SKEPTICAL/REJECT points
5. Handle     : Route: revisions → Triage, defenses → evaluate quality
6. Iterate    : Check exit conditions; increment n if valid response
7. Synthesize : Verify bucket coverage, present results
8. Arbitrate  : (Optional) Secondary verification before output
```

Stage 0 is a pre-gate. Stages 2-6 repeat until termination. Format failures do not increment n.

### Classification Semantics

| Classification | Meaning | Action |
|----------------|---------|--------|
| **AGREE** | Claim accepted | → Agreed bucket |
| **SKEPTICAL** | Flaw identified, defense possible | Issue challenge, standard window |
| **REJECT** | Claim wrong, one chance to rebut | Issue challenge, single round |
| **ILL-FORMED** | Unevaluable (ambiguous, not a claim) | Request clarification; if unresolved after retry → Dismissed (tag: DIALECTICAL-STALL) |

### Acceptance Semantics

| Terminal State | Conditions |
|----------------|------------|
| **Agreed** | (Initial AGREE) ∨ (defense accepted ∧ evidence gate passed) |
| **Dismissed** | Concession ∨ undefended ∨ rejection with evidence ∨ out-of-scope |
| **Unresolved** | Blocked: missing data ∨ definitional mismatch ∨ criteria divergence |

**Evidence gate for empirical claims:** `evidence_type ∈ {execution, textual}` required. Value judgments bypass gate with `evidence_type = n/a`.

### Evidence Hierarchy

Strict ordering for empirical claim verification:

1. **Execution**: Runtime output, test results, compiler diagnostics (strongest)
2. **Textual**: Verbatim citations with path:line reference
3. **Claim**: Unverified assertion (insufficient for acceptance)

Only levels 1-2 satisfy the evidence gate. Claims at level 3 cannot achieve Agreed status for empirical assertions regardless of reasoning quality.

### Attack/Defense Mechanics

```
Challenge types:
  SKEPTICAL → defense window + reminder on first drop
  REJECT    → single defense round, terminal on failure

Defense evaluation:
  Referenced + valid   → status := defended, evaluate quality
  Unreferenced (1st)   → status := dropped, send reminder
  Unreferenced (2nd)   → status := undefended → Dismissed
  Explicit concession  → status := conceded → Dismissed
```

### Partial Defense Protocol

When a consultee concedes part of a challenged claim while defending the remainder:

```
Conceded portion → Dismissed (tag: PARTIAL-CONCEDE)
Defended portion → scope narrowing protocol:

  Orchestrator: "You now claim [narrowed scope]. Confirm or correct."

  Consultee confirms    → evaluate narrowed claim normally
  Consultee corrects    → accept correction (max 1), then evaluate
  2nd correction attempt → Dismissed (tag: DIALECTICAL-STALL: scope unstable)
```

**Rationale:** LLMs may articulate narrowed positions imprecisely. The confirmation round tests mutual understanding before adjudication. Unbounded corrections indicate fundamental ambiguity; one correction accommodates reasonable clarification while preventing indefinite scope shifting.

### Triage and Overflow Handling

**Triage routing.** Applied to every point from the consultee's response:

```
For each point P:
  in-scope            → canonicalize, then Evaluate
  out-of-scope        → Dismissed (tag: out-of-scope)
  anchor-shift        → test: serves anchor better, or shifts it?
    serves            → treat as in-scope
    shifts            → Unresolved (status: pending-anchor-shift; requires user consent per Invariant 2)
```

**Canonicalization.** Deduplicate claims when identical evidence would yield identical verdict. Test: would accepting/rejecting claim A require the same artifact examination as claim B? Same evidence → merge. Different evidence needed → keep separate even if superficially similar.

**Overflow handling (>7 points).** Without cardinality bounds, deliberation time grows as O(kn). For k > 7, the protocol applies themeing-based prioritization:

1. Group points into ≤5 themes
2. Identify blocking claims (would invalidate other work if true)
3. Deliberate blocking themes first
4. Rank remainder by anchor relevance until iteration budget exhausted
5. Overflow → NOT EVALUATED (with explicit warning if any overflow was blocking)

**Hard rule:** Undeliberated points never route to Agreed. Overflow points are marked NOT EVALUATED, preserving the distinction between "evaluated and accepted" and "never examined."

### Bias Calibration

*Note: These are invariant-level constraints that apply throughout execution, positioned here for proximity to the mechanics they constrain.*

The protocol includes mechanisms against evaluation bias:

**Calibration principle.** Apply identical skepticism to consultee proposals as to self-generated ideas. External origin is not evidence for or against validity.

**Position stability check.** Before finalizing any classification:
1. Have I taken a position on this point before?
2. Does current position contradict previous position?

Contradiction without explicit acknowledgment ("Revising from X to Y because...") is prohibited. Unacknowledged drift triggers ledger entry with `revision` tag.

*Implementation note:* Position history is tracked in the externalized state file, not agent memory. This sidesteps bounded context limitations by persisting positions to disk and re-loading relevant entries each iteration.

**Anti-sycophancy guard.** If consultee contradicts its earlier position without acknowledgment, challenge with citation: "Iteration 2 you claimed X, now you claim ¬X. Reconcile."

### Dependency Gate

Decision procedure for claims involving external dependencies (libraries, platforms, tools):

```
Input: Claim advocating dependency D
Test:  Name the granular operation that fails without D.

  Can name    → classify claim as CERTAIN or LIKELY; evaluate normally
  Cannot name → classify as GUESS

Tie-breaker:
  Both sides GUESS on operational behavior → fewer dependencies wins immediately

Defense filter:
  Generic defenses ("reliable", "standard", "best practice") without naming
  what breaks → keep challenging; do not concede
```

**Rationale:** "X is universal/standard" proves existence (textual evidence) but not reliability in a specific use case (requires execution evidence). Burden of proof rests with the party proposing dependencies: they must demonstrate concrete failure of simpler alternatives.

### Behavioral Induction

Prompt framing determines which learned behavioral patterns activate in the consultee. The protocol specifies framings that induce critical analysis:

| Desired mode | Framing | Avoid |
|--------------|---------|-------|
| Grounded critique | "What breaks in actual use?" | "What could be better?" |
| Minimal proposals | State design constraints upfront | Open-ended "improve this" |
| Evidence production | "Cite specific examples" | "Explain why" |
| Adversarial analysis | "Steelman the strongest objection" | "Any concerns?" |

Neutral question framing is encouraged: questions should not presuppose answers or lead toward conclusions the orchestrator already holds. If the orchestrator has a position, it should be stated as a position to be challenged, not as context framing the "correct" answer. (See Limitations for enforcement constraints.)

### Arbitration (Optional)

Before presenting output, invoke secondary verification:

**Triggers:** (a) 2+ unresolved items, (b) early unanimous lacking evidence, (c) high-stakes decision, (d) user request.

**Prompt:** Question + ledger + buckets. Agent names are omitted (no attribution), but bucket contents including point/reason pairs and challenge/defense exchanges are included for evaluation. "Are agreed points well-supported? Dismissals justified? Unresolved genuinely blocked?"

Flags reduce confidence only. ≥50% flagged → present with warning or re-examine.

## Termination Conditions

The protocol terminates under any of:

1. **Convergence**: No open challenges ∧ scope stable (no new points, disputed list unchanged)
2. **Iteration bound**: n = 8 reached
3. **Early exit (trivial)**: Question factual, resolved by iter 2
4. **Early exit (quality)**: Consultee unable to produce structured responses after retry

**Deadlock classification** (3+ defense rounds on same challenge, tracked via `defense_rounds` counter):
- Missing empirical data → route to Blocked, surface question to user
- Definitional mismatch → clarify terms, retry once
- Criteria divergence → surface tradeoff, let user choose

## Invariants

Properties that hold throughout execution:

1. **Anti-authoritarianism**: Consultee output is never accepted without evaluation
2. **Anchor preservation**: Original query remains primary until explicit user consent to reframe
3. **Epistemic gate**: Empirical claims cannot achieve Agreed via unverified assertions
4. **Defense obligation**: Challenged points must be defended by ID or are procedurally dismissed
5. **Provenance integrity**: Ledger tags cannot be upgraded without verification
6. **Role symmetry** *(editorial; implicit in spec, not listed as invariant)*: Protocol mechanics apply regardless of which agent proposes vs evaluates; framing determines adversarial stance, not evaluation rigor

## Complexity

| Measure | Bound | Notes |
|---------|-------|-------|
| Iterations | O(1) | Constant bound of 8 |
| Challenges | O(k) per iteration | k = points under dispute |
| State | O(\|L\| + \|C\| + \|M\|) | Ledger + challenges + SSM |
| Messages | 2n | Request/response pairs for n iterations |

## Implementation

Primary implementation: Claude Code (orchestrator) consulting Codex CLI or Gemini CLI (consultee). The protocol is LLM-agnostic and can be adapted to other agent pairings.

### State Persistence

State is externalized to prevent in-model drift. File is ground truth.

```json
{
  "version": 1,
  "session_id": "<consultee session ID>",
  "question_excerpt": "<first 100 chars>",
  "created_at": "<ISO timestamp>",
  "updated_at": "<ISO timestamp>",
  "iteration": 3,
  "phase": "DEVELOPMENT",
  "challenges": {
    "C1": {"point": "...", "objection": "...", "raised_iter": 1, "status": "defended", "defense_rounds": 1},
    "C2": {"point": "...", "objection": "...", "raised_iter": 2, "status": "open", "defense_rounds": 0}
  },
  "ledger": ["F1 [user]: ...", "F2 [verified: ref]: ..."],
  "disputed": ["C2"],
  "ssm": {
    "shape": "<valid response characteristics>",
    "tangents": "<unproductive directions>",
    "drift_signals": "<indicators of scope departure>"
  },
  "buckets": {
    "agreed": [{"point": "...", "evidence_type": "execution|textual|n/a", "reason": "..."}],
    "dismissed": [{"point": "...", "tag": "REJECTED|CONCEDED|UNDEFENDED", "reason": "..."}],
    "unresolved": [{"point": "...", "crux": "...", "status": "blocked|tradeoff|definitional"}]
  },
  "last_failure_type": "none"
}
```

**Modes:**

| Mode | Behavior |
|------|----------|
| Standard | Full protocol with state persistence |
| Minimal | Disables arbitration and stress testing; retains phases, ledger, challenge tracking. Extended CONSTRUCTIVE can only trigger via coverage check (trigger A), not stress test (trigger B). |
| Quick | 2-iteration max, stateless, no challenge IDs; for simple binary decisions |

## Limitations

**Correlation limitation.** LLMs trained on overlapping data are not independent evidence sources. Agreement between orchestrator and consultee provides weaker epistemic support than agreement between genuinely independent reasoners. The protocol mitigates this through evidence requirements but cannot eliminate shared blind spots or systematic errors present in training data.

**Evidence availability.** The evidence gate can force claims into Unresolved even when true, if supporting artifacts are inaccessible. This is a deliberate conservative bias: the protocol prefers acknowledged uncertainty over false confidence. Users must accept that some valid claims will remain unverified.

**Citation fragility.** Textual evidence depends on accurate file:line references and verbatim quotes. Consultees may hallucinate citations or quote selectively. The protocol requires orchestrator verification of citations before acceptance, but verification itself may miss subtle misrepresentations.

**Adversarial behavior.** The protocol assumes good-faith participation. A consultee could game the system through fabricated evidence references, strategic ambiguity, or sandbagging (deliberately weak initial positions to appear reasonable when "conceding"). No mechanism detects intentional deception.

**Task mismatch.** The adversarial structure may suppress creative exploration on open-ended tasks. Evidence requirements disadvantage novel ideas lacking prior artifacts. Quick and Minimal modes exist for less constrained deliberation, but users must judge when convergence pressure helps versus hinders.

**External validity.** Protocol behavior may vary across model families, temperature settings, context lengths, and tool availability. Results from one LLM pairing may not transfer to others.

**Neutral framing.** The requirement for neutral question framing (see Behavioral Induction) is aspirational. No mechanical test distinguishes neutral from leading questions; detection requires judgment. Orchestrators with strong priors may unconsciously frame questions to confirm existing beliefs. The protocol encourages but cannot enforce neutrality.

## Related Work

**Dialogue games and argumentation.** The challenge/defense mechanics draw from formal dialogue theory (Walton & Krabbe, 1995), where participants exchange moves under commitment rules. The phased structure resembles persuasion dialogues with explicit burden-of-proof shifts. Unlike classical dialogue games, this protocol operates between LLMs rather than humans, requiring additional safeguards against attention failures and position drift.

**Structured argumentation.** ASPIC+ (Modgil & Prakken, 2014) and assumption-based argumentation provide richer internal structure than Dung's abstract attacks. This protocol uses simpler attack relations for tractability but could extend to structured arguments if consultees reliably produced them.

**Belief revision.** The ledger's `revision` tag and position stability checks relate to AGM-style belief revision (Alchourrón, Gärdenfors & Makinson, 1985), which formalizes rational belief change under new information. The protocol enforces explicit justification for position changes, preventing unacknowledged drift.

**LLM debate.** Irving et al. (2018) proposed debate as a training signal for AI alignment. While sharing adversarial structure, that work focuses on model improvement through debate outcomes. This protocol is a runtime governance mechanism: it does not train models, but structures their interaction for immediate decision quality. The bounded rounds, evidence gates, and provenance tracking have no analogue in debate-as-training.

**Multi-agent deliberation.** The protocol relates to distributed AI systems where multiple agents must reach consensus (Olfati-Saber et al., 2007). The key difference is epistemic: LLM agents share training biases, so convergence mechanisms must account for correlated errors rather than assuming independent observations.

**LLM self-evaluation and constitutional constraints.** Bai et al. (2022) demonstrate that LLMs can critique and revise their own outputs using principle-based feedback (Constitutional AI). This protocol externalizes the critique to a separate agent and adds adversarial structure: rather than self-correction against static principles, the consultee's claims face active challenge with defense obligations and evidence gates. The constitutional approach assumes a trusted evaluator; this protocol assumes neither party is authoritative.

**Consistency through sampling.** Wang et al. (2023) show that sampling multiple reasoning paths and selecting the most consistent answer improves chain-of-thought reliability. This protocol pursues a related goal through structured adversarial exchange rather than statistical aggregation: instead of sampling and voting, it forces explicit defense of claims under challenge, surfacing disagreements that majority-vote methods would suppress.

**Debate as alignment mechanism.** Khan et al. (2024) provide empirical evidence that debate between LLMs improves truthfulness of answers, with more persuasive debaters yielding more accurate outcomes. Their findings support the core hypothesis of this protocol, that adversarial structure extracts better answers than single-agent consultation, while this protocol adds formal machinery (phased convergence, evidence hierarchy, provenance tracking) absent from their experimental setup.

**Computational argumentation mining.** Stab & Gurevych (2017) develop methods for parsing argumentation structures in natural text, identifying claims, premises, and support/attack relations. Their work on automatic argument structure recognition informs the classification semantics used here (AGREE/SKEPTICAL/REJECT/ILL-FORMED), though this protocol applies classifications procedurally during deliberation rather than extracting them post-hoc from completed texts.

## References

- Alchourrón, C.E., Gärdenfors, P., & Makinson, D. (1985). On the logic of theory change: Partial meet contraction and revision functions. *Journal of Symbolic Logic*, 50(2), 510-530.

- Bai, Y., Kadavath, S., Kundu, S., Askell, A., Kernion, J., Jones, A., ... & Kaplan, J. (2022). Constitutional AI: Harmlessness from AI feedback. *arXiv preprint arXiv:2212.08073*.

- Dung, P.M. (1995). On the acceptability of arguments and its fundamental role in nonmonotonic reasoning, logic programming and n-person games. *Artificial Intelligence*, 77(2), 321-357.

- Irving, G., Christiano, P., & Amodei, D. (2018). AI safety via debate. *arXiv preprint arXiv:1805.00899*.

- Khan, A., Hughes, J., Valentine, D., Ruis, L., Sachan, K., Radhakrishnan, A., Grefenstette, E., Bowman, S.R., Rocktäschel, T., & Perez, E. (2024). Debating with more persuasive LLMs leads to more truthful answers. *Proceedings of the 41st International Conference on Machine Learning (ICML)*, PMLR 235:23662-23733.

- Modgil, S., & Prakken, H. (2014). The ASPIC+ framework for structured argumentation: A tutorial. *Argument & Computation*, 5(1), 31-62.

- Olfati-Saber, R., Fax, J.A., & Murray, R.M. (2007). Consensus and cooperation in networked multi-agent systems. *Proceedings of the IEEE*, 95(1), 215-233.

- Stab, C., & Gurevych, I. (2017). Parsing argumentation structures in persuasive essays. *Computational Linguistics*, 43(3), 619-659.

- Walton, D.N., & Krabbe, E.C.W. (1995). *Commitment in Dialogue: Basic Concepts of Interpersonal Reasoning*. SUNY Press.

- Wang, X., Wei, J., Schuurmans, D., Le, Q., Chi, E., Narang, S., Chowdhery, A., & Zhou, D. (2023). Self-consistency improves chain of thought reasoning in language models. *Proceedings of the 11th International Conference on Learning Representations (ICLR)*.

For the human-readable protocol explanation, see [PROTOCOL-EXPLAINED-FOR-HUMANS.md](PROTOCOL-EXPLAINED-FOR-HUMANS.md).
