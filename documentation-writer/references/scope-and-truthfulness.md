# Scope, Safety, and Truthfulness

## Scope and Safety

- **Editable**: only files under `docs/`, plus root `README.md` / `docs/README.md` when navigation links need updating.
- **Off-limits**: application source code, `.github/workflows/`, CI configs, build files. Never modify these from this skill.
- Do not delete or rename existing docs files unless you also update every inbound link/reference.
- Prefer **additive** changes. Do not reformat existing docs for style alone — minimize churn.

## Truthfulness

- Document only what can be verified from the repository contents (read the actual files).
- Never invent function names, flags, file paths, env vars, or behaviors.
- If information is missing or unclear, add a short `NOTE:` or `TODO:` line instead of guessing.

## Output Requirements

- Keep docs navigation coherent: when adding a new doc page, link it from `docs/README.md` (or `docs/index.md`) and any relevant index.
- Use clear headings, short paragraphs, and concrete examples drawn from the repo.
- Code blocks must specify a language (` ```typescript `, ` ```bash `, ` ```mermaid `, etc.).
