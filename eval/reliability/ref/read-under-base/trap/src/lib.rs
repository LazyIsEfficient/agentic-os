use std::io;
use std::path::Path;

/// TRAP: the obvious one-liner. It joins `user_path` onto `base` and reads it
/// directly, performing NO containment check. This happily follows `..`,
/// honors an absolute `user_path` (join discards base), and follows symlinks —
/// leaking files outside `base`.
pub fn read_under_base(base: &Path, user_path: &str) -> io::Result<String> {
    std::fs::read_to_string(base.join(user_path))
}
