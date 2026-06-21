# Performance & Invalidation

Performance in Swift/SwiftUI is mostly **structural**: it's decided by how the
view tree is factored, how narrow your dependencies are, and whether your `body`
and your loops do work proportional to what actually changed. Get the structure
right while writing — don't profile your way out of a bad shape later. But also
don't guess: when a tradeoff costs clarity, **measure first**.

## The mental model

Cost ≈ `body work` × `how often it re-evaluates` × `how much of the tree re-runs`.
You have a lever on each:

- **Shrink "how much of the tree re-runs"** → factor into subviews so unchanged
  subtrees are skipped. See `view-structure.md`.
- **Shrink "how often it re-evaluates"** → depend on the narrowest thing.
- **Shrink "body work"** → keep `body` a cheap description, nothing else.

## Narrow your dependencies

A view re-evaluates when something it *reads* changes. Read less, re-run less.

- With `@Observable` (iOS 17+), a view tracks only the **specific properties it
  touches** in `body`. Pass a sub-object or a single value into a subview instead
  of the whole model, so the subview only depends on what it shows.
- Don't read state you don't render. An unused `@Environment` read or an observed
  property you never display still subscribes you to its churn.
- Watch for **invalidation storms**: a single high-frequency source
  (`@AppStorage`, a `UserDefaults` observer, a wide environment value) wired into
  many views re-runs all of them. Fixing the one source often collapses dozens of
  downstream updates.

## Keep `body` cheap

`body` can run many times per second. It must be a *description*, never a
*computation*. Move work out:

- No allocation, sorting, filtering, date/number formatting, regex, or
  encoding/decoding in `body`. Compute it in the model, in `init`, or cache it;
  pass the result in.
- No network or disk I/O in `body`. Load in `.task`/`.onAppear` into state.
- Inline closures that capture create new identities each pass — fine in
  moderation, costly on a hot path.

```swift
// BAD — sorts every re-evaluation
var body: some View {
    List(items.sorted { $0.date > $1.date }) { ItemRow(item: $0) }
}
// GOOD — sort once where the data changes, render the prepared array
List(sortedItems) { ItemRow(item: $0) }   // sortedItems maintained in the model
```

## Identity & diffing

- `ForEach` needs **stable, unique identity** tied to the data, not its position.
  Never `\.self` on mutable values, never the array index / `.offset` — reordering
  or inserting then reuses the wrong view state and forces needless rebuilds.
- Make a frequently-diffed subview `Equatable` (or built only from plain stored
  values) so SwiftUI can cheaply prove "nothing changed, skip the body."
- **Large or unbounded scrolling content → a `List` or a `LazyVStack`/`LazyHStack`**
  inside a `ScrollView`, never a plain `VStack`/`HStack`: lazy stacks build rows
  only as they scroll into view, while an eager stack instantiates every child up
  front (jank + memory on long content).
- **Prefer `List` for long homogeneous rows**: it *recycles* off-screen cells, so
  memory stays flat regardless of scroll depth (and separators / swipe / selection
  come free). A `LazyVStack` only lazy-*builds* rows and keeps each one alive once
  scrolled past, so memory grows the further you scroll — reach for it when you need
  layout or styling `List` can't express.

## Animations

**Correctness.** A `.transition()` animates the insert/remove only when that change
is driven from a *stable ancestor* — a `withAnimation { … }` or an
`.animation(_:value:)` on a parent that stays mounted. Put the animation *inside*
the `if`/conditional being toggled and the exit silently won't animate: on removal
the view is already gone. Always pass `value:`; the bare global `.animation(_:)` is
deprecated and over-broad. A custom `Animatable` type animates only if
`animatableData` is actually wired to the changing value, otherwise it jumps.

**Hot paths.** A `.repeatForever` / `TimelineView` animation whose `@State` lives on an expensive
`body` (a chart, an N-card grid) re-evaluates that whole body every frame → CPU
pinned. **Isolate the animated element into its own subview that owns the state,
and add `.drawingGroup()`** — isolate it, never delete the visual. The animation
keeps running; only the tiny subview re-runs per frame.

## Algorithms & data structures

The framework can't save you from an `O(n²)` body or the wrong collection.

- **Pick the structure for the access pattern.** Membership / dedup / lookup →
  `Set` or `Dictionary` (`O(1)`), not `Array.contains` (`O(n)`) in a loop (that's
  `O(n²)`). Ordered with index access → `Array`. Frequent front insertion →
  rethink, `Array` prepend is `O(n)`.
- **Don't repeat linear scans.** Build an index/dictionary once, then look up.
- **Precompute outside the loop / outside `body`.** Hoist invariants.
- Use lazy (`.lazy`) for chained transforms you only partly consume; don't
  materialize giant intermediate arrays.
- Mind copy-on-write: mutating a `let`-shared large `Array`/`Dictionary` while it's
  referenced elsewhere triggers a full copy.

This is fundamentals, not cleverness — the right collection is usually *less* code
than the workaround for the wrong one.

## Measure, don't speculate

- `let _ = Self._printChanges()` (or `_logChanges()`) inside `body` prints **what
  invalidated this view** — the fastest way to find a re-render cause.
- For real hotspots, profile with Instruments (Time Profiler, SwiftUI lane, Hangs,
  Animation Hitches) rather than guessing.
- Optimize only what a measurement shows. A clear `O(n)` that never runs hot beats
  a clever `O(log n)` nobody can read.
