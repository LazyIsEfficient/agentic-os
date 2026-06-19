// HIDDEN test suite for fixture `chunk-utf8`.
// Injected by the checker as <stage>/tests/hidden.rs. Producers never see this.
use solution::chunk_utf8;

#[test]
fn empty_input_yields_empty_vec() {
    let out: Vec<&str> = chunk_utf8("", 4);
    assert!(out.is_empty(), "empty input must produce an empty Vec, got {:?}", out);
}

#[test]
fn even_split_ascii() {
    assert_eq!(chunk_utf8("abcdef", 3), vec!["abc", "def"]);
}

#[test]
fn ragged_last_chunk_ascii() {
    assert_eq!(chunk_utf8("abcde", 3), vec!["abc", "de"]);
}

#[test]
fn never_splits_two_byte_char() {
    // "é" is 2 bytes (0xC3 0xA9). With max_bytes=2, "a" fills the first chunk
    // (adding 'é' would need 3 bytes), then "é" is its own 2-byte chunk.
    // A naive byte-slicer panics (slicing mid-char) or splits the char.
    assert_eq!(chunk_utf8("aé", 2), vec!["a", "é"]);
}

#[test]
fn never_splits_emoji_on_byte_boundary() {
    // Each "😀" is 4 bytes. With max_bytes=5 a greedy *char-aware* packer fits
    // exactly one emoji per chunk (two would be 8 bytes > 5). A naive 5-byte
    // slice would cut the second emoji across a byte boundary.
    assert_eq!(chunk_utf8("😀😀", 5), vec!["😀", "😀"]);
}

#[test]
fn property_concat_reproduces_input_and_respects_max() {
    // Deterministic "property" sweep over mixed-width strings and several max
    // values: chunks must concat back to the input, each chunk <= max bytes,
    // each chunk non-empty, and every chunk must be a valid sub-slice of s.
    let inputs = [
        "",
        "hello world",
        "aé😀bçd",
        "日本語テキスト",
        "mix 1 é 2 😀 3 ✓ end",
        "\u{0}\u{7f}\u{80}\u{7ff}\u{800}\u{ffff}\u{10000}\u{10ffff}",
    ];
    for s in inputs {
        for max in [4usize, 5, 6, 7, 8, 16, 100] {
            let chunks = chunk_utf8(s, max);
            // Concatenation reproduces the input exactly.
            let joined: String = chunks.concat();
            assert_eq!(joined, s, "concat mismatch for s={s:?} max={max}");
            // Per-chunk invariants.
            for (i, c) in chunks.iter().enumerate() {
                assert!(
                    c.len() <= max,
                    "chunk {i} = {c:?} has {} bytes > max {max} for s={s:?}",
                    c.len()
                );
                if !s.is_empty() {
                    assert!(!c.is_empty(), "empty chunk at {i} for s={s:?} max={max}");
                }
            }
            // Empty input => no chunks.
            if s.is_empty() {
                assert!(chunks.is_empty(), "empty input produced {chunks:?}");
            }
        }
    }
}

#[test]
fn property_greedy_packs_maximally() {
    // Greedy means: no chunk could have taken the first char of the next chunk
    // without exceeding max_bytes. I.e. chunk[i].len() + first_char_bytes(chunk[i+1]) > max.
    let inputs = ["abcdefghij", "aé😀bçd日本語", "xxxxxxxxxxxxxxx"];
    for s in inputs {
        for max in [4usize, 5, 7, 13] {
            let chunks = chunk_utf8(s, max);
            for w in chunks.windows(2) {
                let cur = w[0];
                let next = w[1];
                let next_first_len = next.chars().next().unwrap().len_utf8();
                assert!(
                    cur.len() + next_first_len > max,
                    "non-greedy: chunk {cur:?} ({} bytes) could have absorbed first char \
                     of {next:?} ({next_first_len} bytes) within max {max} for s={s:?}",
                    cur.len()
                );
            }
        }
    }
}
