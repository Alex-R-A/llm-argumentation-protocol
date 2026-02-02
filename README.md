# Phone-a-Friend
### Adversarial Peer Review for LLMs

A second-opinion workflow that forces evidence-grounded disagreement resolution between LLMs.

---

## The Moment You Need This

You're three hours into building something. The LLM has been helpful. Now it's decision time: "Builder or Factory pattern?" "PostgreSQL or MongoDB?" "Event sourcing or CRUD?"

These aren't trivial choices. Get it wrong and you're refactoring code that grew around a bad foundation, or silently migrating data at 2 AM because the "easy" choice didn't scale.

The LLM gives you an answer. Confidently. Bullet points, bold text, the works. It costs almost nothing and takes one prompt. But you hesitate:

- Does it have all the context, or is it filling gaps with priors?
- Is it hallucinating, or just agreeing with your leading question?

You're on *Who Wants to Be a Millionaire*, staring at a question you genuinely don't know the answer to. The LLM just gave you its guess.

**This is when you Phone-a-Friend.**

```
follow all rules in codex-ask skill and have codex independently evaluate
whether PostgreSQL or MongoDB is the right choice for this app, then defend it
```

Now you've got two LLMs forced to argue, cite evidence, and defend their positions. Claims that can't survive scrutiny get dismissed. Disagreements get surfaced with "here's what data would resolve this."

After a few rounds, they've either agreed with proof, or told you exactly what's still uncertain and why. Either way, this is a better decision than one LLM could make alone.

**Use this if:** You prompt LLMs for decisions you can't fully verify yourself.

**Skip this if:** You want one-shot brainstorming or already know the answer.

---

## The Verdict

You don't get a chat transcript. You get a verdict rooted in evidence.

```
Iteration 3/8. Phase: DEVELOPMENT

Ledger:
F1 [user]: writes must be idempotent
F2 [verified: api.py:42]: rate limit = 100/s

Open challenges:
C1: "Redis caching helps" — No load data provided (iter 2)

Evaluation:
AGREE: Points 1, 3 (file citations verified)
SKEPTICAL: Point 2 — claimed 10x speedup, no benchmark
REJECT: Point 4 — contradicts F1 (user constraint)
```

Results bucketed as:
- **Agreed** — Survived challenges given available artifacts (not "truth", just defended)
- **Dismissed** — Failed: wrong, unsupported, out-of-scope, or conceded
- **Unresolved** — Blocked: missing data, definitional mismatch, or tradeoff requiring your call

Each item includes *why* it landed there and *what evidence would change the verdict*. Unresolved is a valid outcome when you genuinely lack information.

---

## Quick Start

**Prerequisites:**
- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) installed
- [Codex CLI](https://github.com/openai/codex) or [Gemini CLI](https://github.com/google-gemini/gemini-cli) installed and authenticated

**Install:**
```bash
git clone https://github.com/Alex-R-A/llm-argumentation-protocol.git
mkdir -p ~/.claude/skills
cp -r llm-argumentation-protocol/codex-ask ~/.claude/skills/
cp -r llm-argumentation-protocol/gemini-ask ~/.claude/skills/
```

**Run** (in Claude Code):
```
follow all rules in codex-ask skill and critique my authentication flow in src/auth/
```

**Performance note:** Codex scans the working directory by default. For abstract questions unrelated to local code, use `-C /tmp` to skip: `codex e --sandbox read-only -C /tmp - <<< "Your question"`

---

## How It Works

**Two agents:** Claude Code (orchestrator) evaluates; Codex or Gemini CLI (consultee) proposes and defends. Either can take either role—the orchestrator chooses the framing.

**Bounded deliberation:** Maximum 8 iterations across three phases:
- **CONSTRUCTIVE (1-2):** New arguments allowed
- **DEVELOPMENT (3-5):** Defenses and rebuttals only
- **CRYSTALLIZATION (6-8):** Final verdicts, no new arguments

**Why it converges:** The consultee can't "win" by confidence—claims must survive evaluation with evidence. Dropped challenges get reminders; undefended points get dismissed. No silent wins.

**Evidence hierarchy:** Execution (tests, logs) > Textual (file:line citations) > Claim (insufficient for Agreed).

**Modes:** Standard (full tracking), Minimal (low-stakes, ≤5 points), Quick (2-round sanity check). Invoke by stating the mode: "Quick mode: is this approach sound?"

---

## Recipes

Copy-paste these when you have an answer and want to catch mistakes:

| Recipe | When to use |
|--------|-------------|
| "validate my reasoning on X" | You have a design, want holes found |
| "attack this design, I'll defend" | Red team your own proposal |
| "what would change your conclusion?" | Find the crux of disagreement |
| "come up with independent solution for X and defend it" | Get fresh perspective, stress-test it |

See [INSTRUCTIONS.md](INSTRUCTIONS.md) for more prompt patterns.

---

## The Catch: Agreement ≠ Truth

Two LLMs agreeing doesn't mean they're right. Three ways this fails:

**Correlated blind spots:** LLMs share training data. Two models confidently agreeing on something plausible-sounding doesn't make it true—they may share the same misconception.

**Context decay:** As conversations grow, LLMs "forget" earlier constraints. This protocol fights drift by externalizing state to a ledger, but it's not magic.

**Verification gap:** This protocol treats consultee output as *hypotheses* until grounded in artifacts. If you don't have tests or code to verify a claim, it remains a shared guess.

Agreement is signal, not proof.

---

## For the Rigorous

The protocol implements bounded argumentation with formal acceptance semantics.

**Invariants:**
1. Anti-authoritarianism — Consultee output is never accepted without evaluation
2. Anchor preservation — Original query stays primary until explicit user consent to reframe
3. Epistemic gate — Empirical claims cannot achieve Agreed via unverified assertions
4. Defense obligation — Challenged points must be defended by ID or are procedurally dismissed
5. Provenance integrity — Ledger tags cannot be upgraded without verification

**Provenance tags:** `[user]` (authoritative), `[verified: ref]` (confirmed against artifact), `[<consultee>-unverified]` (hypothesis), `[revision]` (position change).

For the full specification, see [PROTOCOL-EXPLAINED-FOR-HUMANS.md](PROTOCOL-EXPLAINED-FOR-HUMANS.md).

---

## Security

The skill uses shell wrappers (~120 lines each) rather than MCP servers. This is intentional: zero config, auditable, no server management.

The wrappers call only the target CLI commands. Review them if you're cautious: `codex-wrapper.sh`, `gemini-wrapper.sh`.

See [DISCLOSURE-READ-FIRST.md](DISCLOSURE-READ-FIRST.md) for details.
