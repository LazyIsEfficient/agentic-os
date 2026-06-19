/// Greedily split `s` into consecutive char-boundary-safe chunks, each at most
/// `max_bytes` bytes. Concatenating the result reproduces `s` exactly.
pub fn chunk_utf8(s: &str, max_bytes: usize) -> Vec<&str> {
    let mut out = Vec::new();
    let mut start = 0usize; // byte index where the current chunk begins
    let mut last = 0usize; // byte index of the last char boundary <= start+max_bytes

    for (idx, ch) in s.char_indices() {
        // Would adding this char overflow the current chunk?
        if idx + ch.len_utf8() - start > max_bytes {
            // `last` is the end of the largest run of whole chars that fits.
            // Because max_bytes >= 4 >= any single char, `last > start` always
            // holds once we have consumed at least one char.
            out.push(&s[start..last]);
            start = last;
        }
        last = idx + ch.len_utf8();
    }

    if start < s.len() {
        out.push(&s[start..]);
    }
    out
}
