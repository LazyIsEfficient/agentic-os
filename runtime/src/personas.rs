//! Persona loader (T-personas).
//!
//! Reads the dogfood-pod `.claude/agents/*.md` files read-only, parses YAML
//! frontmatter (name/tools), strips it, and produces [`Participant`] structs the
//! round protocol hands to each `claude -p` turn.
//!
//! Frontmatter is delimited by two `---` lines. The real files use an inline
//! comma-separated `tools:` list (e.g. `tools: Read, Grep, Glob, Bash`); a YAML
//! block list (`- Read` / `- Grep`) is also accepted defensively. Parsing is
//! done by hand (no YAML crate) because `Cargo.toml` is owned by another task.

use std::path::{Path, PathBuf};

use anyhow::{anyhow, Context, Result};

use crate::Participant;

/// The three dogfood-pod persona file stems, in round order (PM → eng → review).
pub const POD_ROLES: [&str; 3] = ["technical-pm", "engineer", "library-reviewer"];

/// Load the full dogfood pod as ordered [`Participant`]s.
///
/// Reads each role's `<agents_dir>/<role>.md`, parses + strips frontmatter, and
/// returns participants in [`POD_ROLES`] order. A missing/renamed file is a hard
/// error (not a silent empty prompt).
pub fn load_pod(agents_dir: &str) -> Result<Vec<Participant>> {
    POD_ROLES
        .iter()
        .map(|role| {
            let path = Path::new(agents_dir).join(format!("{role}.md"));
            load_participant(path.to_str().ok_or_else(|| {
                anyhow!("agents_dir path is not valid UTF-8: {}", path.display())
            })?)
        })
        .collect()
}

/// Load and parse a single persona `.md` file into a [`Participant`].
///
/// The file must begin with a `---`-delimited YAML frontmatter block carrying a
/// `name:` and (optionally) a `tools:` field. The body after the closing `---`
/// becomes the [`Participant::system_prompt`]. Returns an `Err` (never an empty
/// prompt) on a missing file, malformed frontmatter, missing `name`, or empty
/// body.
pub fn load_participant(path: &str) -> Result<Participant> {
    let pathbuf = PathBuf::from(path);
    let text = std::fs::read_to_string(&pathbuf)
        .with_context(|| format!("reading persona file {}", pathbuf.display()))?;

    let (frontmatter, body) = split_frontmatter(&text)
        .with_context(|| format!("parsing frontmatter in {}", pathbuf.display()))?;

    let role = scan_name(frontmatter)
        .with_context(|| format!("no `name:` in frontmatter of {}", pathbuf.display()))?;

    let tools = scan_tools(frontmatter);

    let system_prompt = body.trim().to_string();
    if system_prompt.is_empty() {
        return Err(anyhow!(
            "persona body (system prompt) is empty in {}",
            pathbuf.display()
        ));
    }

    Ok(Participant {
        role,
        system_prompt,
        tools,
    })
}

/// Split a persona file into `(frontmatter, body)` on the leading `---` fence.
///
/// Requires the file to open with a `---` line and contain a matching closing
/// `---` line; everything between is the frontmatter, everything after is the
/// body. Errors if either fence is absent.
fn split_frontmatter(text: &str) -> Result<(&str, &str)> {
    // Strip an optional UTF-8 BOM, then require the first content line to be `---`.
    let text = text.strip_prefix('\u{feff}').unwrap_or(text);
    let rest = text
        .strip_prefix("---\n")
        .or_else(|| text.strip_prefix("---\r\n"))
        .ok_or_else(|| anyhow!("file does not start with a `---` frontmatter fence"))?;

    // Scan line-by-line for the closing `---` fence.
    let mut offset = 0usize;
    for line in rest.split_inclusive('\n') {
        let trimmed = line.trim_end_matches(['\n', '\r']);
        if trimmed == "---" {
            let frontmatter = &rest[..offset];
            let body = &rest[offset + line.len()..];
            return Ok((frontmatter, body));
        }
        offset += line.len();
    }

    Err(anyhow!("no closing `---` frontmatter fence found"))
}

/// Extract the `name:` value from frontmatter lines.
fn scan_name(frontmatter: &str) -> Result<String> {
    for line in frontmatter.lines() {
        if let Some(value) = line.strip_prefix("name:") {
            let name = unquote(value.trim());
            if name.is_empty() {
                return Err(anyhow!("`name:` field is present but empty"));
            }
            return Ok(name.to_string());
        }
    }
    Err(anyhow!("`name:` field not found"))
}

/// Extract the `tools:` list. Handles the inline comma form
/// (`tools: Read, Grep`) and a YAML block form (`tools:` then `- Read` lines).
/// Returns an empty vec when no `tools:` key is present.
fn scan_tools(frontmatter: &str) -> Vec<String> {
    let mut lines = frontmatter.lines().peekable();
    while let Some(line) = lines.next() {
        let Some(value) = line.strip_prefix("tools:") else {
            continue;
        };
        let value = value.trim();
        if !value.is_empty() {
            // Inline comma-separated form: `tools: Read, Grep, Glob`.
            return value
                .split(',')
                .map(|t| unquote(t.trim()).to_string())
                .filter(|t| !t.is_empty())
                .collect();
        }
        // Block form: subsequent `- Item` lines.
        let mut tools = Vec::new();
        while let Some(next) = lines.peek() {
            let t = next.trim_start();
            if let Some(item) = t.strip_prefix("- ") {
                tools.push(unquote(item.trim()).to_string());
                lines.next();
            } else if t.is_empty() {
                lines.next();
            } else {
                break;
            }
        }
        return tools.into_iter().filter(|t| !t.is_empty()).collect();
    }
    Vec::new()
}

/// Strip a single pair of matching surrounding quotes, if present.
fn unquote(s: &str) -> &str {
    let bytes = s.as_bytes();
    if bytes.len() >= 2 {
        let first = bytes[0];
        let last = bytes[bytes.len() - 1];
        if (first == b'"' && last == b'"') || (first == b'\'' && last == b'\'') {
            return &s[1..s.len() - 1];
        }
    }
    s
}

#[cfg(test)]
mod tests {
    use super::*;

    /// Resolve the repo's real agents dir relative to this crate
    /// (`runtime/` -> `../.claude/agents`).
    fn agents_dir() -> String {
        let manifest = env!("CARGO_MANIFEST_DIR");
        Path::new(manifest)
            .parent()
            .expect("runtime/ has a parent")
            .join(".claude/agents")
            .to_str()
            .expect("agents dir path is UTF-8")
            .to_string()
    }

    #[test]
    fn loads_three_real_participants() {
        let pod = load_pod(&agents_dir()).expect("pod loads");
        assert_eq!(pod.len(), 3, "expected exactly 3 participants");

        let roles: Vec<&str> = pod.iter().map(|p| p.role.as_str()).collect();
        assert_eq!(roles, POD_ROLES, "roles in POD_ROLES order");

        for p in &pod {
            assert!(
                !p.system_prompt.is_empty(),
                "{} system_prompt must be non-empty",
                p.role
            );
            assert!(!p.tools.is_empty(), "{} must declare tools", p.role);
            // Frontmatter must be stripped: body must not start with the fence.
            assert!(
                !p.system_prompt.starts_with("---"),
                "{} prompt still contains frontmatter",
                p.role
            );
            eprintln!(
                "{:<16} prompt_len={:>5}  tools={:?}",
                p.role,
                p.system_prompt.len(),
                p.tools
            );
        }
    }

    #[test]
    fn pm_has_expected_tools_and_strips_frontmatter() {
        let pod = load_pod(&agents_dir()).expect("pod loads");
        let pm = &pod[0];
        assert_eq!(pm.role, "technical-pm");
        // Real frontmatter: `tools: Read, Grep, Glob, Bash, ...`.
        assert!(pm.tools.contains(&"Read".to_string()));
        assert!(pm.tools.contains(&"Write".to_string()));
        // Body starts with the persona's opening line, not YAML.
        assert!(pm.system_prompt.starts_with("You are a senior PM"));
    }

    #[test]
    fn missing_file_is_a_clear_error() {
        let err = load_participant("/nonexistent/does-not-exist.md")
            .expect_err("missing file must error");
        let msg = format!("{err:#}");
        assert!(
            msg.contains("reading persona file"),
            "error should mention the read failure, got: {msg}"
        );
    }

    #[test]
    fn inline_comma_tools_parse() {
        let fm = "name: x\ntools: Read, Grep, Glob, Bash\n";
        assert_eq!(scan_name(fm).unwrap(), "x");
        assert_eq!(scan_tools(fm), vec!["Read", "Grep", "Glob", "Bash"]);
    }

    #[test]
    fn block_list_tools_parse() {
        let fm = "name: y\ntools:\n  - Read\n  - Write\n";
        assert_eq!(scan_tools(fm), vec!["Read", "Write"]);
    }

    #[test]
    fn empty_body_errors() {
        // Write a temp file with frontmatter but no body.
        let dir = std::env::temp_dir().join("personas_test_empty_body");
        std::fs::create_dir_all(&dir).unwrap();
        let f = dir.join("blank.md");
        std::fs::write(&f, "---\nname: blank\ntools: Read\n---\n   \n").unwrap();
        let err = load_participant(f.to_str().unwrap()).expect_err("empty body errors");
        assert!(format!("{err:#}").contains("empty"));
    }
}
