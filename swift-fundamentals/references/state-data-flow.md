# State & Data Flow

The rule behind every rule here: **one source of truth, owned by exactly one
place, depended on by the narrowest set of views.** Most SwiftUI bugs and most
re-render problems are really data-flow problems.

## Pick the wrapper by ownership

| You need | Use | Notes |
|----------|-----|-------|
| View owns a value | `@State private var` | Always `private`. The view creates and mutates it. |
| Child mutates parent's value | `@Binding` | Only when the child writes back. Read-only? pass a plain `let`. |
| View owns a reference object (iOS 17+) | `@State` + `@Observable` class | The view creates it and keeps it alive. |
| Injected observable needing bindings | `@Bindable` | For passed-in `@Observable` objects you bind into ($). |
| Read-only passed-in data | `let` | The default. Don't wrap what you only read. |
| Pre-iOS 17 owned reference | `@StateObject` | View-created `ObservableObject`. |
| Pre-iOS 17 injected reference | `@ObservedObject` | Passed-in `ObservableObject`. |

## The bugs that come from getting ownership wrong

- **A passed-in value declared `@State` / `@StateObject`** silently ignores
  updates from the parent — `@State`/`@StateObject` initialize **once** and keep
  their own copy. This is the most common "why won't my view update" bug. Passed
  in → `let`, `@Binding`, `@ObservedObject`, or `@Bindable`.
- **`@Binding` where a plain `let` would do** adds write capability the child
  doesn't use — widen access only when the child actually mutates.
- **Two stored copies of the same fact** drift apart. Store once; derive the rest.
- **A sheet driven by a `Bool isPresented` *plus* a separate `selected` value** is
  that same two-copies bug — the flag and the value drift out of sync. Use
  `.sheet(item:)` with one optional `Identifiable` selection (SwiftUI presents when
  it's non-nil), and let the sheet dismiss itself via `@Environment(\.dismiss)`
  rather than an injected `onCancel`/`onDismiss` closure the parent has to wire.

## Prefer `@Observable` (iOS 17+) over `ObservableObject`

`@Observable` tracks dependencies per-property: a view re-evaluates only when a
property it **actually reads in `body`** changes, not on every `objectWillChange`.
That's both less boilerplate (no `@Published`) and fewer invalidations. Migrate
when the deployment target allows; otherwise `ObservableObject` + `@Published`.

- Mark stored properties that shouldn't trigger updates `@ObservationIgnored`.
- Hand a subview the **sub-object or single value** it needs, not the whole model,
  so its dependency stays narrow (see `performance.md`).

## Derive, don't store (YAGNI for state)

The leanest state is the state you don't keep. If a value is a pure function of
other state, compute it — a `var isValid: Bool { !name.isEmpty }`, not a stored
flag you must remember to update. Every stored copy is one more thing to keep in
sync and one more way to be wrong.

```swift
// BAD — derived flag stored, must be hand-maintained everywhere `items` changes
@State private var isEmpty = true
// GOOD — derived, never out of sync
var isEmpty: Bool { items.isEmpty }
```

## Navigation is state (iOS 16+)

A `NavigationStack(path:)` makes the visible stack a pure function of a `@State`
path: push / pop / pop-to-root are array edits, and a `Codable NavigationPath`
gives deep-linking and state restoration for free. Drive destinations with
`.navigationDestination(for:)` — not the deprecated `NavigationLink(isActive:)` /
`tag:selection:`. Reach for `NavigationStack` for *new* navigation; don't rip out a
working `NavigationView` mid-unrelated-task (the migration can reset state — see the
soft-deprecation rule in `SKILL.md`). Below iOS 16, keep `NavigationView` behind an
`if #available`, or raise the floor.

## Environment & custom keys

- Use `@Environment` for genuinely ambient values (theme, sizing, services), not
  to avoid passing one value one level down.
- Custom `@Entry` environment/focused keys: **stable default values** — no
  `Date()`, `UUID()`, `Model()` expressions in the default (they create churn /
  fresh identity each access) — and **never store closures** in them.
