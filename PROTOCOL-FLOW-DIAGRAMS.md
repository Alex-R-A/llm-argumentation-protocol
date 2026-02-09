# Protocol Flow Diagrams

Companion visual reference to [PROTOCOL-EXPLAINED-FOR-HUMANS.md](PROTOCOL-EXPLAINED-FOR-HUMANS.md). ASCII flow diagrams showing the deliberation protocol's structure, from high-level workflow to specific mechanics.

Two sections: **Conceptual Overview** for general audience, **Technical Reference** for protocol designers.

---

## Conceptual Overview

How the deliberation works, what happens to claims, and how challenges resolve.

---

### Overall Deliberation Flow

What happens from user question to final output. Two loops drive iteration:
the main loop (Iterate → Critique) and the revision loop (Handle Response → Triage).

```
                        USER QUESTION
                             │
                             ▼
                  ┌────────────────────┐
                  │  Invocation Check  │──── fail ───→ EXIT
                  └──────────┬─────────┘
                             │ pass
                             ▼
                  ┌────────────────────┐
                  │ Solution Space Map │
                  └──────────┬─────────┘
                             │
                             ▼
                  ┌────────────────────┐
                  │      1. ASK        │───→ Consultee ───┐
                  └──────────┬─────────┘                  │
                             │◄────── response ───────────┘
                             ▼
              ┌─→ ┌────────────────────┐
              │   │     2. TRIAGE      │──→ out-of-scope ──→ DISMISSED
              │   └──────────┬─────────┘
              │              │ in-scope
              │              ▼
              │   ┌────────────────────┐
              │   │    3. EVALUATE     │──→ AGREE ───→ AGREED
              │   │  (bias & humility) │──→ REJECT ──→ DISMISSED
              │   └──────────┬─────────┘
              │              │ SKEPTICAL
              │              ▼
  ┌───────────┤   ┌────────────────────┐
  │           │   │    4. CRITIQUE     │───→ Consultee ───┐
  │           │   └──────────┬─────────┘                  │
  │           │              │◄────── response ───────────┘
  │           │              ▼
  │           │   ┌────────────────────┐
  │           │   │ 5. HANDLE RESPONSE │
  │           │   └──┬─────────────┬───┘
  │           │      │             │
  │           │ revisions       defenses
  │           │      │             │
  │           └──────┘        evaluate
  │          (→ Triage)            │
  │                                ▼
  │              ┌────────────────────┐
  │              │    6. ITERATE      │
  │              └──┬─────────────┬───┘
  │                 │             │
  │            unresolved       done
  │                 │             │
  └─────────────────┘             ▼
   (→ Critique)        ┌────────────────────┐
                       │   7. SYNTHESIZE    │
                       │  (exit validation) │
                       └──────────┬─────────┘
                                  │
                                  ▼
                       ┌────────────────────┐
                       │  8. ARBITRATION    │ (if triggered)
                       └──────────┬─────────┘
                                  │
                                  ▼
                               OUTPUT
                       ┌────────┼────────┐
                    AGREED  DISMISSED  UNRESOLVED
```

Not shown above (covered in later graphs): Coverage Check at iter 2 may extend CONSTRUCTIVE phase. Stress Test on early unanimity. ILL-FORMED handling and partial defense. Challenge/defense detail (SKEPTICAL vs REJECT). >7 points overflow. At N=8 with open disputes, remaining go to UNRESOLVED and skip to Synthesize.

---

### Two Debate Directions

The protocol runs in either direction. The framing determines who originates claims and who challenges them. Evaluation mechanics are identical both ways.

```
DIRECTION A: Claude proposes, Consultee challenges
"evaluate if my caching strategy is sound"

    CLAUDE                         CONSULTEE
  (proposer)                        (critic)
      │                                │
      │──── states position ──────────→│
      │                                │
      │◄─── challenges points ─────────│
      │                                │
      │   [evaluates challenges]       │
      │                                │
      │──── defends or concedes ──────→│
      │                                │
      │◄─── accepts / pushes back ─────│
      │             ...                │
      ▼                                ▼
                 Three Buckets


DIRECTION B: Consultee proposes, Claude challenges
"have Consultee propose a caching strategy and defend it"

    CLAUDE                         CONSULTEE
   (critic)                       (proposer)
      │                                │
      │──── "propose and defend" ─────→│
      │                                │
      │◄─── independent proposal ──────│
      │                                │
      │   [evaluates proposal]         │
      │                                │
      │──── challenges points ────────→│
      │                                │
      │◄─── defenses ─────────────────│
      │             ...                │
      ▼                                ▼
                 Three Buckets
```

Both directions use the same evaluation mechanics: same evidence gates, same challenge rules, same bias checks, same three buckets. The direction determines who originates claims, not how claims are judged.

Direction A validates your current path. Direction B surfaces paths you would not consider.

---

### Single Point's Journey to a Bucket

Every claim from the Consultee follows one of these paths from arrival to final placement.

```
                       CLAIM ARRIVES
                       (from Consultee)
                            │
                            ▼
                     ┌─────────────┐
                     │   TRIAGE    │
                     └──┬────┬──┬──┘
                        │    │  │
               in-scope │    │  │ anchor-shift
                        │    │  └────→ UNRESOLVED
                        │    │         (pending user consent
                        │    │          to shift question)
                        │    │ out-of-scope
                        │    └───→ DISMISSED (oos)
                        │
                        ▼
                 ┌─────────────┐
                 │  EVALUATE   │
                 └──┬──┬──┬──┬─┘
                    │  │  │  │
                AGREE  │  │  ILL-FORMED
                    │  │  │       │
                    ▼  │  │    clarify
                 AGREED│  │    ┌──┴──┐
                       │  │  fixed  still unclear
                       │  │    │       │
                       │  │    ▼       ▼
                       │  │  re-    DISMISSED
                       │  │  enter  (dialectical-stall)
                       │  │  Evaluate
                       │  │
                 SKEPTICAL REJECT
                       │    │
                       ▼    ▼
               CHALLENGE ISSUED
              (see Challenge graph
               for full cycle)
                       │
              ┌────────┼────────┐
              │        │        │
          defended   dropped   conceded
              │     or ignored     │
              │        │           ▼
              ▼        ▼       DISMISSED
         EVALUATE   DISMISSED  (conceded)
         DEFENSE   (undefended)
              │
         ┌────┴────┐
      accepted   rejected
         │           │
         ▼           ▼
      AGREED      stays disputed
                  (next iteration)
                       │
                  ┌────┴────┐
              resolves   stuck 3+ rounds
                  │           │
              AGREED or    UNRESOLVED
              DISMISSED    (blocked / tradeoff /
                            definitional)
```

Additional paths not in main diagram: partial defense splits a claim (conceded part → DISMISSED, defended part → re-evaluate at narrowed scope). Phase violation (new argument in DEVELOPMENT or CRYSTALLIZATION) → NOT EVALUATED. Overflow (>7 points) → NOT EVALUATED. REJECT challenges allow only 1 defense round, then terminal DISMISSED.

---

### Challenge / Defense Cycle

Two challenge types with different rules. SKEPTICAL gives multiple chances with a reminder window. REJECT is terminal after one defense round.

```
SKEPTICAL FLOW ("I'm not convinced")
═════════════════════════════════════

  challenge issued (with ID, e.g. C1)
               │
               ▼
     ┌───────────────────┐
     │ Consultee responds │
     │ to this challenge? │
     └────┬──────────┬────┘
          │          │
     addresses    silent on
     challenge    challenge
          │          │
          ▼          ▼
     status:      status:
     DEFENDED     DROPPED
          │          │
          │          ▼
          │     ┌─────────────────────────────────┐
          │     │ REMINDER                        │
          │     │ "C1 was not addressed.          │
          │     │  Defend or explicitly concede." │
          │     └──────────┬──────────────────────┘
          │                │
          │          ┌─────┴─────┐
          │       addresses    still silent
          │          │              │
          │          ▼              ▼
          │     status:         status:
          │     DEFENDED        UNDEFENDED
          │          │              │
          ▼          ▼              ▼
     ┌──────────────────┐     DISMISSED
     │ evaluate defense │     (UNDEFENDED tag)
     └────┬────────┬────┘
          │        │
     accepted    rejected
          │        │
          ▼        ▼
       AGREED    push back
                (stays disputed,
                 next iteration)


REJECT FLOW ("I believe this is wrong")
════════════════════════════════════════

  challenge issued
          │
          ▼
  ┌───────────────────┐
  │ Consultee responds │
  │ to this challenge? │
  └────┬──────────┬────┘
       │          │
    defends    no defense
       │          │
       ▼          ▼
  ┌──────────┐  DISMISSED
  │ evaluate │  (immediate, no
  │ defense  │   reminder window)
  └──┬────┬──┘
     │    │
  accepted rejected
     │       │
     ▼       ▼
  upgrade  DISMISSED
  to AGREE (terminal, no
  or       more rounds)
  SKEPTICAL
```

```
PARTIAL DEFENSE
═══════════════

  Consultee concedes part, defends rest
                │
                ▼
       ┌────────┴────────┐
       │                 │
  conceded part     defended part
       │                 │
       ▼                 ▼
  DISMISSED         Orchestrator restates
  (PARTIAL          narrowed claim:
   CONCEDE)         "You now claim [X].
                     Confirm or correct."
                         │
                    ┌────┴────┐
                confirms    corrects
                    │        (max 1 allowed)
                    ▼             │
               evaluate           ▼
               narrowed      use corrected,
               claim         then evaluate
                    │             │
               ┌────┴────┐       │
            sound      weak      │
               │        │        │
               ▼        ▼        │
            AGREED   stays       │
                    disputed     │
                                 │
                         2nd correction
                         attempted?
                              │
                              ▼
                         DISMISSED
                        (DIALECTICAL-STALL:
                         scope unstable)
```

```
KEY DIFFERENCES
═══════════════

  ┌──────────────┬─────────────────┬──────────────────┐
  │              │ SKEPTICAL       │ REJECT           │
  ├──────────────┼─────────────────┼──────────────────┤
  │ Meaning      │ "not convinced" │ "this is wrong"  │
  │ Reminder     │ yes (1 chance)  │ no               │
  │ Defense      │ multiple rounds │ 1 round only     │
  │ If dropped   │ remind → wait   │ dismiss          │
  │              │ → undefended    │ immediately      │
  │ Terminal?    │ no              │ yes (after       │
  │              │                 │  defense eval)   │
  └──────────────┴─────────────────┴──────────────────┘

Missing-ID note: if Consultee addresses a challenge substantively
but omits the ID (e.g. "Re C1"), that's a format issue, not a drop.
One recovery attempt: "Your response addresses C1 but doesn't
reference it. Confirm?" Still no ID after recovery → treat as dropped.
```

---

## Technical Reference

Phase mechanics, evaluation internals, evidence routing, and triage logic. For protocol designers and those reading the full specification.

---

### Phase Progression with Extension Triggers

Three phases constrain what content can be introduced. Extensions borrow from DEVELOPMENT budget; total cap stays at 8 iterations.

```
DEFAULT TIMELINE
════════════════

  iter:  1 ─── 2 ─── 3 ─── 4 ─── 5 ─── 6 ─── 7 ─── 8
         │           │                    │
    CONSTRUCTIVE     │    DEVELOPMENT     │  CRYSTALLIZATION
    new arguments    │    defenses only   │  final verdicts
    positions        │    rebuttals       │  open-challenge
    scenarios        │    extensions      │  defenses only


EXTENSION DECISION (end of iter 2)
══════════════════════════════════

                     End of iter 2
                          │
                     ┌────┴─────┐
                     │          │
              disputes       all AGREE
              remain?            │
                  │         ┌────┴────┐
                  │      high-stakes  normal
                  │      or suspect     │
                  │         │           │
                  ▼         ▼           ▼
            Coverage     Stress       proceed to
            Check        Test         DEVELOPMENT
            (Trigger A)  (Trigger B)
                  │         │
                  ▼         ▼
            asks        "Steelman the
            "What's     strongest
             missing?"  objection."
                  │         │
             ┌────┴────┐    │
          NEW        nothing│
         evidence    new    │
             │        │     │
             ▼        ▼     │
          extend    no      │
             │   extension  │
             │        │     │
             │        ▼     │
             │    DEVELOPMENT
             │              │
             └──────┬───────┘
                    │
               both triggered?
               ┌────┴────┐
              yes        no
               │          │
               ▼          ▼
           +2 iters    +1 iter
           Coverage    (borrows 1
           first,      from DEV)
           then Stress
           (borrows 2
            from DEV)

  Do not combine constructive and adversarial goals in one prompt.


WITH TRIGGER A (Coverage Check extends):

  iter:  1 ─── 2 ─── 3 ─── 4 ─── 5 ─── 6 ─── 7 ─── 8
         │                 │              │
    CONSTRUCTIVE (+1)      │  DEVELOPMENT │  CRYSTALLIZATION
                           │  (shortened) │

WITH BOTH TRIGGERS:

  iter:  1 ─── 2 ─── 3 ─── 4 ─── 5 ─── 6 ─── 7 ─── 8
         │                       │        │
    CONSTRUCTIVE (+2)            │  DEV   │  CRYSTALLIZATION
    coverage iter, then          │(short) │
    stress test iter             │        │
```

```
PHASE VIOLATIONS
════════════════

  Content arriving in wrong phase:

  ┌──────────────────┬──────────────────────────────────┐
  │ Phase            │ New argument arrives              │
  ├──────────────────┼──────────────────────────────────┤
  │ DEVELOPMENT      │ → NOT EVALUATED (phase violation) │
  │ CRYSTALLIZATION  │ → NOT EVALUATED (phase closed)    │
  └──────────────────┴──────────────────────────────────┘

  Exception: evidence is always phase-exempt (see Evidence graph).


COVERAGE CHECK: WHAT COUNTS AS "NEW"
═════════════════════════════════════

  Response to "What's missing?"
                │
                ▼
  ┌──────────────────────┐
  │ Cites artifacts not  │──── yes ──→ NEW EVIDENCE?
  │ previously referenced│              │
  │ in this deliberation?│         ┌────┴────┐
  └──────────┬───────────┘     contradicts  generic
             │ no              existing     addition
             ▼                 item?        ("consider
        not new,                │           also...")
        don't extend            ▼              │
             │              extend             ▼
             ▼           CONSTRUCTIVE      don't extend
        SYNTHESIZE
```

---

### Bias & Humility Evaluation Sequence

The five-step procedure applied to every in-scope point at step 3 (Evaluate). Gates prevent gut-feeling rejections and ungrounded agreements.

```
             POINT TO EVALUATE
                    │
                    ▼
  ┌──────────────────────────────┐
  │ 1. TENTATIVE CLASSIFICATION  │
  │    first-read assessment     │
  └──────────────┬───────────────┘
                 │
        ┌────────┼────────┐
        │        │        │
   SKEPTICAL   AGREE    ILL-FORMED
   or REJECT     │        │
        │        │     (clarify,
        ▼        │      not challenge)
  ┌──────────────────┐   │
  │ 2. ARTICULATION  │   │
  │    GATE          │   │
  │                  │   │
  │ State the flaw   │   │
  │ in one sentence. │   │
  │ "Seems wrong"    │   │
  │ = insufficient.  │   │
  └───────┬──────────┘   │
          │              │
     ┌────┴────┐         │
  can state  can't       │
  the flaw   state it    │
     │          │        │
     │          ▼        │
     │    don't challenge│
     │    → clarify      │
     │    instead        │
     ▼                   ▼
  ┌──────────────────────────────┐
  │ 3. REFINEMENT CHECKS         │
  │    (logic varies by type)    │
  └──────────────┬───────────────┘
                 │
    ┌────────────┼─────────────┐
    │            │             │
  REJECT     SKEPTICAL       AGREE
    │            │             │
  concrete    what's the    empirical
  flaw?       real issue?   or value
    │            │          judgment?
  ┌─┴──┐    ┌───┴────┐    ┌───┴────┐
 yes   no  flaw   no flaw empirical value
  │     │    │    + evidence  │       │
  ▼     ▼    ▼       │       │       ▼
 keep  →SKEP keep    ▼    have    AGREE
 REJECT      SKEP  →AGREE evidence? (n/a)
                          ┌──┴──┐
                        yes    no
                          │     │
                          ▼     ▼
                       AGREE  BLOCKED
                              (not Agreed)
                 │
                 ▼
  ┌──────────────────────────────┐
  │ 4. REFLECTIVE PROMPT         │
  │ "What viewpoint or evidence  │
  │  might contradict this?"     │
  └──────────────┬───────────────┘
                 │
                 ▼
  ┌──────────────────────────────┐
  │ 5. FINALIZE                  │
  │    Lock classification.      │
  │    Output reasoning.         │
  └──────────────────────────────┘


HARD GATES
══════════

  Empirical claim + evidence_type = "claim" → CANNOT AGREE
  Route to BLOCKED or UNRESOLVED instead.

  "I didn't find a problem" ≠ "no problem exists"
  Need positive evidence to upgrade, not just absence of noticed flaw.

  "Flaw: none" + SKEPTICAL/REJECT = contradiction.
  Either articulate the flaw or revise to AGREE.
```

```
DEPENDENCY GATE (conditional, for dependency-related claims)
════════════════════════════════════════════════════════════

  "Should we add library X?"
               │
               ▼
  ┌──────────────────────────┐
  │ Name the granular        │
  │ operation that fails     │
  │ without this dependency. │
  └────────────┬─────────────┘
               │
          ┌────┴────┐
       can name   can't name
          │           │
          ▼           ▼
     CERTAIN /      GUESS
     LIKELY
          │           │
          │      ┌────┴────┐
          │   one side   both sides
          │   has         GUESS
          │   evidence       │
          │      │           ▼
          │      ▼        fewer
          │   evaluate    dependencies
          │   normally    wins (tie-break)
          │
          ▼
     Generic defense
     ("reliable / standard /
      best practice") without
     naming what breaks?
          │
          ▼
     Keep challenging.
     Don't concede.
```

---

### Evidence Routing by Type and Phase

Evidence is phase-exempt: it can always be introduced. But its effect depends on type and on whether it's decisive.

```
EVIDENCE vs ARGUMENT
════════════════════

  Content presented in deliberation
                │
                ▼
  ┌──────────────────────────────┐
  │ "Can this be verified from   │
  │  shared artifacts without    │
  │  trusting the claimant?"     │
  └──────────────┬───────────────┘
                 │
            ┌────┴────┐
           YES        NO
            │          │
            ▼          ▼
        EVIDENCE    ARGUMENT
     (phase-exempt)  (subject to
            │        phase rules)
            │
  ┌─────────┼──────────┐
  │         │          │
  ▼         ▼          ▼
Execution Textual    Claim
 (tests,  (file:line ("I verified"
  output,  + verbatim  without proof)
  logs)    quote)        │
  │         │            │
  │         │         treat as
  │         │         UNVERIFIED
  ▼         ▼            │
 STRONGEST              ▼
  │                   WEAKEST
  │                      │
  │     can back         │    cannot back
  │     empirical AGREE  │    empirical AGREE
  │                      │
  ▼                      ▼
 empirical claims      route to
 can resolve           BLOCKED or
                       UNRESOLVED


EVIDENCE HIERARCHY
══════════════════

  Execution ──→ test result, compiler output, runtime behavior
      │
      │  stronger than
      ▼
  Textual ────→ file:line quote, spec citation with verbatim text
      │
      │  stronger than
      ▼
  Claim ──────→ "I verified" without proof (treat as unverified)

  Value judgments (simpler, cleaner, more maintainable) are outside
  this hierarchy. Require observable referents, not verification.
  Mark as evidence_type = n/a.
```

```
DECISIVE vs NON-DECISIVE (phase routing)
═════════════════════════════════════════

  New evidence arrives
          │
          ▼
  ┌────────────────────────┐
  │ Does it directly match │
  │ or contradict the      │
  │ EXACT predicate in     │
  │ the claim?             │
  └───────────┬────────────┘
              │
         ┌────┴────┐
        YES        NO
         │          │
         ▼          ▼
     DECISIVE    NON-DECISIVE
     (self-evident)  (needs interpretation)
         │          │
         │     ┌────┴──────────────┐
         │     │                   │
         │  CONSTRUCTIVE /      CRYSTALLIZATION
         │  DEVELOPMENT              │
         │     │                     ▼
         │     ▼                NOT EVALUATED
         │  evaluate
         │  normally
         │
         ▼
  Updates bucket IMMEDIATELY
  regardless of phase.

  ┌─────────────────────────────────────────────────┐
  │ Decisive test:                                  │
  │ "If you must explain WHY the evidence matters,  │
  │  it's not decisive."                            │
  │                                                 │
  │ Decisive:                                       │
  │   "X never throws" + stack trace of X throwing  │
  │   "returns int" + signature shows string        │
  │                                                 │
  │ Not decisive:                                   │
  │   "fast enough" + 10ms benchmark                │
  │   "cache helps" + 80% hit rate                  │
  └─────────────────────────────────────────────────┘
```

---

### Triage Decision Tree

Applied at step 2 to every point from the Consultee's response, and again when revisions re-enter the workflow from step 5.

```
TRIAGE ROUTING
══════════════

             POINTS FROM RESPONSE
                      │
                      ▼
           ┌────────────────────┐
           │  Tag each point:   │
           │  in-scope /        │
           │  out-of-scope /    │
           │  anchor-shift      │
           └──────────┬─────────┘
                      │
         ┌────────────┼─────────────┐
         │            │             │
     in-scope    out-of-scope   anchor-shift
         │            │          candidate
         │            ▼             │
         │       DISMISSED          ▼
         │       (oos)      ┌─────────────────┐
         │                  │ Serves anchor   │
         │                  │ better, or      │
         │                  │ shifts it?      │
         │                  └───┬─────────┬───┘
         │                  serves      shifts
         │                      │           │
         │                      ▼           ▼
         │                  treat as    UNRESOLVED
         │                  in-scope    (pending-anchor-shift;
         │◄─────────────────────┘        needs user consent
         │                               per Rule 2)
         ▼
  ┌─────────────────┐
  │  Canonicalize   │
  │  (deduplicate   │
  │   claims where  │
  │   same evidence │
  │   yields same   │
  │   verdict)      │
  └────────┬────────┘
           │
           ▼
  ┌─────────────────┐
  │  Count points   │
  └────┬────────┬───┘
       │        │
     ≤ 7      > 7
       │        │
       ▼        ▼
   EVALUATE   OVERFLOW
   all        HANDLING
   points         │
                  ▼


OVERFLOW HANDLING (> 7 points)
══════════════════════════════

              > 7 points
                  │
                  ▼
        ┌───────────────────┐
        │ 1. Group into     │
        │    ≤ 5 themes     │
        └────────┬──────────┘
                 │
                 ▼
        ┌───────────────────┐
        │ 2. Flag themes    │
        │    with BLOCKING  │
        │    claims (would  │
        │    invalidate     │
        │    other work     │
        │    if true)       │
        └────────┬──────────┘
                 │
                 ▼
        ┌───────────────────┐
        │ 3. Deliberate     │
        │    BLOCKING       │
        │    themes FIRST   │
        └────────┬──────────┘
                 │
                 ▼
        ┌───────────────────┐
        │ 4. Rank remainder │
        │    by relevance   │
        │    to anchor      │
        │    until budget   │
        │    exhausted      │
        └────────┬──────────┘
                 │
                 ▼
        ┌───────────────────┐
        │ 5. Overflow →     │
        │    NOT EVALUATED  │
        └────────┬──────────┘
                 │
            ┌────┴─────┐
            │          │
      non-blocking  blocking
       overflow     overflow
            │          │
            ▼          ▼
      NOT EVALUATED  NOT EVALUATED
                     + warning:
                     "undeliberated
                      blocking claims
                      exist"

  Hard rule: never route undeliberated points to AGREED.
```
