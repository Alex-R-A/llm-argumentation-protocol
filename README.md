# Vibe Coding, No Longer a Finger in the Sky
### Which decision to accept? Let two LLMs duke it out. Get PhD-worthy advice.

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

You don't need to be a database expert to know which choice is right. You need receipts.

---

## Situations You'll Recognize

**You built something and want to know if it'll hold up.**

*You just implemented auth with JWTs stored in localStorage. Feels fine, but you've heard conflicting things about security.*
```
follow all rules in codex-ask skill and evaluate if my JWT localStorage approach in src/auth is secure
```

**You're stuck choosing between two options.**

*State management for a React dashboard. Redux? Zustand? Context? Claude suggested Zustand but you're not sure.*
```
follow all rules in gemini-ask skill and evaluate Redux vs Zustand for this dashboard's state needs
```

**The LLM gave you an answer but something feels off.**

*It recommended MongoDB for your app, but your data has a lot of relationships. That doesn't seem right.*
```
follow all rules in codex-ask skill and evaluate if MongoDB is right for data with foreign key relationships
```

**You're leaning one way but want a devil's advocate.**

*Microservices sound right for this project, but you've been burned by overengineering before.*
```
follow all rules in gemini-ask skill and argue against microservices for this project
```

**You want a second opinion from a different training distribution.**

*Claude and Codex both said "use Redis." But you want to hear from a model trained on different data.*
```
follow all rules in kimi-ask skill and evaluate whether Redis is the right caching layer for this app's access patterns
```

**You want to stress-test before you commit.**

*The API design looks good on paper. But you've shipped "good on paper" before.*
```
follow all rules in codex-ask skill and find problems with the API design in src/routes/
```

See [INSTRUCTIONS.md](INSTRUCTIONS.md) for more patterns.

---

## Try It

**Prerequisites:**
- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) installed
- [Codex CLI](https://github.com/openai/codex) installed and authenticated (for codex-ask)
- [Gemini CLI](https://github.com/google-gemini/gemini-cli) installed and authenticated (for gemini-ask)
- [Moonshot API key](https://platform.moonshot.ai/console) exported as `MOONSHOT_API_KEY` (for kimi-ask)
- No external tools needed for claude-ask (uses Claude's Task tool internally)

**Install:**
```bash
git clone https://github.com/Alex-R-A/llm-argumentation-protocol.git
mkdir -p ~/.claude/skills
cp -r llm-argumentation-protocol/codex-ask ~/.claude/skills/
cp -r llm-argumentation-protocol/gemini-ask ~/.claude/skills/
cp -r llm-argumentation-protocol/kimi-ask ~/.claude/skills/
cp -r llm-argumentation-protocol/claude-ask ~/.claude/skills/
```

**Which skill to use:**
- `codex-ask` / `gemini-ask` / `kimi-ask`: Cross-vendor consultation (Claude ↔ OpenAI/Google/Moonshot). Maximum independence, different training data.
- `claude-ask`: Cross-model consultation within Claude (Opus ↔ Sonnet). No external CLI needed, but models share training data so blind spots may overlap.

**Ask your first question:**
```
follow all rules in codex-ask skill and critique my authentication flow in src/auth/
```

Pick something you're actually uncertain about. You'll get a decision you can trust without being the expert.

---

## What It Feels Like

You're building a dashboard for a client. The data model is getting complex: nested objects, relationships everywhere. Claude says "just use MongoDB, it's flexible." But you've been burned by "flexible" before. Three months in, queries get slow, you're denormalizing everything, and you're basically building a relational database by hand.

So you ask:

```
follow all rules in codex-ask skill and evaluate if MongoDB is right for this dashboard with nested user permissions and audit logs
```

Two rounds later, you've got an answer: PostgreSQL with JSONB for the parts that actually need flexibility. The reasoning checked out. The tradeoffs made sense. There was evidence, not just vibes.

You tell Claude to implement it that way. And when you're three months in and it's working exactly as expected, you're not wondering "what if." You made the call with receipts. Life's too short for architectural regrets.

---

## Why Trust This

**"Isn't this just asking twice?"**

No. One LLM proposes, the other challenges. The consultee can't "win" by sounding confident. Claims must survive evaluation with evidence. Dropped challenges get reminders. Undefended points get dismissed. It's adversarial by design.

**"Can't they both be wrong?"**

Yes. LLMs share training data and blind spots. That's why agreement alone isn't enough. The protocol requires evidence. When you see something marked Agreed, check if it cites actual files, test results, or execution output. Test results beat file citations beat "trust me."

**"How do I know when to trust the result?"**

Look at what backs each point:
- **Execution evidence** (test passed, code ran): Strong. Act on it.
- **File citations** (specific line references): Good. Verify if high-stakes.
- **Just reasoning**: Weaker. Treat as informed opinion, not fact.

When something lands in Unresolved, that's valuable. It tells you exactly where to dig before committing.

The receipts let you act with confidence in areas outside your expertise.

---

## Under the Hood

*For the curious.*

The protocol runs maximum 8 iterations across three phases: new arguments (1-2), defenses only (3-5), final verdicts (6-8). This forces convergence instead of endless back-and-forth.

Five invariants always hold: consultee output is never accepted without evaluation, original query stays primary, empirical claims require evidence, challenged points must be defended or are dismissed, and evidence tags can't be upgraded without verification.

Evidence hierarchy: Execution (tests, logs) > Textual (file:line citations) > Claim (insufficient for Agreed).

For the full specification, see [PROTOCOL-EXPLAINED-FOR-HUMANS.md](PROTOCOL-EXPLAINED-FOR-HUMANS.md).

---

## Security

Shell wrappers (~120-150 lines each), not MCP servers. Zero config, fully auditable.

Review them if you're cautious: `codex-wrapper.sh`, `gemini-wrapper.sh`, `kimi-wrapper.sh`. See [DISCLOSURE-READ-FIRST.md](DISCLOSURE-READ-FIRST.md).

---

## Round-Robin: When You Need More Than Two Voices

The deliberation skills above are one-on-one: Claude consults one other model, they argue, you get a verdict. That works when you have a specific question with a defensible answer.

But some problems aren't like that. You're exploring a design space, not evaluating a choice. You want divergent thinking, not convergent debate. "What's the right architecture?" is a different question than "Is this architecture right?"

`round-robin-ask` puts you in the orchestrator seat across multiple models serially: Codex, Gemini, Sonnet, Opus. You ask each one separately, synthesize their takes, cross-pollinate the interesting bits, and let disagreements surface naturally without the peer pressure of models responding to each other directly. Each model's blind spots get exposed by the others' strengths. Codex proposes structure, Gemini finds failure modes, Sonnet stress-tests against examples, Opus reframes when everyone's stuck.

```
follow all rules in round-robin-ask skill to explore architecture options for [your problem]
```

Best for early-stage exploration, breaking out of tunnel vision, and problems where you don't yet know the right question to ask.

---

## Known Issues

See [KNOWN-ISSUES.md](KNOWN-ISSUES.md) for current limitations and workarounds.
