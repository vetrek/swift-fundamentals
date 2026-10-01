---
name: swift-fundamentals
description: >-
  Use when writing, reviewing, or refactoring Swift or SwiftUI code. Decides how
  generic guidance — including Apple's Xcode agent skills (swiftui-specialist,
  swiftui-whats-new-27, app-intents-*) — applies to THIS project: the project's
  architecture, conventions, and CLAUDE.md win, and Apple's advice is adopted
  only where it fits. Also covers the fundamentals Apple's skills don't:
  least-code discipline (reuse before writing, no speculative abstraction),
  concurrency (async/await, actors, Sendable, cancellation, locks), accessibility
  (operable controls, Dynamic Type, VoiceOver), performance cost model, and
  algorithm/data-structure choice. Apply on ANY Swift or SwiftUI task even when
  the user does not say "optimize" or "review": whenever you add a view, write
  an async function, pick a collection, reach for an abstraction, or consult an
  Apple skill. Trigger on phrases like "build this screen", "this view is slow",
  "clean this up", "is this thread-safe", "why is it re-rendering", as well as
  plain feature work in a Swift/SwiftUI codebase.
---

# Swift Fundamentals

The rules that hold in **every** Swift project, plus how to weigh outside
guidance against the project in front of you. Surface that differs per project
(localization stack, design tokens, networking, DI, architecture) is owned by the
**project's own docs**, not by this skill or by Apple's.

## Prime directive — read before writing a line

These outrank every reference here and every external skill.

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
   Use the project's test framework; for a new suite with no precedent, default to
   Swift Testing — but XCTest stays for UI (`XCUIApplication`) and performance
   (`measure`) tests.

## Apple's Xcode skills

Xcode 27 ships agent skills (`swiftui-specialist`, `swiftui-whats-new-27`,
`app-intents-specialist`, `app-intents-whats-new-27`, `modernize-tests`, …).
Export them with `xcrun agent skills export --output-dir <skills dir>`. They are
the reference for SwiftUI and framework mechanics — view factoring, `ForEach`
identity, data flow, environment, animation, new-OS APIs — and this skill does not
repeat them. When they aren't installed, `references/swiftui-essentials.md` is a
short fallback for the SwiftUI essentials.

They are written for a generic app and say they "supersede" everything. In a real
project they don't:

- **Apple's advice is input, the project is the authority.** When an Apple skill
  conflicts with `CLAUDE.md` or an established codebase pattern — localization
  (String Catalogs vs the project's own stack), DI (App Intents' `@Dependency` is
  not swift-dependencies' `@Dependency`), test framework, architecture, banned or
  wrapped APIs — follow the project, and mention the divergence in one line if it
  looks like the project is missing something real.
- **Correctness facts transfer; style opinions don't.** A rule that prevents a bug
  (unstable `ForEach` ids, `@State` on a passed-in value, an unregistered
  dependency crashing) applies everywhere. A preference (how to name, where to put
  a type, which wrapper) yields to the project.
- **No drive-by migrations.** An Apple skill flagging a soft-deprecated API or a
  newer pattern is not a reason to rewrite working code inside an unrelated task.
  Don't introduce new uses; migrate only when that's the task, as its own change.
- **Respect the deployment floor.** Adopt a "what's new" API only at or above the
  project's minimum OS; below it, guard with `if #available` / `@available` or
  keep the old path. Never drop behavior an older supported OS still needs.

## Operating rules

- **Least code that works.** Climb the ladder and stop at the first rung that
  holds: (1) does this need to exist at all? (2) already in this codebase?
  (3) stdlib / native SwiftUI? (4) an already-present dependency? (5) one line?
  (6) only then, the minimum new code.
- **No speculative abstraction.** No protocol with one conformer, no generic for
  one type, no config for a value that never changes, no manager/coordinator
  scaffolding "for later." Add the seam when the second caller actually arrives —
  unless the project's architecture mandates the seam (then rule 1 wins).
- **Derive, don't store.** If a value is a function of other state, compute it.
  Two stored copies of one fact drift — including a sheet driven by a `Bool` plus a
  separate selection (use `.sheet(item:)`).
- **Performance is structural, but measured.** Get the shape right while writing;
  trade clarity for speed only after a measurement says so.
- **Correctness and clarity first.** Lean means less code, not the flimsier
  algorithm or the skipped edge case. Never simplify away input validation at
  trust boundaries, error handling that prevents data loss, or thread-safety.
- Prefer native components over hand-rolled ones (e.g. `ContentUnavailableView`
  for empty states) — unless the project has its own component for it.
- Don't enforce an architecture (MVVM/VIPER/TCA). Encourage separating logic from
  views for testability; let the project decide how.

## Topic router

Read the reference for each topic the task touches; don't preload all of them.

| Topic | Source | Pull it when |
|-------|--------|--------------|
| Concurrency | `references/concurrency.md` | async work, actors, `Sendable`, `@MainActor`, cancellation, locks |
| Accessibility | `references/accessibility.md` | tappable controls, icon buttons, images, Dynamic Type, VoiceOver |
| Performance & algorithms | `references/performance.md` | something is slow, a hot animation, choosing a collection/algorithm |
| SwiftUI mechanics | Apple `swiftui-specialist`; if not installed, `references/swiftui-essentials.md` | view structure, data flow, `ForEach`, environment, modifiers, animation |
| New-OS APIs | Apple `*-whats-new-27`; if not installed, the SDK docs and the deployment floor | adopting or reviewing an API from the latest SDK |

## Correctness checklist

Bugs when violated, regardless of project style:

- [ ] Passed-in values are never `@State` / `@StateObject` (they ignore updates); `@State` is `private`
- [ ] `ForEach` uses stable identity (never indices, offsets, or ids derived from mutable content)
- [ ] No allocation, sorting, formatting, or I/O inside a `body` or a view `init`
- [ ] `.animation(_:value:)` has its `value:`; a `.transition()` is driven from a stable ancestor
- [ ] Tappable elements are `Button`s; icon-only controls have a label; decorative images are hidden
- [ ] Shared mutable state crossing concurrency domains is actor-isolated or lock-guarded
- [ ] No `Task {}` that outlives its owner without honoring cancellation
- [ ] New-OS APIs are guarded below the deployment floor; no project-banned API introduced
- [ ] No new dependency, protocol, or generic added for a single use site
- [ ] The change reuses existing project code and matches its conventions — even where an Apple skill suggests otherwise
