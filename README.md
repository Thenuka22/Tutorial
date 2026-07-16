# MiNi ARCADE

MiNi ARCADE is a portrait SwiftUI mini-game collection. It brings three games into one native app with Home, Stats, Map, Settings, score sharing, local reminders, and JSON persistence.

## Architecture Overview

The app is organized under `timer/` into the assignment folders:

- `App`: `MiniArcadeApp` and the root `TabView` shell.
- `Models`: `GameMode`, `GameSession`, and `TriviaQuestion`.
- `ViewModels`: one view model per game plus `StatsVM`.
- `Services`: session persistence, free trivia loading, local notifications, and Core Location.
- `Views`: tab screens, game screens, and shared UI components.

Each completed game writes one `GameSession` to `UserDefaults` as encoded JSON. Sessions are the single source of truth for best scores, totals, recent games, chart data, and map pins.

## Features

- Four-tab SwiftUI game shell: Home, Stats, Map, and Settings.
- A portrait launch artwork and full-screen intro video before the game shell appears.
- Switchable Jungle Day, Sunset Ruins, and Moonlit Forest artwork, while Jungle Day keeps its original visual treatment.
- Custom game glyphs and compact arcade controls built with SwiftUI.
- Three game modes: Tap Frenzy, Light It Up, and Quiz Rush.
- Stats tab with totals, best scores, recent games, and a Swift Charts bar chart.
- Map tab using MapKit markers for completed sessions with real saved coordinates.
- Result screen with `ShareLink` for sharing a score.
- Settings tab with local daily challenge notifications, audio controls, default game options, and a reset-all-stats action.
- Free-only implementation using Apple frameworks and a free trivia endpoint with bundled fallback questions.

## Known Limitations

- Location pins appear only after the user grants location permission and the device/simulator provides a coordinate. Scores still save without a location.
- Daily challenges are local notifications only. There is no server, remote push notification, TestFlight, App Store release, or paid Apple Developer Program dependency.
- Quiz Rush uses a free public trivia endpoint. If the request fails, the app uses bundled fallback questions.

## Reflection

This refactor turns three separate mini games into a structured app. The most important change is the shared `GameSession` model: it keeps the project explainable because every feature reads from one persisted session history instead of each game keeping separate manual scores.
