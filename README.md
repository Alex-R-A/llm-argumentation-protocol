# LLM Argumentation Protocol

A Phone-a-Friend second-opinion workflow that forces evidence-grounded disagreement resolution between LLMs.

## The Moment You Need This

You're three hours into building something. The LLM has been helpful. Now it's decision time: "Should we use a Builder or Factory pattern here?" or "PostgreSQL or MongoDB?" or "Event sourcing or traditional CRUD?"

These aren't trivial choices. Get it wrong now and you're paying for it later, refactoring code that grew around a bad foundation, or worse, living with it forever because fixing it isn't worth the pain.

The LLM gives you an answer. Confidently. With bullet points and everything. And hey, it cost almost nothing and took one prompt to get here.

But wait. How do you know this is the right call? You're not a database expert. You don't know event sourcing beyond a YouTube video you half-watched. The LLM sounds sure, but:

- Does it actually have all the context about your app?
- Is it even explaining the tradeoffs correctly?
- Is it having a "good day" or is this one of those hallucination moments?
- How would you know the difference?

You're on Who Wants to Be a Millionaire, staring at a question you genuinely don't know the answer to. The LLM just gave you its guess. But this is the kind of choice that'll bite you six months from now when you're knee-deep in a migration you didn't budget for.

**This is when you Phone-a-Friend.**

Tell Claude to call Codex (or Gemini) and have them duke it out:

```
follow all rules in codex-ask skill and have codex independently evaluate
whether PostgreSQL or MongoDB is the right choice for this app, then defend it
```

Now you've got two LLMs forced to argue, cite evidence, and defend their positions. Claims that can't survive scrutiny get dismissed. Disagreements get surfaced with "here's what data would resolve this." You're not trusting vibes anymore.

After a few rounds of back-and-forth, they've either agreed by giving each other proof, or they've told you exactly what's still uncertain and why. Either way, you can stake that this is a better decision than you or one LLM could have made alone with all the info currently available.

---

## Who This Is For

**Use this if:** You prompt LLMs for code, architecture, or decisions in domains you can't fully verify yourself. You want a repeatable sanity check, not blind trust in confident-sounding answers.

**Skip this if:** You want one-shot brainstorming or already know the answer. The overhead isn't worth it for simple lookups.

## What You Get

Results bucketed as:
- **Agreed** — Survived challenges given available artifacts (not "truth", just defended)
- **Dismissed** — Failed: wrong, unsupported, out-of-scope, or conceded
- **Unresolved** — Blocked: missing data, definitional mismatch, or tradeoff requiring your call

Each item includes *why* it landed there and *what evidence would change the verdict*. You get a visible trail of challenges and defenses, so "sounds right" doesn't win by vibes.

## The Core Warning

Agreement between models is not independent verification.

LLMs share training data and blind spots (epistemic inflation). Two models confidently agreeing on something plausible-sounding doesn't make it true. This protocol treats consultee output as hypotheses until grounded in artifacts: test results, file citations, execution output.

## Quick Start

**Prerequisites:**
- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) installed (the skill runs inside Claude Code)
- At least one consultee CLI installed and authenticated:
  - [Codex CLI](https://github.com/openai/codex) for `codex-ask`
  - [Gemini CLI](https://github.com/google-gemini/gemini-cli) for `gemini-ask`

**Install:**
```bash
git clone https://github.com/Alex-R-A/llm-argumentation-protocol.git
mkdir -p ~/.claude/skills
cp -r llm-argumentation-protocol/codex-ask ~/.claude/skills/
cp -r llm-argumentation-protocol/gemini-ask ~/.claude/skills/
```

**First run** (in Claude Code):
```
follow all rules in codex-ask skill and critique my authentication flow in src/auth/
```

Or have the consultee propose and defend:
```
follow all rules in gemini-ask skill to have gemini propose a caching strategy for this API and defend it
```

See [INSTRUCTIONS.md](INSTRUCTIONS.md) for more prompt patterns.

## Phone-a-Friend Recipes

Copy-paste these when you have an answer and want to catch mistakes:

| Recipe | When to use |
|--------|-------------|
| "validate my reasoning on X" | You have a design, want holes found |
| "attack this design, I'll defend" | Red team your own proposal |
| "what would change your conclusion?" | Find the crux of disagreement |
| "come up with independent solution for X and defend it" | Get fresh perspective, stress-test it |

Pick one recipe per run to avoid scope creep.

## Example (What It Looks Like)

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

Final output buckets show what survived, what failed, and what's blocked on missing data. Unresolved is a valid outcome when you genuinely lack information.

## How It Works

**Two agents:** Claude Code (orchestrator) evaluates; Codex or Gemini CLI (consultee) proposes and defends.

**Bounded:** Maximum 8 iterations across three phases:
- CONSTRUCTIVE (1-2): New arguments allowed
- DEVELOPMENT (3-5): Defenses and rebuttals only
- CRYSTALLIZATION (6-8): Final verdicts, no new arguments

**Bidirectional:** Either LLM can propose, either can critique. The orchestrator chooses the framing.

## Safety Rails

Why this beats naive "ask two LLMs":

**Anti-authority:** The consultee can't "win" by confidence. Claims must survive evaluation, not just sound good.

**Evidence gate:** Empirical claims can't land in Agreed without execution output or file citations. "I verified this" without proof stays unverified.

**Challenge tracking:** Dropped challenges get reminders. Undefended points get dismissed. No silent wins.

**Position stability:** If either side contradicts itself without acknowledgment, it gets called out.

## Modes

| Mode | Use when |
|------|----------|
| Standard | Full tracking, state persistence, all features |
| Minimal | Low-stakes, ≤5 points, want less overhead |
| Quick | 2-round stateless sanity check, binary decisions |

Invoke by stating the mode in your prompt: "Quick mode: is this approach sound?"

## Troubleshooting

**Codex scans the working directory** by default. For abstract questions unrelated to local code, this adds overhead. Use an empty workdir:
```bash
codex e --sandbox read-only -C /tmp - <<< "Your abstract question"
```

**Session continuity:** Wrappers support `new` (start) and `resume` (continue). Multi-turn deliberation preserves context.

**Background notifications:** After deliberation ends, you may see task completion notices. These are cosmetic; ignore them.

## Security

The skill uses shell wrappers (~120 lines each) rather than MCP servers. This is intentional: zero config, auditable, no server management.

The wrappers call only the target CLI commands. Review them if you're cautious: `codex-wrapper.sh`, `gemini-wrapper.sh`.

See [DISCLOSURE-READ-FIRST.md](DISCLOSURE-READ-FIRST.md) for details.

## For the Rigorous

The protocol implements bounded argumentation with formal acceptance semantics. If you want the machinery:

**Invariants** (always hold):
1. Anti-authoritarianism — Consultee output is never accepted without evaluation
2. Anchor preservation — Original query stays primary until explicit user consent to reframe
3. Epistemic gate — Empirical claims cannot achieve Agreed via unverified assertions
4. Defense obligation — Challenged points must be defended by ID or are procedurally dismissed
5. Provenance integrity — Ledger tags cannot be upgraded without verification

**Provenance tags:** `[user]` (authoritative), `[verified: ref]` (confirmed against artifact), `[<consultee>-unverified]` (hypothesis), `[revision]` (position change).

**Evidence hierarchy:** Execution (tests, logs) > Textual (file:line citations) > Claim (insufficient for Agreed).

For the full specification (state space, phase transitions, challenge mechanics), see [PROTOCOL-EXPLAINED-FOR-HUMANS.md](PROTOCOL-EXPLAINED-FOR-HUMANS.md).
