---
name: swift-fundamentals
description: >-
  Use when writing, reviewing, or refactoring Swift or SwiftUI code. Covers the
  fundamentals that hold for every Swift project: performance and view
  invalidation, view composition (splitting a body into separate View types
  instead of computed properties, and why that affects performance), state and
  data flow, concurrency (async/await, actors, Sendable, cancellation),
  accessibility basics (operable controls, Dynamic Type, VoiceOver labels), and
  algorithm/data-structure choices. The goal is correct, lean, project-consistent
  code — less code whenever possible, never over-engineered. Apply this on ANY
  Swift or SwiftUI task even when the user does not say "optimize" or "review":
  whenever you add a view, touch a `body`, write an async function, pick a
  collection, or reach for an abstraction. Trigger on phrases like "build this
  screen", "this view is slow", "clean this up", "is this thread-safe", "why is
  it re-rendering", as well as plain feature work in a Swift/SwiftUI codebase.
  Does NOT cover project-specific surface (localization stack, charts, macOS
  scenes, design system) — those belong to the project's own docs.
---

# Swift Fundamentals

A router for the things that are true in **every** Swift project. It deliberately
covers fundamentals only — not framework trivia. Surface that differs per project
(how you localize, your design tokens, your networking layer, charts, macOS
scenes) is owned by the **project's own docs**, not here.

## Prime directive — read before writing a line

These outrank every suggestion in the references. When a reference and the
project disagree, the project wins.

1. **Follow the current project's architecture and standards.** Read the relevant
   `CLAUDE.md` / module conventions first. Match the layering, naming, DI, and
   patterns already in the codebase. Consistency beats personal preference — a
   "better" pattern that fights the codebase is worse.
2. **Reuse before you write.** Search for an existing type, helper, extension, or
   component that already does this. Extending or calling existing code beats new
   code every time.
3. **Don't duplicate.** If the same logic appears twice, that's a bug waiting to
   diverge. Lift it to one place the project already uses for shared code.
4. **Test what you change.** Non-trivial logic leaves a runnable check behind.
   Build and test the narrowest target that covers the change, not the whole app.
   For new unit tests default to Swift Testing (`@Test`/`#expect`/`#require`,
   Xcode 16+) unless the project standardizes on XCTest — but keep XCTest for UI
   (`XCUIApplication`) and performance (`measure`) tests, which Swift Testing does
   not cover.

## Operating rules

- **Least code that works.** Climb the ladder and stop at the first rung that
  holds: (1) does this need to exist at all? (2) stdlib / native SwiftUI? (3) an
  already-present dependency? (4) one line? (5) only then, the minimum new code.
- **No speculative abstraction.** No protocol with one conformer, no generic for
  one type, no config for a value that never changes, no manager/coordinator
  scaffolding "for later." Add the seam when the second caller actually arrives.
- **Performance is a property of structure, not a pass you bolt on later.** Most
  SwiftUI performance comes from *how the view tree is factored* and *how narrow
  your dependencies are* — get that right while writing, don't profile your way
  out of it after. But don't micro-optimize on a hunch: measure before you trade
  clarity for speed.
- **Correctness and clarity first.** Lean means writing less code, not picking the
  flimsier algorithm or skipping the edge case. Never simplify away input
  validation at trust boundaries, error handling that prevents data loss, or
  thread-safety.
- Prefer native SwiftUI/Swift APIs over UIKit/AppKit bridging (unless bridging is
  genuinely necessary), and a native component over a hand-rolled one — e.g.
  `ContentUnavailableView` (iOS 17+) for empty / error / no-results states instead
  of a bespoke icon+title+button `VStack`.
- **Don't migrate a soft-deprecated API as a drive-by** during unrelated work — it
  risks behavioral regressions (e.g. `NavigationView` → `NavigationStack` resetting
  state) and noisy diffs. Don't introduce *new* uses of a deprecated API; migrate
  only when that migration is the actual task, as its own change.
- **Adopt a new-OS API only at or above the deployment target — never regress.**
  Use a modern API when the project's floor supports it; below the floor, guard it
  with `if #available` / `@available` or keep the older path. Never drop a behavior
  an older *supported* OS still needs, and never adopt an API the project's own
  floor has deprecated or banned — the project's docs win (prime directive 1).
- Don't enforce an architecture (MVVM/VIPER/TCA). Encourage separating logic from
  views for testability; let the project decide how.

## Topic router

Read the reference for each topic the task actually touches. Don't preload all
four — pull the one you need.

| Topic | Reference | Pull it when |
|-------|-----------|--------------|
| View composition | `references/view-structure.md` | adding/refactoring a view, a `body` is growing, deciding whether to extract |
| Performance & invalidation | `references/performance.md` | something is slow, a body is hot, choosing a collection/algorithm, re-render questions |
| State & data flow | `references/state-data-flow.md` | choosing a property wrapper, passing data between views, `@Observable` questions |
| Concurrency | `references/concurrency.md` | async work, actors, `Sendable`, `@MainActor`, cancellation, data races |
| Accessibility | `references/accessibility.md` | adding a tappable control or icon button, images, Dynamic Type, VoiceOver labels/grouping |

## Correctness checklist

Fundamentals that are bugs when violated, regardless of project style:

- [ ] `@State` / `@FocusState` properties are `private`
- [ ] Passed-in values are never `@State` / `@StateObject` (they'd ignore updates)
- [ ] `@StateObject` for view-owned reference objects; `@ObservedObject`/`@Bindable` for injected
- [ ] iOS 17+: `@State` with `@Observable`; `@Bindable` for injected observables needing bindings
- [ ] `ForEach` uses stable identity (never `.indices` / index-as-id / id derived from mutable content)
- [ ] No allocation, sorting, formatting, or network/disk work inside a `body`
- [ ] `.animation(_:value:)` includes the `value:` parameter (not the broad, deprecated global `.animation(_:)`)
- [ ] A `.transition()` is driven by `withAnimation` / `.animation(_:value:)` on a stable ancestor — never an `.animation` placed inside the conditional being toggled (else removal won't animate)
- [ ] Tappable elements use `Button` (not `onTapGesture`); icon-only controls have an `accessibilityLabel`; decorative images are hidden from VoiceOver
- [ ] Shared mutable state crossing concurrency domains is actor-isolated or lock-guarded (and the lock is non-reentrant-safe)
- [ ] No `Task {}` that outlives its view without honoring cancellation
- [ ] A new-OS API used above the deployment floor is `@available`/`if #available`-guarded; no path an older *supported* OS needs was dropped, and no project-deprecated/banned API was introduced
- [ ] No new dependency, protocol, or generic added for a single use site
- [ ] The change reuses existing project code instead of re-implementing it
