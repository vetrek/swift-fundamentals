# View Structure

The single highest-leverage SwiftUI habit: **factor a view into separate `View`
types, not computed `var someView: some View` properties and not `@ViewBuilder`
helper methods.** A `@ViewBuilder private func headerSection() -> some View` is
the same anti-pattern as a computed property wearing a different spelling — both
are inlined into the parent's `body` with no identity of their own. This is a
performance decision, not a style one. Here's why.

## Why factoring affects performance

SwiftUI keeps a persistent tree of view *values* and re-runs `body` only where
inputs changed. The unit of "did this change?" is a **`View` type's identity and
its stored inputs**.

- A **computed property** (`private var header: some View { ... }`) or a
  **`@ViewBuilder` helper method** (`private func header() -> some View`) is just
  code spliced into the parent's `body`. It has no identity of its own. When the
  parent re-evaluates, it re-evaluates with it — *always*. SwiftUI cannot skip it,
  because to SwiftUI it isn't a separate node; it's one big body.
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

## Writing a new multi-section view

When a prompt asks for a screen with distinct sections — header + content +
footer, hero + details + related, sidebar + main — the reflexive shape is a
single `View` with `private var header: some View` or `@ViewBuilder` section
funcs. **That shape is wrong; don't emit it in the first place.** Each named
section is its own `struct` conforming to `View` from the first draft, not a
refactor applied later.

- Not every section is a shared component. If it has one call site, declare it
  **`private struct` in the same file** as its parent. Promote to its own file
  only when a second call site appears.
- After extraction, small computed properties *inside* a leaf subview are fine —
  the invalidation boundary is already small. The anti-pattern is computed
  properties doing section-factoring in the parent.

## Composition rules that keep diffing cheap

- **Pass the minimum inputs — for value types.** A subview that takes
  `let title: String` can be skipped when `title` is unchanged. One that takes a
  whole value struct (or an `ObservableObject`) re-runs whenever any field
  changes. An `@Observable` reference is different: tracking is per property
  *read in `body`*, so passing the whole object keeps the dependency exactly as
  narrow as what the subview reads. Don't shred an `@Observable` model into
  a dozen `let`s for performance — and for action-only children, passing the
  object beats an injected closure (closures aren't comparable, so they defeat
  skipping; a reference is pointer-compared and stable).
- **Avoid `AnyView`.** It erases the static type SwiftUI uses to diff, defeating
  the optimization and slowing things down. Reach for `@ViewBuilder`, a `Group`,
  or returning the concrete type instead.
- **Use `@ViewBuilder` for conditional content** (if/else branches inside a
  `body`) rather than building `AnyView` branches by hand. This is *not* license
  for `@ViewBuilder` section helpers — see the top of this file.
- Prefer **modifiers over wrapper conditionals**; prefer `overlay`/`background`
  over an extra `ZStack` when you just need layering.
- **No single-child `Group`.** `Group { Text(status) }.padding()` wraps the view
  in an extra `Group<Text>` type that every chained modifier must type-check
  against, for zero behavioral benefit — chain modifiers on the child directly.
  `Group` around multiple siblings, a `ForEach`, or an `if`/`else` (to apply one
  modifier to all branches) is real work and fine.
- Keep `body` declarative — see `performance.md` for what must stay *out* of it.

## Keep view `init` cheap

A view's `init` runs **every time the parent's body re-evaluates** — many times
per second inside a `List`, lazy stack, scroll container, or animated parent.
It is not a one-time setup hook. Treat it as a constant-time copy of inputs
into stored properties: no decoding, no formatter allocation, no file system,
no large structures.

```swift
// BAD — decodes and allocates a formatter on every parent re-evaluation
init(rawJSON: Data, date: Date) {
    self.summary = try! JSONDecoder().decode(WeatherSummary.self, from: rawJSON)
    let formatter = DateFormatter(); formatter.dateStyle = .medium
    self.formattedDate = formatter.string(from: date)
}
// GOOD — take prepared values; decode in the model, format with Text(_:format:)
let summary: WeatherSummary
let date: Date   // body: Text(date, format: .dateTime.day().month().year())
```

Genuinely need compute-once-per-lifetime? Store it on a `@State`-owned
`@Observable` model or produce it in `.task` — those follow view *lifetime*,
`init` follows parent *body frequency*.
