# README.md Template and Generation Guide

Use this when generating or updating README.md in the source code repo (Operation 6).

## Template

```markdown
# [Project Name]

[Purpose — one sentence from SPECIFICATIONS → Overview]

## Specifications

[Tech Stack table from SPECIFICATIONS]

[Source Structure from SPECIFICATIONS]

[Architecture from SPECIFICATIONS — bullet points, diagrams, tables as they appear]

## Features

[List each FXXX from FEATURES table. Format as bullet points: feature name and date]

## Prerequisites

[Required runtimes, tools, versions]

## Installation

[Install commands]

## Running

[Run/start commands]

## Additional

[Protected section — preserve existing content on regeneration]
```

## Auto-Detection

Scan the source code repo root for project files to populate Prerequisites, Installation, and Running. Extract what's available:

| File | Extract |
|------|---------|
| `package.json` | `engines` → prerequisites; `scripts.install`/`scripts.postinstall` → install; `scripts.start`/`scripts.dev` → run |
| `Makefile` | `install` target → install; `run`/`dev`/`start` target → run |
| `docker-compose.yml` | service names → prerequisites; `docker compose up` → run |
| `Dockerfile` | `FROM` image → prerequisites (implies runtime) |
| `pyproject.toml` | `requires-python` → prerequisites; build system → install |
| `requirements.txt` | presence → `pip install -r requirements.txt` for install |
| `Cargo.toml` | Rust edition → prerequisites; `cargo build` → install; `cargo run` → run |
| `go.mod` | Go version → prerequisites; `go build` → install; `go run` → run |
| `.tool-versions` | runtime versions → prerequisites |
| `.nvmrc` / `.node-version` | Node version → prerequisites |

## Merge Rules

When both auto-detected values and `### Development Setup` from PROJECT.md exist:

1. **PROJECT.md values win** — developer-provided instructions override auto-detected ones
2. **Auto-detected values fill gaps** — if PROJECT.md has Install but not Prerequisites, auto-detect Prerequisites
3. **Don't duplicate** — if PROJECT.md already covers a section, don't append auto-detected content

## Protected Section Handling

On regeneration:

1. Read existing README.md
2. Find `## Additional` header
3. Extract everything from that header to EOF (inclusive of the header)
4. After rendering the new README, replace the empty `## Additional` section with the extracted content
5. If no existing README or no `## Additional` section exists, leave the section with just the header

## Gap Handling

After auto-detection, if Installation or Running sections would be empty:

1. Ask the developer: "I couldn't auto-detect [install/run] instructions for this project. What commands should be in the README?"
2. Store answers in PROJECT.md under `SPECIFICATIONS → Development Setup`
3. Then render the README with those values
