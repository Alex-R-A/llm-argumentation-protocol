# Installation

## Prerequisites

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) installed (these skills run inside Claude Code)
- `jq` installed (`brew install jq` or `apt install jq`)
- At least one consultee installed and authenticated:
  - [Codex CLI](https://github.com/openai/codex) for `codex-ask`
  - [Gemini CLI](https://github.com/google-gemini/gemini-cli) for `gemini-ask`
  - [Moonshot API key](https://platform.moonshot.ai/console) for `kimi-ask`: `export MOONSHOT_API_KEY=your-key-here`

## Setup

Clone the repo and copy the skill folder(s) into your `~/.claude/skills` directory:

```bash
git clone https://github.com/Alex-R-A/llm-argumentation-protocol.git
mkdir -p ~/.claude/skills

# Install any combination:
cp -r llm-argumentation-protocol/codex-ask ~/.claude/skills/
cp -r llm-argumentation-protocol/gemini-ask ~/.claude/skills/
cp -r llm-argumentation-protocol/kimi-ask ~/.claude/skills/
```

Start a new Claude Code session and invoke the skill with prompts like:

- "follow all rules in codex-ask skill and give me best options for ..."
- "follow all rules in gemini-ask skill and critique architecture of my ..."
- "follow all rules in kimi-ask skill and evaluate whether my data model scales for ..."
- "follow all rules in codex-ask skill and find top 5 issues in my ..."
- "follow all rules in gemini-ask skill and review my code in ..."

**Why "follow all rules"?** This phrasing ensures the orchestrating LLM adheres to the full protocol rather than taking shortcuts it deems "more efficient." Without explicit instruction, LLMs may skip mandated steps (phase tracking, challenge mechanics, evidence gates) in favor of faster but less rigorous approaches.

**When you want the consultee to propose and defend:** If you want Codex or Gemini to generate an independent solution and defend it against Claude's challenges, use wording like:

- "follow all rules in codex-ask skill to ask codex to come up with an independent solution for X and defend it"
- "follow all rules in gemini-ask skill to have gemini propose an architecture for Y and defend it"
- "follow all rules in kimi-ask skill to have kimi propose an error handling strategy for Z and defend it"

The skill facilitates structured deliberation between Claude and the external LLM, with results categorized as agreed, dismissed, or unresolved.

## Round-Robin

`round-robin-ask` consults multiple LLMs serially rather than one-on-one. Install the skill alongside whichever consultees you have:

```bash
cp -r llm-argumentation-protocol/round-robin-ask ~/.claude/skills/
```

It uses all available models (Codex, Gemini, Kimi, Sonnet, Opus) but works with any subset. If some are unavailable, say which to skip:

```
follow all rules in round-robin-ask skill, skip Kimi and Codex, to explore architecture options for [your problem]
```
