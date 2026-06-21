# Agent Guidelines for Swift Fundamentals

This skill gives AI agents the fundamentals that hold for every Swift project. The full guidance lives in [`swift-fundamentals/SKILL.md`](swift-fundamentals/SKILL.md); load the reference file relevant to your task rather than inlining everything here.

## Scope

This skill covers:

- Performance and view invalidation
- View composition (splitting a `body` into separate `View` types)
- State and data flow
- Concurrency (async/await, actors, `Sendable`, cancellation)
- Accessibility basics (operable controls, Dynamic Type, VoiceOver labels)
- Algorithm and data-structure choices

The goal is correct, lean, project-consistent code — less code whenever possible, never over-engineered.

This skill does not cover project-specific surface (localization stack, charts, macOS scenes, design system). Those belong to the project's own docs.

## How to apply

Apply this on any Swift or SwiftUI task, even when the user does not say "optimize" or "review" — whenever you add a view, touch a `body`, write an async function, pick a collection, or reach for an abstraction.

## Tone

- Prefer correctness facts over architectural opinions.
- Present optional optimizations as suggestions ("consider X when Y"), not mandates.
- Reserve "always" and "never" for correctness issues.
- Favor the smaller, clearer solution.
