# Handoff: Afterflow redesign (iOS)

> **Note (Aug 2026):** This redesign has been fully implemented — tokens live in
> `Afterflow/Resources/Assets.xcassets` (`Theme/`, `Treatment/`) and
> `Afterflow/Utilities/DesignTokens.swift`. This document is kept as the design
> spec of record (token tables, dark-mode remap, type scale, rationale). The
> interactive prototype bundle it references ("Files in this bundle" below) was
> removed from the working tree; recover it from git history if needed:
> `git show d81e89e:"design_handoff_afterflow_redesign/Afterflow Redesign.dc.html"`.

## Overview

A visual and interaction redesign of Afterflow's six existing surfaces — sessions list, search, calendar, session detail, new-session form — plus two new surfaces the team asked for: a **Trends** view (mood over time) and a dedicated **Reflection entry** screen. Information architecture is unchanged from what ships today; what changes is the visual system, the arrangement of the primary controls, and two additions.

Everything is grounded in the existing SwiftUI codebase (`LauraReesby/afterflow`, branch `main`). Feature behaviour, model fields, statuses, mood scale and music-link handling all come from that source — see **Mapping to the codebase** below.

## About the design files

The files in this bundle are **design references created in HTML**. They are prototypes that show intended look and behaviour — **not production code to copy**. The task is to recreate them in the app's existing environment: **SwiftUI + SwiftData, iOS 17.6+**, using the project's established patterns (`Views/`, `ViewModels/`, `Services/`, `Utilities/DesignConstants.swift`).

Concretely that means: new colour and type tokens belong in the asset catalogue / a design-tokens file alongside `DesignConstants`, not as literals scattered through views; the layouts below should be built with SwiftUI `List`/`ScrollView`/`LazyVGrid` as the current screens are; and the HTML's `div`/`flex` structure is a description of intent, not a structure to mirror.

## Fidelity

**High fidelity.** Colours, type, spacing, radii and copy are final. Recreate pixel-faithfully, substituting SwiftUI-native controls (`DatePicker`, `Slider`, `Menu`, `TextField`) where the HTML fakes them.

One deliberate exception: the HTML frames are drawn at 402×874 (iPhone 16 Pro logical size). All values below are in points at that width; nothing is pixel-locked, everything should flow.

---

## Design tokens

Taken from the "Organic" design system (`design_system/styles.css` in this bundle). Add these as named colours; do not re-derive them.

### Colour roles

| Token | Hex | Used for |
| --- | --- | --- |
| `bg` | #f5ead8 | Page ground (light) |
| `text` | #201e1d | Primary text (light) |
| `accent` | #c67139 | Primary action fill, selected mood step |
| `accent-2` | #7a8a5e | Second voice: "complete" state, reflect nudge |

### Neutral ramp

| Step | Hex | Step | Hex |
| --- | --- | --- | --- |
| neutral-100 | #f9f4ed | neutral-600 | #82796a |
| neutral-200 | #eee7db | neutral-700 | #645c50 |
| neutral-300 | #dcd3c4 | neutral-800 | #474238 |
| neutral-400 | #c0b6a5 | neutral-900 | #2e2b25 |
| neutral-500 | #a19786 | | |

### Accent ramp (terracotta)

| Step | Hex | Step | Hex |
| --- | --- | --- | --- |
| accent-100 | #fff2eb | accent-600 | #b2622d |
| accent-200 | #ffe1d0 | accent-700 | #8c491a |
| accent-300 | #ffc6a5 | accent-800 | #643312 |
| accent-400 | #f6a06b | accent-900 | #402310 |
| accent-500 | #d67f48 | | |

### Accent-2 ramp (sage)

| Step | Hex | Step | Hex |
| --- | --- | --- | --- |
| accent-2-100 | #f0fae1 | accent-2-600 | #728157 |
| accent-2-200 | #e1eecc | accent-2-700 | #56633f |
| accent-2-300 | #ccdbb2 | accent-2-800 | #3d472b |
| accent-2-400 | #aebf92 | accent-2-900 | #272e1b |
| accent-2-500 | #8fa073 | | |

### Typography

- **Display / headings:** Caprasimo, weight 400 only. Sizes used: 40 (screen title), 34 (Trends title), 30 (detail + reflection headings), 28 (form heading), 26/22 (numerals), 20 (month names).
- **Body / UI:** Figtree, weights 400 / 600 / 700. Sizes: 16 (row title, field text), 15 (secondary), 14 (buttons, subheads), 13 (meta, chips), 12 (kickers, captions), 11 (tags, legends).
- **Kicker style** (section labels — "WHEN", "MOOD", "INTENTION"): 12pt, letter-spacing 0.08em, uppercase, `neutral-600`.
- Never bolden Caprasimo; hierarchy is size and space.

### Geometry

- Radii: `sm` 8, `md` 16, `lg` 28 (cards), `999` (all buttons, chips, inputs, avatars).
- Spacing scale (1.10× density): 4.4 / 8.8 / 13.2 / 17.6 / 26.4 / 35.2. Screen gutters are 16; card inner padding 16–18.
- Shadows: `sm` 0 1px 2px rgba(46,43,37,0.14); `md` 0 3px 10px rgba(46,43,37,0.16); `lg` 0 12px 32px rgba(46,43,37,0.22). Cards use `sm`; floating buttons use `md`.

### Icons

**Lucide**, inline SVG, **stroke-width 2.75**, round caps and joins, on `currentColor`. Icons used: `search`, `plus`, `chevron-left`, `chevrons-up-down`, `trending-up`, `external-link`, `ellipsis`. If the team prefers SF Symbols for platform consistency, that is a reasonable substitution — but keep one family throughout and match the heavier weight (`.semibold`).

### Treatment colours

The shipped app uses system tints (`Color.purple`, `.indigo`, `.cyan`…) via `TreatmentTypeAppearance.swift`. The redesign remaps them to muted earth tones that sit on a warm ground. Same identity, same initials, unchanged in dark mode.

| Treatment | Initials | Hex |
| --- | --- | --- |
| Psilocybin | P | #c67139 |
| LSD | L | #9b6a9e |
| DMT | D | #4f8a8b |
| MDMA | MD | #d69a3f |
| Ketamine | K | #6f8fa8 |
| Ayahuasca | A | #8a6a4f |
| Mescaline | ME | #7a8a5e |
| Cannabis | C | #94a86b |
| Other | O | #a19786 |

Avatar: 38×38 circle, filled with the treatment colour, initials in Figtree 13/700 at #fdf7ee. (Detail screen uses 52×52 with 17pt initials.) The current `TreatmentAvatar`'s gradient/soft-light/screen overlay stack is dropped — the flat fill is intentional.

### Dark mode

Dark is the same design with tokens remapped through the ramps — a mode, not a rebrand. Type, radii and treatment colours are unchanged.

| Light role | Dark replacement |
| --- | --- |
| `bg` (page) | `neutral-900` #2e2b25 |
| `neutral-100` (cards) | `neutral-800` #474238 |
| `neutral-200` (fills, borders, inactive) | `neutral-700` |
| `neutral-300` | `neutral-600` |
| `neutral-400` | `neutral-500` |
| `text` | `neutral-100` #f9f4ed |
| `neutral-600` (muted text) | `neutral-400` |
| `neutral-700` (secondary text/icons) | `neutral-300` |
| `accent-100/200/300` (tint fills) | `accent-900/800/700` |
| `accent-700/800/900` (text on tints) | `accent-300/200/100` |
| `accent-500/600` | `accent-400` |
| Same pattern for all `accent-2-*` | |

Two inversions that are **not** mechanical and must be preserved:
1. **Segmented control:** in dark the *track* is darker than the selected chip (track `neutral-900` + 1px `neutral-700` border; selected chip `neutral-700`). In light it is the reverse (track `neutral-200`, selected chip `neutral-100` + `shadow-sm`).
2. **Glyphs on accent fills** read as dark ink (`neutral-900`) in dark mode, cream (#fdf7ee) in light.

In SwiftUI this is a colour-set-per-token job in `Assets.xcassets` (Any/Dark appearances), which then makes the whole thing automatic.

---

## Navigation model (changed)

The shipped app puts search, calendar-toggle and add in one floating glass pill, centred at the bottom. The redesign splits them by job (option **3a** in `explorations/Afterflow Nav Options.dc.html`, chosen after comparing three arrangements):

- **List ↔ Calendar** — a labelled segmented control directly under the screen title, full width minus gutters. Replaces the icon that silently swapped between `calendar` and `list.bullet`. Works in both directions, so Calendar no longer needs a back button.
- **Search** — a pull-down field under the segmented control (placeholder "Search intentions and reflections"). Tapping it expands the panel *in place* at the top of the screen.
- **Add** — a single 60×60 circular button, `accent` fill, bottom-right, inset 20 from the trailing edge and 34 from the bottom, `shadow-md`. It is the only floating element.

Consequence: nothing occludes list content. The old pill clipped the last visible row; the scroll region now reserves 130 of bottom padding instead.

The header row above the title is unchanged in structure: an `ellipsis` menu button on the left (60×40 pill, `neutral-100`, `shadow-sm`) and a **Trends** pill on the right (40 tall, `accent-200` fill, `accent-800` label + `trending-up` icon, 13/600).

---

## Screens

### 1. Sessions list

**Purpose:** the home surface; scan history, see what still needs reflecting, open a session.

Layout, top to bottom, all inside a single vertical scroll (gutters 16, content max width = screen):

1. Header row (see above), 56 below the status bar.
2. Title `Sessions` — Caprasimo 40, letter-spacing -0.02em. Subhead Figtree 14 `neutral-600`: "Ten logged · last one three days ago" (live copy: count + relative date of most recent).
3. Segmented control, 16 top margin: track `neutral-200`, radius 999, 3 inner padding; two equal segments, 8 vertical padding, 13/600.
4. Search field, 12 top margin: `neutral-200` fill, radius 999, padding 10×14, `search` icon 16 + placeholder 15 `neutral-600`.
5. **Reflect nudge** (only when sessions need reflection): `accent-2-200` card, radius `lg`, padding 14×16. Title 15/600 `accent-2-800` ("Three sessions are waiting"), subtitle 13 `accent-2-700` ("A few words is plenty."), trailing pill button — `accent-2-700` fill, `neutral-100` label, 13/600, padding 9×16 — labelled "Reflect", opening the reflection screen for the oldest unreflected session.
6. **Session rows** in one `neutral-100` card, radius `lg`, `shadow-sm`, rows divided by 1px `neutral-200` top borders (no divider above the first row):
   - Row: padding 14×16, 13 gap. Avatar 38. Right column: title row (treatment name 16/600 + date 12 `neutral-600`, right-aligned), intention 13 `neutral-700` truncated to one line, then a meta row (3 top margin) with the status tag and mood text.
   - Status tag: radius 999, padding 2×9, 11/600. Complete → `accent-2-200` / `accent-2-800`. Reflect → `accent-200` / `accent-800`.
   - Mood text 11 `neutral-600`: "mood 5 → 6" when complete, "mood 5 · after not added" otherwise.
   - Tap → session detail. Hover/press → row background `neutral-200`.
7. Add button, floating (see above).

**Note:** the earlier draft carried a mood-lift chart on this screen. It was removed — trends live only on the Trends view.

### 2. Search (state of the list, not a separate screen)

When the search field is tapped it becomes a `neutral-100` card (radius `lg`, 1px `neutral-200` border, padding 14) containing:

- Active field: `neutral-200` pill, `search` icon, live `TextField`, trailing "Done" 13/600 `accent-700` that collapses the panel.
- **Treatment filter chips**, wrapping, 7 gap: All + all nine `PsychedelicTreatmentType.allCases`. Selected → `accent` fill, #fdf7ee label. Unselected → transparent with 1px `neutral-300` border, `neutral-700` label. 13/600, padding 6×13.
- **Sort** row: kicker "SORT" + segmented control with Newest / Oldest / Mood lift (maps to `SessionListViewModel.SortOption`).

While a query is active:

- The reflect nudge is hidden (results are the subject).
- A result line appears above the list: "3 sessions mention "grief"" — 13/600 `accent-800` — with a trailing "Clear" (12/600 `neutral-600`).
- **Matching reflections are quoted in the row.** Any session whose *reflection text* matched shows the matching passage beneath its intention: `accent-100` block, radius `md`, padding 8×11, a 2pt `accent-400` rule down the left, text 12/1.45 `accent-900`. This is the important behavioural addition — the current app searches `intention` and `reflections` but shows no evidence of why a row matched.

Search filters on intention + reflections, matching `SessionListViewModel.applyFilters`.

### 3. Calendar

Same header, title and segmented control as the list (Calendar segment selected); subhead becomes "Ten logged · six this quarter". Then, per month:

- Month name — Caprasimo 20, 10 bottom margin.
- Weekday row: 7 columns, 11/600 `neutral-500`, centred.
- Day grid: 7 columns, 6 row gap / 2 column gap, cells 38×38 centred, day number 15 `neutral-700`.
- A day with a session is a filled 38 circle in that session's **treatment colour**, number 15/600 #fdf7ee.
- Today additionally carries a 3pt `accent-200` ring (`box-shadow: 0 0 0 3px`).
- Tapping a marked day opens that session's detail.
- Bottom padding 110 so the Add button never covers a row of days.

Month range and grid generation already exist in `Support/CalendarGridHelper.swift` — reuse unchanged.

**Open question (not yet decided):** whether the search field and reflect nudge should also appear here. Current recommendation: search stays list-only (a grid can't express ranked results), the nudge appears as a single compact line, and days awaiting reflection get a hollow terracotta ring rather than a filled dot.

### 4. Session detail

1. Header: back chevron (44×40 `neutral-100` pill), centred title "Session" 15/600, trailing **Edit** pill (40 tall, `neutral-100`, `accent-700` label 14/600).
2. Identity block, 20 top: avatar 52, treatment name Caprasimo 30 (line-height 1.05), meta line 13 `neutral-600` — "Today, 6:59 PM · Oral".
3. **Mood card** — `neutral-100`, radius `lg`, `shadow-sm`, padding 18. Kicker "MOOD" + delta 13/600 `accent-700` ("+1 shift"). Body: before value in a 44 `neutral-200` circle with caption "before"; a dotted rising arc; after value in a 52 `accent-200` circle, 20/700 `accent-800`, captioned with the `MoodRatingScale` descriptor; trailing status tag.
   **This block is under review** — five alternatives are in `explorations/Afterflow Mood Card Options.dc.html`. The recommended replacement is **6b "On the scale"**: a single 1–10 track with a hollow marker at the before value, a filled `accent` marker at the after value (with a 4pt `accent-100` halo), the span between them tinted `accent-300`, and "1 tender / 10 radiant" end labels. Confirm with the design owner before building.
4. Kicker "INTENTION" + card containing the intention, 16/1.5.
5. Kicker "MUSIC" + card: 54 artwork tile (radius `md`) using the provider logo from `Assets.xcassets/Brands`, title 15/600, meta 12 `neutral-600` ("Spotify · Lo-Fi Collective · 1 hr"), trailing `external-link` icon. Behaviour, provider classification, oEmbed hydration and the link-only fallback are all existing `MusicLinkMetadataService` behaviour — unchanged.
6. Kicker "REFLECTION" with a trailing "Add more" link (12/600 `accent-700`) + card, 15/1.6 `neutral-800`. Existing markdown rendering (`MarkdownRenderer`) applies.

When there is no music link or no reflection, keep the current app's empty affordances ("Attach music link", "You haven't added reflections yet.") restyled to these tokens.

### 5. New session (sheet)

Presented as a sheet over a dimmed ground; sheet corner radius 28, drag indicator 38×5 `neutral-400`.

- Bar: "Cancel" 15 `neutral-700` / title "New session" 15/600 / **Save** pill (`accent` fill, #fdf7ee, 14/600, padding 9×18), disabled until the form validates (existing `FormValidation` rules: non-empty intention, mood in 1–10, normalised date).
- Heading: Caprasimo 28 "Set an intention", subhead 14 `neutral-600` "Mood and reflections can come later." (Replaces "Draft • Capture your intention".)
- Kicker "WHEN" + card row: label 16 + two `neutral-200` pill buttons (date, time), 14/600 — these are `DatePicker(.compact)` in `[.date, .hourAndMinute]`.
- Kicker "TREATMENT" + **wrapping chip row** exposing all nine treatment types (selected → `accent` fill; 14/600, padding 9×14). Below it, a card row "Administration" with the current value 15/600 `accent-700` + `chevrons-up-down`, opening a `Menu` over `AdministrationMethod.allCases`.
- Kicker "INTENTION" + card containing a multi-line field, 16/1.5, placeholder "What do you hope to explore or heal?".
- Kicker "MOOD BEFORE" + card: label "Feeling centered" (descriptor from `MoodRatingScale`) and "5 of 10" 13 `neutral-600`; below, **ten tappable bars** — equal width, height 34, radius 999, 5 gap. Steps up to the value are `accent-300`, the selected step is `accent`, the rest `neutral-200`. This replaces the `Slider` (easier to hit, shows the whole scale). Keep the existing accessibility contract: adjustable action, value announced as "5 of 10, centered".
- Draft autosave, draft recovery and the post-save reminder prompt ("In 3 hours / Tomorrow / None") are unchanged existing behaviour.

### 6. Reflection entry (new screen)

Reached from the list nudge, the detail screen's "Add more", or a reflection reminder notification (`NotificationHandler` deep link).

- Header: back chevron / "Reflection" / **Save** pill.
- Heading Caprasimo 30 "How has it settled?", context line 14 `neutral-600` — "LSD · July 30 · three days ago".
- **Mood now** card: kicker + current value and descriptor 13/600 `accent-700`; ten bars as in the form but height 38 and **numbered** (10/600, bottom-aligned), with "tender" / "radiant" end labels 11 `neutral-600`. Writes `moodAfter`.
- Kicker "A PLACE TO START" + wrapping **prompt chips**, sage-toned when used: "What emerged", "The hardest moment", "What I will carry", "In my body", "Someone I thought of". Tapping a chip appends `"<label> — "` to the reflection text (two newlines before it if the field is non-empty) and marks the chip used; it does not remove it. This is the "reflection prompts" feature the team asked for.
- Reflection field: card, min height 150, 16/1.65, placeholder "Whatever is still with you — a phrase is enough."
- Saving writes `reflections` (and `moodAfter`), which flips `session.status` from `.needsReflection` to `.complete` via the existing computed property, and should cancel any pending reminder (`ReminderScheduler`).

### 7. Trends (new screen)

Reached from the Trends pill in either list or calendar header. Scrolls; no Add button.

- Header: back chevron / "Trends".
- Title Caprasimo 34 "Mood over time", subhead 14 `neutral-600` "Ten sessions, Nov 2025 to today."
- Range segmented control: 3 months / 6 months / All time.
- **Mood chart card:** kicker "MOOD, BEFORE AND AFTER" + "+2.1 avg" 13/600 `accent-700`. Plot area ~334×150: three horizontal gridlines `neutral-200` with "8" and "4" axis labels 9pt `neutral-500`; the *after* series as a 2.5pt `accent-500` polyline with 3.5 radius dots and an `accent-200` area fill at 55% beneath it; the *before* series as a 2pt `neutral-400` dashed polyline (4 4); month labels at the ends. Legend: dashed swatch "before", solid "after".
- **Three stat tiles**, equal width, 10 gap, radius `lg`, padding 14×16: sessions reflected (`accent-2-200` / `accent-2-800`), average mood after (`accent-200` / `accent-800`), days between sessions (`neutral-200`). Numerals in Caprasimo 26, captions 11 with line-height 1.3.
- **Lift by treatment:** card with one row per treatment — label 13/600 (74 wide), a 10pt track (`neutral-200`) with the bar in that treatment's colour, and the value right-aligned 12 `neutral-700`. Treatments with no after-mood show "—", are dimmed, and are excluded from the average; a footnote states why ("Two sessions still have no after-mood, so LSD sits out of the average"). **Do not silently average incomplete data.**
- **Words you return to:** counted from the user's own reflection text, on-device. Chips sized and tinted by frequency (top term 16/600 in `accent-200`/`accent-800`, second `accent-2-200`/`accent-2-800`, the rest `neutral-200` descending 14 → 12). Footnote: "Counted from your own reflections on this device. Tap a word to see those sessions." Tapping a word should run it as a search — i.e. push the list with that query.

All Trends figures derive from stored sessions; no network, no analytics, consistent with the constitution.

---

## Interactions & behaviour

- **Navigation:** list ⇄ calendar via the segmented control (no push/pop, no back button). Row or marked day → push detail. Add → sheet. Nudge/"Add more"/reminder → reflection screen. Trends pill → push Trends.
- **Search:** tapping the field expands the panel in place; "Done" collapses it and keeps the query; "Clear" empties it. Filtering is live per keystroke (the current 300ms debounce pattern in the form is a good model if needed).
- **Chips:** treatment filter, treatment type, prompts and range are all single-tap toggles. Prompt chips are additive (never destructive to typed text).
- **Mood bars:** tap any step to set the value; drag across is a nice-to-have.
- **Transitions:** keep `DesignConstants.Animation` values — 0.3s ease-in-out for panel expand/collapse and view swaps, spring (0.35 / 0.8) for the list⇄calendar change.
- **States:** every interactive element needs a themed pressed state — one step along the ramp (`accent` → `accent-600` in light, → `accent-400` in dark; tinted surfaces → next ramp step). Focus rings, where applicable, are 2pt `accent` at 2pt offset. Never leave system-default blue.
- **Empty states:** "no sessions yet" on the list, "no sessions this month" on the calendar, "no matches for X" in search, and Trends needing at least two sessions with after-moods before the chart is meaningful — all currently unspecified; worth designing before ship.
- **Accessibility:** preserve the existing VoiceOver labels/hints and Dynamic Type support. Nothing here is smaller than 11pt and no hit target is under 44 (the mood bars are 34 tall but full-width slices; if that fails audit, grow to 44).

## State

Nothing new is needed at the model layer — `TherapeuticSession` already carries every field these screens show. View state added by the redesign:

- `isSearchExpanded`, `searchText`, `treatmentFilter`, `sortOption` — already in `SessionListViewModel`/`SessionListSection`.
- `showCalendarView` — already exists; now driven by the segmented control.
- Reflection screen: `moodAfter`, `reflectionText`, `usedPrompts: Set<String>`.
- Trends: `range` (3 / 6 months / all) and derived aggregates (per-session before/after series, average lift, lift per treatment, reflected count, mean days between sessions, word frequencies). These are computations over `[TherapeuticSession]` and belong in a new `TrendsViewModel` next to `SessionListViewModel`, with the same memoisation approach for large datasets.

## Mapping to the codebase

| Design screen | Existing files to change |
| --- | --- |
| Sessions list | `Views/ContentView.swift`, `Views/ContentView/SessionListSection.swift`, `Views/Components/SessionRowView.swift`, `Views/Shared/TreatmentAvatar.swift`, `Models/TreatmentTypeAppearance.swift` |
| Search + filters | `Views/Components/SearchControlBar.swift` (loses the calendar + add buttons; may disappear entirely), `Views/Components/ExpandableSearchView.swift`, `Views/Components/FullWidthSearchBar.swift`, `ViewModels/SessionListViewModel.swift` |
| Calendar | `Views/ContentView/SessionListSection.swift`, `Views/CollapsibleCalendarView.swift`, `Support/CalendarGridHelper.swift` |
| Session detail | `Views/SessionDetailView.swift`, `ViewModels/MoodRatingScale.swift`, `Views/Components/MusicLinkSummaryCard.swift` |
| New session | `Views/SessionFormView.swift`, `Views/Components/MoodRatingView.swift`, `ViewModels/FormValidation.swift`, `ViewModels/ReminderOption.swift` |
| Reflection entry | **new** view; `Services/ReminderScheduler.swift`, `Services/ReflectionQueue.swift`, `Services/NotificationHandler.swift` for entry points |
| Trends | **new** view + view model over `@Query` sessions |
| Tokens | `Utilities/DesignConstants.swift` + `Resources/Assets.xcassets` colour sets |

Unchanged and out of scope: export/import (`CSVExportService`, `CSVImportService`, `PDFExportService`, `ExportSheetView`), the settings/help menu contents, notification scheduling logic, and all persistence.

## Assets

- **Provider logos** — already in the repo at `Afterflow/Resources/Assets.xcassets/Brands/*` with light/dark variants (Spotify, Apple Music, Apple Podcasts, Bandcamp, SoundCloud, Tidal, YouTube). The designs use these directly; no new brand art. `design_system/brand-spotify-logo.png` in this bundle is a copy for reference only.
- **Fonts** — Caprasimo (display) and Figtree (body), both open-licensed via Google Fonts. Bundle the `.ttf`s in the app; do not fetch at runtime (offline-first).
- **Icons** — Lucide, MIT-licensed; inline the handful listed above rather than adding a dependency, or substitute SF Symbols at `.semibold`.
- **Photography** — none. The design uses no imagery.

## Open decisions

Flag these to the design owner before building; each has an exploration file in this bundle.

1. **Mood block on detail** — five options; **6b** recommended. `explorations/Afterflow Mood Card Options.dc.html`
2. **Accent colour on action surfaces** — terracotta currently does three jobs (action, data, state). Four options; **4c** ("ink actions, colour for meaning only") recommended. `explorations/Afterflow Accent Options.dc.html`
3. **Search + nudge on the calendar view** — recommendation in §3 above, not yet approved.
4. **Empty states** for list, calendar, search and Trends — not yet designed.

## Files in this bundle

| File | What it is |
| --- | --- |
| `Afterflow Redesign.dc.html` | The interactive prototype, light mode — all seven screens, real navigation. **Primary reference.** |
| `Afterflow Redesign Dark.dc.html` | The same prototype in dark mode. |
| `Afterflow Redesign Screens.dc.html` | Board view: every screen side by side, light and dark, with annotations. |
| `Afterflow Current.dc.html` | Pixel-faithful recreation of the **shipped** UI, rebuilt from the SwiftUI source — use it to diff old against new. |
| `explorations/Afterflow Nav Options.dc.html` | The three control arrangements compared; 3a was chosen and is built. |
| `explorations/Afterflow Accent Options.dc.html` | Open decision 2. |
| `explorations/Afterflow Mood Card Options.dc.html` | Open decision 1. |
| `design_system/styles.css` | The Organic token sheet — authoritative source for every value above. |
| `design_system/readme.md` | The design system's own guidance (direction, do/don't). |
| `ios-frame.jsx` | Device-frame scaffolding used by the prototypes. Not part of the design. |

Open the `.dc.html` files in a browser. They are self-contained apart from `design_system/styles.css` and `ios-frame.jsx`, which sit alongside them — if a file's paths don't resolve, note that the originals expect `_ds/organic-…/styles.css`; adjust the `<link>` or open the board from the original project.
