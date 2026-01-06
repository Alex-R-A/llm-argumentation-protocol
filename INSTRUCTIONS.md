# Installation

## Prerequisites

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) installed (this skill runs inside Claude Code)
- [Codex CLI](https://github.com/openai/codex) installed and authenticated
- `jq` installed (`brew install jq` or `apt install jq`)

## Setup

Clone the repo and copy the `codex-ask` folder into your `~/.claude/skills` directory:

```bash
git clone https://github.com/Alex-R-A/llm-argumentation-protocol.git
mkdir -p ~/.claude/skills
cp -r llm-argumentation-protocol/codex-ask ~/.claude/skills/
```

Start a new Claude Code session and invoke the skill with prompts like:

- "use codex-ask skill to give me best options for ..."
- "use codex-ask skill to critique architecture of my ..."
- "use codex-ask skill to find top 5 issues in my ..."
- "use codex-ask skill to review my code in ..."

The skill will have Claude consult Codex before making decisions, producing a decision log with what survived scrutiny, what got rejected, and what remains unresolved.
