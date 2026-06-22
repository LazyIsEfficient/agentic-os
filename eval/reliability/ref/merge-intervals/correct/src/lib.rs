/// Merge inclusive integer intervals into the minimal disjoint set covering the
/// same points, sorted ascending by start. Input may be unsorted. Two intervals
/// merge iff they overlap or touch at an endpoint (`next.start <= cur.end`); a
/// pure gap (`next.start == cur.end + 1`) does NOT merge.
pub fn merge_intervals(intervals: &[(i64, i64)]) -> Vec<(i64, i64)> {
    if intervals.is_empty() {
        return Vec::new();
    }

    let mut sorted: Vec<(i64, i64)> = intervals.to_vec();
    sorted.sort_unstable();

    let mut out: Vec<(i64, i64)> = Vec::with_capacity(sorted.len());
    let mut cur = sorted[0];

    for &(a, b) in &sorted[1..] {
        if a <= cur.1 {
            // Overlap or shared endpoint: extend current interval.
            if b > cur.1 {
                cur.1 = b;
            }
        } else {
            // Pure gap (a > cur.1, including a == cur.1 + 1): flush and restart.
            out.push(cur);
            cur = (a, b);
        }
    }
    out.push(cur);
    out
}
