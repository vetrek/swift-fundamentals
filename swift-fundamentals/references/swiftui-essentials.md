# SwiftUI Essentials (fallback)

Read this only when Apple's `swiftui-specialist` skill is not available. If it is,
use it instead — it covers all of this in more depth.

## Factor views into `View` types

Split a screen's sections into separate `struct`s conforming to `View`, not
`private var header: some View` or `@ViewBuilder func header()`. A computed
property or builder helper is spliced into the parent's `body` and re-runs every
time the parent does. A separate `View` is a real node: when its inputs are
unchanged, SwiftUI skips its `body`. It also keeps the type-checker fast.

- One call site → `private struct` in the same file. Promote when a second
  caller appears.
- Don't over-extract: a one-line label used once doesn't need a struct.
- Avoid `AnyView`; no single-child `Group`.

## Pick the wrapper by ownership

| You need | Use |
|----------|-----|
| View owns a value | `@State private var` |
| View owns a reference object | `@State` + `@Observable` class (`@StateObject` pre-iOS 17) |
| Child writes the parent's value | `@Binding` |
| Injected observable needing `$` bindings | `@Bindable` (`@ObservedObject` pre-iOS 17) |
| Read-only passed-in data | plain `let` |

A passed-in value declared `@State` / `@StateObject` initializes once and ignores
every later update from the parent — the most common "view won't update" bug.

## `@Observable`

- Prefer it over `ObservableObject` when the floor allows (iOS 17+): views track
  only the properties they read in `body`.
- Mark models that drive views `@MainActor` (unless the module defaults to it).
- Make stored property types `Equatable` so same-value writes don't invalidate.
- `@ObservationIgnored` for state that shouldn't trigger updates.

## `ForEach` identity

Stable, unique ids tied to the data. Never `.indices`, offsets, `\.self` on
mutable values, or ids created on the fly (`UUID()` in the view). Wrong identity
loses row state, breaks animations, and forces rebuilds.

## Environment

Use `@Environment` for genuinely ambient values. `@Entry` defaults must be stable:
no `Date()`, `UUID()`, or class instances in the default, and no closures — they
invalidate every dependent on each access.

## Animation

Always `.animation(_:value:)` with its `value:`. A `.transition()` animates only
when the change is driven from a stable ancestor (`withAnimation` or an
`.animation` on a parent that stays mounted), never from inside the conditional
being toggled.
