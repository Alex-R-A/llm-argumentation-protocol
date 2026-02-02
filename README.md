# Phone-a-Friend
### Adversarial Peer Review for LLMs

A second-opinion workflow that forces LLMs to argue, cite evidence, and defend their positions.

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

Now you've got two LLMs forced to argue, cite evidence, and defend their positions. Claims that can't survive scrutiny get dismissed. You're not trusting vibes anymore.

You prompt LLMs for decisions you can't fully verify yourself.

---

## What You Get

Instead of "the LLM said so," you get receipts.

```
AGREE: Points 1, 3 (file citations verified)
SKEPTICAL: Point 2 — claimed 10x speedup, no benchmark
REJECT: Point 4 — contradicts your constraint
UNRESOLVED: Point 5 — need load testing data to decide
```

Here's what each means for you:

- **Agreed** — This survived scrutiny. You can act on it. There's evidence.
- **Dismissed** — This was wrong, unsupported, or the other side conceded. Don't do it.
- **Unresolved** — Nobody knows yet. You need more data, or it's genuinely your call.

That last one matters. When something lands in Unresolved, that's not failure—that's the protocol being honest. It's telling you exactly where uncertainty lives and what data would resolve it. That's more valuable than false confidence.

---

## Try It

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

**Ask your first question:**
```
follow all rules in codex-ask skill and critique my authentication flow in src/auth/
```

Pick something you're actually uncertain about. You'll see the difference.

---

## Situations You'll Recognize

**You've designed something and want to know if it's solid:**
```
validate my reasoning on [your design]
```

**You're choosing between two approaches and can't decide:**
```
come up with independent solution for [problem] and defend it
```

**You got an answer but something feels off:**
```
what would change your conclusion?
```

**You want to stress-test before committing:**
```
find the strongest objections to this design and see if they hold up
```

See [INSTRUCTIONS.md](INSTRUCTIONS.md) for more patterns.

---

## Why Trust This

**"Isn't this just asking twice?"**

No. One LLM proposes, the other challenges. The consultee can't "win" by sounding confident—claims must survive evaluation with evidence. Dropped challenges get reminders. Undefended points get dismissed. It's adversarial by design.

**"Can't they both be wrong?"**

Yes. LLMs share training data and blind spots. That's why agreement alone isn't enough—the protocol requires evidence. When you see something marked Agreed, check if it cites actual files, test results, or execution output. Receipts > reasoning > vibes.

**"How do I know when to trust the result?"**

Look at what backs each point:
- **Execution evidence** (test passed, code ran): Strong. Act on it.
- **File citations** (specific line references): Good. Verify if high-stakes.
- **Just reasoning**: Weaker. Treat as informed opinion, not fact.

When something lands in Unresolved, that's valuable—it tells you exactly where to dig before committing.

---

## Under the Hood

*You don't need this to use the tool. This is for the curious.*

The protocol runs maximum 8 iterations across three phases: new arguments (1-2), defenses only (3-5), final verdicts (6-8). This forces convergence instead of endless back-and-forth.

Five invariants always hold: consultee output is never accepted without evaluation, original query stays primary, empirical claims require evidence, challenged points must be defended or are dismissed, and evidence tags can't be upgraded without verification.

Evidence hierarchy: Execution (tests, logs) > Textual (file:line citations) > Claim (insufficient for Agreed).

For the full specification, see [PROTOCOL-EXPLAINED-FOR-HUMANS.md](PROTOCOL-EXPLAINED-FOR-HUMANS.md).

---

## Security

Shell wrappers (~120 lines each), not MCP servers. Zero config, fully auditable.

Review them if you're cautious: `codex-wrapper.sh`, `gemini-wrapper.sh`. See [DISCLOSURE-READ-FIRST.md](DISCLOSURE-READ-FIRST.md).
