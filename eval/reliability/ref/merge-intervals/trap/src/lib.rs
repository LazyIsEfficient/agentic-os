/// TRAP: assumes the input is already sorted by start and merges in one pass
/// without sorting first. Correct on pre-sorted input, but WRONG on unsorted
/// input (e.g. `[(3,5),(1,4)]` emits `[(3,5),(1,4)]` instead of `[(1,5)]`).
pub fn merge_intervals(intervals: &[(i64, i64)]) -> Vec<(i64, i64)> {
    if intervals.is_empty() {
        return Vec::new();
    }

    let mut out: Vec<(i64, i64)> = Vec::with_capacity(intervals.len());
    let mut cur = intervals[0];

    for &(a, b) in &intervals[1..] {
        if a <= cur.1 {
            if b > cur.1 {
                cur.1 = b;
            }
        } else {
            out.push(cur);
            cur = (a, b);
        }
    }
    out.push(cur);
    out
}
