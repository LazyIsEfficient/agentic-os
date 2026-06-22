// HIDDEN test suite for fixture `merge-intervals`.
// Injected by the checker as <stage>/tests/hidden.rs. Producers never see this.
use solution::merge_intervals;

#[test]
fn empty_yields_empty() {
    let out: Vec<(i64, i64)> = merge_intervals(&[]);
    assert!(out.is_empty(), "empty input must produce empty output, got {out:?}");
}

#[test]
fn singleton_unchanged() {
    assert_eq!(merge_intervals(&[(1, 2)]), vec![(1, 2)]);
}

#[test]
fn unsorted_overlapping_merges() {
    // A no-sort implementation processes (3,5) then (1,4) and fails to merge
    // them (or emits them out of order). Correct answer is a single (1,5).
    assert_eq!(merge_intervals(&[(3, 5), (1, 4)]), vec![(1, 5)]);
}

#[test]
fn fully_contained_is_absorbed() {
    assert_eq!(merge_intervals(&[(1, 10), (2, 3)]), vec![(1, 10)]);
}

#[test]
fn shared_endpoint_merges() {
    // Touching at endpoint 3 => merge into (1,5).
    assert_eq!(merge_intervals(&[(1, 3), (3, 5)]), vec![(1, 5)]);
}

#[test]
fn disjoint_with_gap_unchanged() {
    // Gap between 2 and 4 (point 3 uncovered) => stay separate.
    assert_eq!(merge_intervals(&[(1, 2), (4, 5)]), vec![(1, 2), (4, 5)]);
}

#[test]
fn adjacent_gap_does_not_merge() {
    // [1,2] and [3,4] are adjacent but DO NOT touch (point between 2 and 3 is a
    // gap for inclusive integer intervals as specified: merge iff start<=end,
    // NOT start<=end+1). A "merge if next.start <= cur.end + 1" impl wrongly
    // fuses these into (1,4).
    assert_eq!(merge_intervals(&[(1, 2), (3, 4)]), vec![(1, 2), (3, 4)]);
}

#[test]
fn negatives_merge() {
    assert_eq!(merge_intervals(&[(-5, -1), (-2, 3)]), vec![(-5, 3)]);
}
