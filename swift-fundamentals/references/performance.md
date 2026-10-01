# Performance & Algorithms

SwiftUI mechanics — view factoring, `ForEach` identity, `@Observable` granularity,
environment churn — are covered by Apple's `swiftui-specialist` skill (see
"Apple's Xcode skills" in `SKILL.md`). This file holds what that skill doesn't:
the cost model, hot-path isolation, algorithm choice, and measuring.

## The mental model

Cost ≈ `body work` × `how often it re-evaluates` × `how much of the tree re-runs`.
Each factor is a separate lever — find which one is actually large before
changing anything.

## Keep work out of `body` and `init`

Both run every time the parent re-evaluates. They describe and copy inputs;
they never compute. No sorting, filtering, formatting, decoding, regex, or I/O.
Prepare data where it changes (the model, `.task`) and pass the result in. Use
`Text(_:format:)` for dates and numbers.

```swift
// BAD — sorts every re-evaluation
List(items.sorted { $0.date > $1.date }) { ItemRow(item: $0) }
// GOOD — sorted once where the data changes
List(sortedItems) { ItemRow(item: $0) }
```

## Hot-path animation: isolate, never delete

A `.repeatForever` / `TimelineView` animation whose `@State` lives on an expensive
`body` (a chart, an N-card grid) re-evaluates that whole body every frame → CPU
pinned. Move the animated element into its own subview that owns the state, and
add `.drawingGroup()` when it's render-heavy. The animation keeps running; only
the tiny subview re-runs per frame. Removing the visual is not a fix.

## Algorithms & data structures

The framework can't save you from an `O(n²)` body or the wrong collection.

- **Pick the structure for the access pattern.** Membership / dedup / lookup →
  `Set` or `Dictionary` (`O(1)`), not `Array.contains` (`O(n)`) in a loop (that's
  `O(n²)`). Ordered with index access → `Array`. Frequent front insertion →
  `Deque` (swift-collections) if already a dependency, else rethink.
- **Don't repeat linear scans.** Build an index once, then look up.
- **Hoist invariants** out of loops and out of `body`.
- Use `.lazy` for chained transforms you only partly consume; don't materialize
  giant intermediate arrays.
- Mind copy-on-write: mutating a large `Array`/`Dictionary` that's still
  referenced elsewhere copies all of it.

The right collection is usually *less* code than the workaround for the wrong one.

## Measure, don't speculate

- `let _ = Self._printChanges()` inside `body` prints what invalidated the view —
  the fastest way to find a re-render cause. Remove it before committing.
- For real hotspots, profile with Instruments (Time Profiler, SwiftUI, Hangs,
  Animation Hitches) instead of guessing.
- Optimize only what a measurement shows. A clear `O(n)` that never runs hot
  beats a clever `O(log n)` nobody can read.
