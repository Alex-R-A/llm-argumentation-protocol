# Disclosure: Shell Script Usage

These skills invoke external LLM CLIs (Codex, Gemini) via bash wrapper scripts rather than through MCP (Model Context Protocol) servers.

## Why Shell Scripts?

MCP would require users to configure and run additional servers for each consultee LLM. Shell scripts provide a turnkey solution: install the CLI, install the skill, done. No server configuration, no port management, no additional processes to maintain.

Bash is the natural choice for CLI-to-CLI integration. The wrappers handle session management, argument passing, and response extraction in ~100 lines of portable shell code.

## Security Considerations

The wrapper scripts execute only the specific CLI commands needed for deliberation (`codex`, `gemini`). They do not execute arbitrary code, do not process untrusted input as commands, and do not modify system state beyond the CLIs' own behavior.

The scripts are readable and auditable. Review them before use if you have concerns: `codex-wrapper.sh`, `gemini-wrapper.sh`.

## Trade-offs

| Approach | Pros | Cons |
|----------|------|------|
| Shell wrappers | Zero config, portable, auditable | Requires CLI auth, text parsing |
| MCP servers | Structured protocol, reusable | Setup overhead, server management |

For a skill meant to be installed and used immediately, shell wrappers are the pragmatic choice.
