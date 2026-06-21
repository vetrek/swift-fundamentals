# Accessibility

The bar: a control a sighted user can operate, a VoiceOver / Switch Control /
Full-Keyboard / large-Dynamic-Type user can operate too. This is a fundamental,
not polish — the alternative isn't "less refined," it's an app a portion of users
literally cannot use. Keep it minimal and built-in: SwiftUI hands you most of it
for free *if* you reach for the right primitive.

## Use `Button`, not `onTapGesture`, for anything tappable

A `Button` is focusable, carries the `.isButton` trait, fires on VoiceOver
double-tap / keyboard / Switch Control, and announces itself as interactive.
`.onTapGesture` is invisible to every assistive technology — those users can't
tell the element does anything.

```swift
// BAD — assistive tech sees inert text
Text(title).onTapGesture { open() }
// GOOD — operable by everyone, free traits + focus
Button(title) { open() }
```

## Images: decorative vs meaningful

Decorative imagery is noise to VoiceOver — hide it. An image that *conveys*
information needs a label.

```swift
Image(decorative: "texture")                 // or .accessibilityHidden(true)
Image("battery-low").accessibilityLabel(lowBatteryLabel)
```

An SF Symbol *inside* a labeled `Button` is decorative — the button already
carries the meaning; don't double-label.

## Icon-only controls need a label

An icon `Button` has no text, so VoiceOver reads nothing useful. Give it a label
(localized via the project's localization, never a hardcoded literal).

```swift
Button { search() } label: { Image(systemName: "magnifyingglass") }
    .accessibilityLabel(searchLabel)
```

## Respect Dynamic Type

Use semantic font styles (`.body`, `.headline`, or `Font.custom(_:relativeTo:)`)
so text scales with the user's setting; a hardcoded `.system(size: 13)` never
does. For spacing or sizes that must grow with the text, use `@ScaledMetric`.
`.minimumScaleFactor` is a fallback for tight cases, not a substitute for a layout
that reflows.

## Group related elements

A card built from several `Text`s reads as N separate swipes. Merge them so it's
one stop:

```swift
HStack { Text(name); Text(score) }
    .accessibilityElement(children: .combine)
```

Use `.contain` for a container that holds focusable children, `.ignore` to drop
the children and supply your own label.

## Don't signal state with color or shape alone

State shown only by color (red = over limit) is invisible to color-blind users
and to VoiceOver. Pair it with text, an icon, or a trait.

## Honor reduce-motion

Gate decorative or large-movement animation on
`@Environment(\.accessibilityReduceMotion)` and fall back to a cross-fade or
nothing. Animation that conveys meaning can stay. This is the a11y side of the
animation rules in `performance.md`.

## Don't over-do it

Native controls (`Button`, `Toggle`, `List`, `NavigationStack`, `TextField`) are
already accessible — adding labels/traits that just restate what SwiftUI infers is
noise, and noise is its own a11y bug. Annotate where you've *departed* from native
semantics: custom controls, icon-only buttons, combined cards, decorative images.
Everywhere else, the right primitive already did the work.
