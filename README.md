# Fall, Number... Fall!

Native iOS addition puzzle built with SwiftUI and SpriteKit. Gameplay works offline, without accounts, ads, or purchases.

## Rules and modes

Single number tiles fall into the board. After a number locks, the engine searches for contiguous horizontal or vertical lines of at least two numbers whose sum equals the current target. Diagonal, L-shaped, and disconnected groups do not match.

The first clear must include the newly locked tile. When several lines qualify, the engine selects the longest, then prefers horizontal lines, then uses a stable position-based tie-break. Cleared tiles disappear and gravity collapses each column.

| Mode | Board (columns × rows) | Behavior |
| --- | --- | --- |
| Beginner | 7 × 12 | Small starting layout, gradual number/target progression, automatic cascades capped at six clear passes per lock. |
| Expert | 10 × 18 | Faster falling, numbers 1–9, random targets 5–20, fixed center spawn, one clear pass per lock. |

The target changes on a timer; the timer runs faster at higher difficulty. Target changes wait while a tile is in its lock delay. Any settled tile in the top row ends the game after the current lock is resolved.

Special tiles become available from level 6 in Beginner and level 3 in Expert:

- **↔ Row Clear:** removes its landing row, then applies gravity and resolves matches.
- **↕ Column Clear:** removes its landing column, then applies gravity and resolves matches.
- **⟳ Reorder:** sorts existing number tiles across occupied cells, starting from the bottom row. It does not automatically resolve matches.

Scores include placement points, line length and direction bonuses, Beginner cascade bonuses, an Expert clear bonus, and perfect-clear rewards. High scores are stored separately for each mode. Resetting a record excludes the current run from setting another record until a new game starts.

## Controls

- Swipe left or right, or tap the corresponding side of the board, to move one column.
- Swipe down briefly, or tap the lower center, for a soft drop.
- Swipe down farther, or double-tap the board, for a hard drop.
- Tap Pause for Resume, Settings, New Game, and Main Menu.
- Play from the menu resumes an unfinished run in the same mode. Selecting another mode starts a new run.
- VoiceOver adds visible buttons for Left, Down, Drop, and Right.

The app pauses when inactive and resumes a run that was paused by the app lifecycle. A manually paused run remains paused.

## Source layout

- `Falling numbers/App` — app entry, scene lifecycle, menu/game navigation.
- `Falling numbers/Game/Engine` — actions, turn orchestration, debug logging.
- `Falling numbers/Game/Models` — board and grid positions (`Board.swift`), tile types (`Tiles.swift`), mode/configuration (`GameConfig.swift`), events (`GameEvents.swift`), game state, and session statistics.
- `Falling numbers/Game/Rules` — line-sum detection.
- `Falling numbers/Game/Systems` — gravity, spawning, score/progression, starting layout, power-ups, telemetry.
- `Falling numbers/UI/Game` — game screen, view model, HUD, controls, overlays. The 124-point HUD with larger labels and values shows a target countdown ring and a tile-shaped next preview; landscape places the HUD beside the board. The board has no outer frame or rendering inset, maximizing the grid while keeping cells square.
- `Falling numbers/UI/Menu` — main menu and how-to-play screen.
- `Falling numbers/UI/Settings` — sound, haptics, and record reset.
- `Falling numbers/Rendering/SpriteKit` — renderer and scene (`SpriteKitRenderer.swift`), board geometry, and tile animations.
- `Falling numbers/Audio` — feedback interfaces and UIKit haptics (`FeedbackClients.swift`), plus generated audio tones (`UIKitAudioClient.swift`). Audio preparation and playback share a background serial queue; players are created on the first sound, interruptions suspend effects, and audio service resets rebuild players on demand. Each resolved turn uses one primary sound and haptic effect, prioritizing game over, perfect clears, power-ups, clears, and placement. Muting or leaving the app stops playing effects. Sound uses media volume and plays even in Silent Mode while enabled; Settings includes Test Sound and plays a preview when Sound is enabled. Real-player tests verify generated WAV decoding, playback progress, and submission through the audio client.
- `Falling numbers/Persistence` — UserDefaults settings and per-mode high scores in `UserDefaultsStores.swift`.
- `Falling numbers/Theme` — Classic (paper, ink, teal, and coral), Cappuccino (cream, ochre, and coffee), Carnival (nine saturated tile colors, candy accents, and a pastel background), and Neon (midnight surfaces, electric outlines, and a soft glow) palettes in `ArcadeTheme.swift`. Settings saves the selection; changing it refreshes the HUD, board, and existing tiles without restarting the run. Cappuccino uses one tile color with readable white values and symbols.
- `Falling numbersTests` — focused rule, engine, timing, spawning, progression, view model, rendering, and regression suites; shared doubles in `Support`.
- `Falling numbersUITests` — navigation and settings flows, each starting with app launch; a game-screen screenshot is attached to the menu/resume test.
- `docs` — static marketing, support, and privacy pages.

The engine has no dependency on SpriteKit or SwiftUI. Rendering mirrors engine state and does not mutate gameplay. Tiles keep stable identities through locking, gravity, and reorder, so equal numbers do not exchange animations. Board equality compares contents; rendering signatures also include tile and run identities. The app clock sends elapsed monotonic time independently of the fall interval, so the configured lock delay does not change with falling speed. Tests can use `.tick` to advance by one fall interval or `.advanceTime(seconds)` for precise timing.

Xcode uses filesystem-synchronized groups: Swift files added within the app or test folders are discovered automatically.

## Build and validation

Open `Falling numbers.xcodeproj`, select the `Falling numbers` scheme, and choose an installed iOS simulator. For a physical device, configure your signing team.

```bash
xcodebuild -project "Falling numbers.xcodeproj" -scheme "Falling numbers" -destination 'generic/platform=iOS' build
```

Run unit tests with an installed simulator destination:

```bash
xcodebuild -project "Falling numbers.xcodeproj" -scheme "Falling numbers" -destination 'platform=iOS Simulator,name=iPhone 17' -parallel-testing-enabled NO -only-testing:'Falling numbersTests' test
```

For interface checks, replace the final test selection with `-only-testing:'Falling numbersUITests/Falling_numbersUITests'`. Confirm audio and haptics on a physical iPhone as well; the simulator may emit internal audio hardware diagnostics.
