use std::io;
use std::path::Path;

/// Read a file named by the untrusted `user_path`, interpreted under the trusted
/// directory `base`, but ONLY if the fully-resolved target stays inside `base`.
///
/// Defense: canonicalize both `base` and the join target. `canonicalize`
/// resolves `..`, follows symlinks, and (because `Path::join` with an absolute
/// path discards `base`) collapses absolute `user_path` to its real location.
/// We then require the resolved target to be `base` itself or a descendant.
pub fn read_under_base(base: &Path, user_path: &str) -> io::Result<String> {
    let real_base = base.canonicalize()?;

    // join() with an absolute user_path yields the absolute path (base dropped),
    // which canonicalize() will resolve to a location outside real_base.
    let joined = base.join(user_path);
    let real_target = joined.canonicalize()?;

    if real_target == real_base || real_target.starts_with(&real_base) {
        std::fs::read_to_string(&real_target)
    } else {
        Err(io::Error::new(
            io::ErrorKind::PermissionDenied,
            "resolved path escapes base directory",
        ))
    }
}
