# Swift Fundamentals Skill

A deliberately **lean** Swift + SwiftUI fundamentals skill for any AI coding tool that supports the [Agent Skills open format](https://code.claude.com/docs/en/skills), the anti-bloat counterpart to large SwiftUI skills. It is a small router (`SKILL.md`) plus five focused references that **defer to each project's own architecture and conventions**, encode the rules that hold in *every* Swift project, and gate new-OS APIs behind availability with a strict no-regression rule.

![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)
![Version](https://img.shields.io/badge/version-1.0.1-green.svg)
![Format: Agent Skills](https://img.shields.io/badge/format-Agent%20Skills-orange.svg)

## Who this is for

Anyone using an agentic coding tool (Claude Code, Codex, Cursor, or any client that reads the Agent Skills format) to write, review, or refactor Swift and SwiftUI. It is intentionally **fundamentals-only**: the things that are true regardless of stack. Project-specific surface (your localization stack, charts, design system, macOS scenes, networking layer) is **owned by the project's own docs**, not by this skill.

## When it triggers

On *any* Swift or SwiftUI work, not just when you say "optimize" or "review":

- adding or refactoring a view, or touching a `body`
- writing async code, actors, or anything that crosses a thread
- choosing a property wrapper or passing data between views
- picking a collection or data structure
- reaching for an abstraction, dependency, or protocol

It fires on phrases like *"build this screen"*, *"this view is slow"*, *"clean this up"*, *"is this thread-safe"*, *"why is it re-rendering"*, and on plain feature work in a Swift/SwiftUI codebase.

## How to use this skill

Each tool installs natively via its own manifest. The skill folder is `swift-fundamentals/` at the repo root (it contains `SKILL.md` + `references/`).

### Claude Code

Install via the `.claude-plugin/` marketplace:

```text
/plugin marketplace add vetrek/swift-fundamentals
/plugin install swift-fundamentals@swift-fundamentals
```

### Codex

Install via the `.codex-plugin/plugin.json` manifest. Codex also auto-scans `~/.agents/skills`, so this manual copy works as a fallback:

```bash
cp -R swift-fundamentals ~/.agents/skills/swift-fundamentals
```

### Cursor

Install via the `.cursor-plugin/plugin.json` manifest, or use the root `AGENTS.md` as a per-project fallback that points Cursor at the skill.

### skills.sh

Generic cross-tool install:

```bash
npx skills add https://github.com/vetrek/swift-fundamentals --skill swift-fundamentals
```

### Manual

Clone the repo and copy or symlink the `swift-fundamentals/` folder into your agent's skills directory:

```bash
git clone https://github.com/vetrek/swift-fundamentals.git
cp -R swift-fundamentals/swift-fundamentals ~/.claude/skills/swift-fundamentals
```

## What it covers

`SKILL.md` is the router. It carries the **prime directive** (follow the current project's architecture and standards; reuse before you write; don't duplicate; test what you change), the **operating rules** (least code that works, no speculative abstraction, performance is structural, correctness first), a topic router, and a **correctness checklist** of fundamentals that are bugs when violated. It then pulls in exactly the reference(s) the task touches, never all five at once.

| Reference | Pull it when | Covers |
|-----------|--------------|--------|
| `references/view-structure.md` | adding/refactoring a view; a `body` is growing | Separate `View` types over computed `var someView` properties, and *why* that drives invalidation (a struct is a real node SwiftUI can skip; a computed property always re-runs). When to extract vs. over-extract; pass minimum inputs; avoid `AnyView`. |
| `references/performance.md` | something is slow; a body is hot; choosing a collection/algorithm | Narrow dependencies, keep `body` a cheap description, stable `ForEach` identity, `Equatable` subviews, `List`/`LazyVStack` for long content, animation correctness + hot-path isolation, and algorithm/data-structure choice (`Set`/`Dictionary` over `O(n²)` scans). Measure before trading clarity for speed. |
| `references/state-data-flow.md` | choosing a property wrapper; passing data between views | One source of truth by ownership: `@State`/`@Binding`/`@Bindable`, never `@State` for passed-in values, prefer `@Observable` (iOS 17+), **derive-don't-store**, `.sheet(item:)` over `Bool + selection`, and navigation-as-state with `NavigationStack(path:)`. |
| `references/concurrency.md` | async work; actors; `Sendable`; `@MainActor`; cancellation | Structured `async`/`await` over callbacks, **isolation over locks** for UI/model state, Swift 6.2 default-MainActor isolation, honoring cancellation (`.task`/`.task(id:)`), `Sendable` and data races (no drive-by `@unchecked`), non-reentrant locks, `Task.sleep(for:)`. Least machinery that's correct under Swift 6. |
| `references/accessibility.md` | adding a tappable control or icon button; images; Dynamic Type | Operable controls (`Button`, not `onTapGesture`), decorative vs. meaningful images, icon-only controls need a label, Dynamic Type via semantic fonts + `@ScaledMetric`, grouping related elements, never signal state by color alone, honor reduce-motion, and don't over-annotate native controls. |

Two rules thread through the whole skill: the **correctness checklist** in `SKILL.md` catches the violations that are bugs regardless of project style, and the **adopt-new-OS-APIs-only-at-or-above-the-deployment-target, never regress** rule means a modern API is used only when the project's floor supports it (guarded by `if #available` / `@available` otherwise), and a behavior an older *supported* OS still needs is never dropped.

## Philosophy: why lean

Most Swift skills try to encode an entire framework. This one encodes only the fundamentals that hold for **every** project, then gets out of the way. Three convictions:

- **The project wins.** When a reference and the codebase disagree, follow the codebase. This skill defers to your `CLAUDE.md`, your module conventions, your layering and DI; it does not impose an architecture.
- **Project-specific surface is intentionally excluded.** Localization, charts, design systems, macOS scenes, networking: those belong to the project's own docs, not a portable skill. Keeping them out is what keeps this skill correct everywhere.
- **The least code that works.** Climb the ladder (does this need to exist? stdlib/native SwiftUI? an existing dependency? one line?) and stop at the first rung that holds. No speculative abstraction, no over-engineering, never the flimsier algorithm.

## Contributing

Issues and PRs welcome. Keep additions **fundamental and portable**: if a rule only applies to one project's stack, it belongs in that project's docs, not here. Match the lean style: a tight router, focused references, and no rule that the code can't already express.

## License

MIT. See `LICENSE`.
