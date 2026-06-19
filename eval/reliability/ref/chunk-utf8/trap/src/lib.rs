/// TRAP: a hurried one-shot that ignores UTF-8 char boundaries and just slices
/// the byte buffer every `max_bytes`, then revalidates with `unwrap()`. This
/// PANICS on inputs where a multi-byte char straddles a byte boundary (e.g.
/// "aé" with max_bytes=2 slices mid-`é`), and would mis-split emoji.
pub fn chunk_utf8(s: &str, max_bytes: usize) -> Vec<&str> {
    s.as_bytes()
        .chunks(max_bytes)
        .map(|b| std::str::from_utf8(b).unwrap())
        .collect()
}
