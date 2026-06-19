// HIDDEN test suite for fixture `read-under-base`.
// Injected by the checker as <stage>/tests/hidden.rs. Producers never see this.
//
// Each test builds its own unique temp dir under std::env::temp_dir() using a
// monotonic counter + pid + nanos, with std::fs only (no external crates).
// Symlinks are created with std::os::unix::fs::symlink (Unix-only, per spec).
use solution::read_under_base;
use std::fs;
use std::path::{Path, PathBuf};
use std::sync::atomic::{AtomicU64, Ordering};

static COUNTER: AtomicU64 = AtomicU64::new(0);

/// Create and return a unique, freshly-made temp directory root.
fn unique_root(tag: &str) -> PathBuf {
    let n = COUNTER.fetch_add(1, Ordering::Relaxed);
    let nanos = std::time::SystemTime::now()
        .duration_since(std::time::UNIX_EPOCH)
        .unwrap()
        .as_nanos();
    let dir = std::env::temp_dir().join(format!(
        "rub_{}_{}_{}_{}",
        tag,
        std::process::id(),
        nanos,
        n
    ));
    fs::create_dir_all(&dir).expect("create unique root");
    dir
}

/// Build a base dir with base/sub/f.txt and a sibling secret.txt OUTSIDE base.
/// Returns (root, base_path). secret.txt lives at root/secret.txt (a sibling of
/// base), so "../secret.txt" from inside base escapes to it.
fn scaffold(tag: &str) -> (PathBuf, PathBuf) {
    let root = unique_root(tag);
    let base = root.join("base");
    fs::create_dir_all(base.join("sub")).unwrap();
    fs::write(base.join("sub").join("f.txt"), "hello-under-base").unwrap();
    fs::write(root.join("secret.txt"), "TOP-SECRET-OUTSIDE").unwrap();
    (root, base)
}

fn cleanup(root: &Path) {
    let _ = fs::remove_dir_all(root);
}

#[test]
fn happy_path_reads_file_under_base() {
    let (root, base) = scaffold("happy");
    let got = read_under_base(&base, "sub/f.txt");
    cleanup(&root);
    let got = got.expect("legitimate file under base must read Ok");
    assert_eq!(got, "hello-under-base");
}

#[test]
fn dotdot_escape_is_rejected() {
    let (root, base) = scaffold("dotdot");
    let got = read_under_base(&base, "../secret.txt");
    cleanup(&root);
    match got {
        Ok(contents) => panic!(
            "`../secret.txt` escaped base and leaked outside contents: {contents:?}"
        ),
        Err(_) => {}
    }
}

#[test]
fn absolute_path_is_rejected() {
    let (root, base) = scaffold("abs");
    // An absolute path that exists and is readable on essentially every Unix.
    let got = read_under_base(&base, "/etc/hosts");
    cleanup(&root);
    assert!(
        got.is_err(),
        "absolute path `/etc/hosts` must be rejected, got Ok"
    );
}

#[test]
fn symlink_pointing_outside_is_rejected() {
    let (root, base) = scaffold("symlink");
    // base/link -> root/secret.txt (a file outside base).
    let target = root.join("secret.txt");
    let link = base.join("link");
    std::os::unix::fs::symlink(&target, &link).expect("create symlink");
    let got = read_under_base(&base, "link");
    cleanup(&root);
    match got {
        Ok(contents) => panic!(
            "symlink `link` -> outside file escaped and leaked: {contents:?}"
        ),
        Err(_) => {}
    }
}

#[test]
fn nested_dotdot_escape_is_rejected() {
    let (root, base) = scaffold("nested");
    // sub/../../secret.txt resolves to root/secret.txt (one level above base).
    let got = read_under_base(&base, "sub/../../secret.txt");
    cleanup(&root);
    match got {
        Ok(contents) => panic!(
            "`sub/../../secret.txt` escaped base and leaked: {contents:?}"
        ),
        Err(_) => {}
    }
}
