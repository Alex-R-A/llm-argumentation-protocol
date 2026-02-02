# Installation

## Prerequisites

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) installed (these skills run inside Claude Code)
- `jq` installed (`brew install jq` or `apt install jq`)
- At least one consultee CLI installed and authenticated:
  - [Codex CLI](https://github.com/openai/codex) for `codex-ask`
  - [Gemini CLI](https://github.com/google-gemini/gemini-cli) for `gemini-ask`

## Setup

Clone the repo and copy the skill folder(s) into your `~/.claude/skills` directory:

```bash
git clone https://github.com/Alex-R-A/llm-argumentation-protocol.git
mkdir -p ~/.claude/skills

# Install one or both:
cp -r llm-argumentation-protocol/codex-ask ~/.claude/skills/
cp -r llm-argumentation-protocol/gemini-ask ~/.claude/skills/
```

Start a new Claude Code session and invoke the skill with prompts like:

- "follow all rules in codex-ask skill and give me best options for ..."
- "follow all rules in gemini-ask skill and critique architecture of my ..."
- "follow all rules in codex-ask skill and find top 5 issues in my ..."
- "follow all rules in gemini-ask skill and review my code in ..."

The skill will have Claude consult the external LLM before making decisions, producing a decision log with what survived scrutiny, what got rejected, and what remains unresolved.
