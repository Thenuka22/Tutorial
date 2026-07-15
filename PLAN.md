# PlayHub Existing Game Mode Upgrade Plan

**Summary**
- Improve only the existing modes: Tap Frenzy, Light It Up, and Quiz Rush.
- Add global audio, music, haptics, and default game option settings.
- Add per-game customization panels before or above the active play area.
- Track separate leaderboards for different presets, difficulties, and quiz filters.

**Shared Features Added To All Modes**
- Per-game `Customize` panel with preset/options shown before starting.
- Variant-aware scoring so custom modes do not mix unfairly in leaderboards.
- Result screen shows the mode variant, such as `Tap Frenzy - Chaos` or `Quiz Rush - Hard / Computers`.
- Sound effects for key actions, success, mistakes, and round completion.
- Optional background music controlled by Settings.
- Haptics toggle so vibration feedback can be disabled.
- Persistent defaults using `UserDefaults` through a shared `GameSettingsStore`.

**Tap Frenzy Improvements**
- Add presets:
  - `Classic`: current 10-second tap sprint.
  - `Focus`: longer, easier round with fewer distractions and traps disabled.
  - `Chaos`: faster target movement, more bonus/trap changes, higher scoring potential.
- Add customizable options:
  - Round duration.
  - Trap toggle.
  - Bonus burst toggle.
  - Target movement speed.
- Add feedback improvements:
  - Sound for normal tap, bonus tap, trap hit, and round finish.
  - Respect global haptics setting before triggering impact feedback.

**Light It Up Improvements**
- Add presets:
  - `Classic`: current 60-second level progression.
  - `Sprint`: shorter, faster game.
  - `Expert`: faster lights, stronger penalties, more difficult scoring.
- Add customizable options:
  - Round duration.
  - Starting difficulty level.
  - Wrong-tap penalty.
  - Missed-light penalty.
  - Lights per tick intensity.
- Add feedback improvements:
  - Sound for correct tile, wrong tile, missed tile, level change, and finish.
  - Clearer variant label in Stats and Results.

**Quiz Rush Improvements**
- Add API-backed filters:
  - Question count: `5`, `10`, or `15`.
  - Difficulty: `Any`, `Easy`, `Medium`, `Hard`.
  - Category/niche from Open Trivia DB, such as General Knowledge, Computers, Science, History, Geography, Sports, and others.
- Add quiz mode options:
  - Timed questions toggle.
  - Time per question when timed mode is enabled.
  - Optional streak bonus remains active.
- Improve loading/fallback:
  - Load category list from Open Trivia DB.
  - Build quiz requests with `URLComponents`.
  - If selected filters return no questions, retry with fewer filters before using fallback questions.
  - Show the active filter and offline/fallback state clearly.

**Settings UI**
- Add `Audio & Feel` section:
  - Sound effects toggle.
  - Background music toggle.
  - Haptics toggle.
  - Sound volume slider.
  - Music volume slider.
- Add `Default Game Options` section:
  - Default Tap Frenzy preset.
  - Default Light It Up preset.
  - Default Quiz Rush difficulty, category, and question count.
- Keep existing notification, location, and reset stats sections.

**Data and Interfaces**
- Add optional `variantID` and `variantLabel` to `GameSession`.
- Update `GameSessionStore.addSession(...)` to accept variant metadata.
- Add lightweight option models for each game, such as Tap Frenzy options, Light It Up options, and Quiz Rush filters.
- Preserve backward compatibility so old saved sessions still load.

**Test Plan**
- Confirm old saved sessions decode successfully.
- Play every Tap Frenzy preset and verify separate leaderboard entries.
- Play every Light It Up preset and verify scoring/options apply.
- Test Quiz Rush with `Any`, `Easy`, `Hard`, and a category like `Science: Computers`.
- Simulate trivia API failure/no results and verify fallback behavior.
- Toggle sound, music, and haptics off and confirm they stop.
- Run `git diff --check`; final Xcode build/run validation should happen on macOS/Xcode.

**Assumptions**
- No new game titles are added in this pass.
- New Swift files go under `timer/` so they compile with the existing file-system-synchronized target.
- Audio uses simple local/system playback for v1, not licensed external music.
