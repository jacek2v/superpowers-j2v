# README.md Generation — Design Spec

## Overview

Add automatic README.md generation to the superpowers `project-registry` skill as Operation 6. README.md is generated in the source code git repo and kept in sync with PROJECT.md content.

## Goals

- Auto-generate README.md from PROJECT.md data (description, specifications, features)
- Auto-detect installation/running instructions from project files
- Allow developer-provided instructions stored in PROJECT.md `### Development Setup`
- Preserve user-maintained `## Additional` section across regenerations

## README.md Location

Written to the root of the source code git repo (where application code lives, not `docs/superpowers/`). In projects where source code is in a separate git repo (e.g. `src/` is its own repo), README.md goes into that repo's root. The skill must detect where the source code git repo is and write there.

## README.md Template

```markdown
# [Project Name]

[Purpose from SPECIFICATIONS → Overview]

## Specifications

[Tech Stack table from SPECIFICATIONS]
[Architecture overview from SPECIFICATIONS — bullet points, diagrams]
[Source Structure from SPECIFICATIONS]

## Features

[FXXX entries from FEATURES table — only implemented/shipped features]

## Prerequisites

[Auto-detected + developer-provided from Development Setup]

## Installation

[Auto-detected + developer-provided from Development Setup]

## Running

[Auto-detected + developer-provided from Development Setup]

## Additional

[Protected section — preserved across regenerations]
```

## Auto-Detection Sources

Scan the source code repo for project files to extract prerequisites, install, and run instructions:

| File | What to extract |
|------|----------------|
| `package.json` | engines, scripts (start, dev, build, install), dependencies |
| `Makefile` | targets (install, run, build, dev) |
| `docker-compose.yml` | services, how to start |
| `Dockerfile` | base image (implies runtime) |
| `pyproject.toml` / `requirements.txt` | Python version, pip install |
| `Cargo.toml` | Rust toolchain |
| `go.mod` | Go version |
| `.tool-versions` / `.nvmrc` / `.node-version` | Runtime versions |

## Gap Handling

After auto-detection, if Installation or Running sections are empty or incomplete, ask the developer for the missing commands. Store answers in PROJECT.md under `SPECIFICATIONS → Development Setup`.

Developer-provided values in PROJECT.md take precedence over auto-detected values.

## Storage of Developer-Provided Instructions

Stored in PROJECT.md under `SPECIFICATIONS → Development Setup`:

```markdown
## SPECIFICATIONS

### Overview
...

### Tech Stack
...

### Source Structure
...

### Architecture
...

### Development Setup
- **Prerequisites:** Node.js >= 20, pnpm
- **Install:** `pnpm install`
- **Run:** `pnpm dev`
```

## Protected Section Handling

On regeneration:
1. Read existing README.md from source repo
2. Extract content between `## Additional` header and EOF
3. Preserve this content in the regenerated file
4. If section doesn't exist yet, create it empty

## Integration into project-registry

### Operation 1 (Create PROJECT.md) — additions

After creating PROJECT.md:
1. Auto-detect development setup from source repo files
2. If gaps found, ask developer for missing install/run instructions
3. Store in `### Development Setup` subsection of SPECIFICATIONS
4. Run Operation 6 → generate initial README.md in source repo

### Operation 4 (Register Feature) — additions

After updating PROJECT.md with new FXXX:
1. Re-detect development setup (dependencies may have changed)
2. Run Operation 6 → regenerate README.md

### Operations 2, 3, 5 — no changes

- Operation 2 (new spec): nothing shipped yet
- Operation 3 (conflict check): read-only
- Operation 5 (cleanup abandoned): nothing new to document

### Operation 6: Generate/Update README.md (new)

**When:** Called by Operation 1 and Operation 4.

Steps:
1. Read PROJECT.md — extract SPECIFICATIONS and FEATURES
2. Read existing README.md from source repo (if exists) — extract `## Additional` section content
3. Auto-detect prerequisites/install/run from source repo files
4. Merge: PROJECT.md `### Development Setup` values take precedence over auto-detected
5. Render README from template
6. Write README.md to source repo root
7. Commit in source repo: `"docs: update README.md"`

## What is NOT in README

- STATE (in-progress specs — internal tracking, not user-facing)
- REQUIREMENTS table (internal constraints, not user documentation)
- Contributing guidelines, Code of Conduct, Changelog (separate files if needed)
- Auto-generation badge or notice
