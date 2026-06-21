# View Structure

The single highest-leverage SwiftUI habit: **factor a view into separate `View`
types, not computed `var someView: some View` properties.** This is a performance
decision, not a style one. Here's why.

## Why factoring affects performance

SwiftUI keeps a persistent tree of view *values* and re-runs `body` only where
inputs changed. The unit of "did this change?" is a **`View` type's identity and
its stored inputs**.

- A **computed property** (`private var header: some View { ... }`) is just code
  spliced into the parent's `body`. It has no identity of its own. When the parent
  re-evaluates, the computed property re-evaluates with it — *always*. SwiftUI
  cannot skip it, because to SwiftUI it isn't a separate node; it's one big body.
- A **separate `View` struct** is a real node. When the parent re-evaluates,
  SwiftUI compares the child's inputs to last time. If they're unchanged — and the
  view is made of plain stored values (`POD`) or is `Equatable` — SwiftUI skips
  the child's `body` entirely. The subtree is pruned from the work.

So extracting a subview converts "re-run everything every time the parent
changes" into "re-run only the subviews whose inputs actually changed." On a
screen that updates often (a timer, live data, scroll), that's the difference
between a cheap diff and a pinned CPU.

Two more reasons extraction wins:

- **Type-checker speed.** Big bodies blow up Swift's expression solver
  ("the compiler is unable to type-check this expression in reasonable time").
  Smaller `View` structs compile fast.
- **Reuse and testability.** A named view with explicit inputs is reusable and
  trivial to preview in isolation.

```swift
// BAD — one body, nothing can be skipped, type-checker strains
struct Dashboard: View {
    @State private var tick = 0
    var body: some View {
        VStack {
            header            // re-runs every tick
            ForEach(rows) { RowContent(row: $0) }  // all of this re-runs too
            footer
        }
    }
    private var header: some View { /* heavy layout */ }
    private var footer: some View { /* heavy layout */ }
}

// GOOD — Header/Footer are nodes; when only `tick` changes, their bodies are skipped
struct Dashboard: View {
    @State private var tick = 0
    var body: some View {
        VStack {
            Header(title: title)
            ForEach(rows) { RowView(row: $0) }
            Footer(total: total)
        }
    }
}
struct Header: View { let title: String; var body: some View { /* ... */ } }
struct Footer: View { let total: Int; var body: some View { /* ... */ } }
```

## When to extract (and when not to)

Extract a subview when it:

- updates on a different cadence than its parent (the big one),
- is reused in more than one place,
- owns its own `@State`,
- is conditionally shown, or
- is large enough to strain the type-checker.

**Don't over-extract.** A one-line label used once does not need its own struct —
that's ceremony, not structure. Extract for identity, reuse, or compile health;
not dogmatically. The goal is less *total* code that the framework can diff
cheaply, not maximum file count.

## Composition rules that keep diffing cheap

- **Pass the minimum inputs.** A subview that takes `let title: String` can be
  skipped when `title` is unchanged. One that takes the whole model re-runs
  whenever any field of the model changes.
- **Avoid `AnyView`.** It erases the static type SwiftUI uses to diff, defeating
  the optimization and slowing things down. Reach for `@ViewBuilder`, a `Group`,
  or returning the concrete type instead.
- **Use `@ViewBuilder` for conditional content** rather than building `AnyView`
  branches by hand.
- Prefer **modifiers over wrapper conditionals**; prefer `overlay`/`background`
  over an extra `ZStack` when you just need layering.
- Keep `body` declarative — see `performance.md` for what must stay *out* of it.
