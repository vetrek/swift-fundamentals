# Concurrency

Goal: correct under Swift 6 strict concurrency, with the **least** machinery.
`async`/`await` and isolation are usually enough — most code does not need an
actor, a queue, or a lock you reached for out of habit. Add synchronization to
protect real shared mutable state, not preemptively.

## Default to structured async

- Prefer `async`/`await` over completion handlers, and over Combine for one-shot
  work. Linear code, real error propagation, no callback nesting.
- Use `.task { }` on a view for work tied to its lifetime — it **auto-cancels**
  when the view disappears. This is the right home for "load on appear."
- Run children concurrently with `async let` (a fixed few) or `TaskGroup` (a
  dynamic number), then `await` them. The structure guarantees they finish (or
  cancel) before the parent returns.

```swift
// Two independent fetches, concurrently, both bounded by this scope
async let user = api.user(id)
async let feed = api.feed(id)
let screen = Screen(user: try await user, feed: try await feed)
```

- Express delays in units: `try await Task.sleep(for: .seconds(2))` (iOS 16+), not
  `Task.sleep(nanoseconds: 2_000_000_000)` — the unit-typed `Duration` kills the
  off-by-three-zeros bug. Below iOS 16, `nanoseconds:` is the non-deprecated
  fallback.

## Isolation, not locks, for UI and model state

- UI state is `@MainActor`. `@Observable` view models that drive views are
  typically `@MainActor` too — then you never hop threads to update them and never
  race the UI.
- **Swift 6.2+ can make main-actor isolation the default** ("approachable
  concurrency": `.defaultIsolation(MainActor.self)` in `Package.swift`, or Xcode's
  *Default Actor Isolation = MainActor*). App code is then on the main actor unless
  it opts out, so you stop sprinkling `@MainActor` everywhere; push work *off* main
  with `nonisolated` (and `@concurrent` for a function that must run in the
  background). Compile-time only — no minimum-OS cost. Below 6.2, hand-annotate UI
  types `@MainActor` (purely additive).
- For shared mutable state **not** on the main actor, make it an `actor`. The actor
  serializes access for you — no manual lock, no `DispatchQueue`. Reach for an
  explicit lock only in a hot, non-async path where actor hops are too costly.
- Don't block the main thread: no synchronous network/disk/CPU-heavy work inside a
  `@MainActor` function. `await` the work off-main, then update state on-main.

## Honor cancellation

A `Task` that outlives its trigger and ignores cancellation leaks work and can
write stale results.

- Prefer `.task`/`.task(id:)` over a bare `Task {}` so the framework cancels for
  you. `.task(id:)` restarts when the id changes — the clean way to reload on
  input change.
- In long loops, check `try Task.checkCancellation()` (or `Task.isCancelled`).
- A fire-and-forget `Task {}` that captures a view/model must avoid retaining it
  past relevance and must drop its result if cancelled.

## Sendable & data races (Swift 6)

The compiler now proves values crossing concurrency domains are safe. Work *with*
it instead of silencing it:

- Make types crossing actor/task boundaries `Sendable` (value types of `Sendable`
  members usually are for free). Don't reach for `@unchecked Sendable` to make a
  warning disappear.
- `@unchecked Sendable` is a promise *you* now enforce — it's only honest when a
  real lock guards **every** access to the mutable state.
- Locks (`Mutex`, `OSAllocatedUnfairLock`) are **non-reentrant**: acquiring one
  you already hold deadlocks/asserts. Never call out to unknown code (a delegate,
  a continuation handler, `onTermination`) while holding the lock — collect under
  the lock, then act after releasing it.
- Bridging callback APIs: wrap with `withCheckedContinuation` /
  `withCheckedThrowingContinuation`, and resume **exactly once** on every path.

## Don't over-build

- No actor/queue/lock for state that never crosses a thread, or that `@MainActor`
  already serializes.
- No `DispatchQueue` where an `actor` or plain `await` expresses it more simply.
- No detached `Task.detached` unless you specifically need to escape the current
  actor's isolation — it throws away context (priority, task-locals) you usually
  want to keep.
