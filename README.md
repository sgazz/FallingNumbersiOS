# Fall, Number... Fall!

Native iOS puzzle game built with SwiftUI + SpriteKit.

## Overview

`Fall, Number... Fall!` is a falling-number puzzle game inspired by falling-block classics.
Instead of geometric pieces, single number tiles (`1...9`) fall into a `10 x 20` board.

After a tile locks, the game searches for orthogonally connected groups whose sum equals the current target number.
Matching groups are cleared, gravity collapses the board, and chain reactions can occur.

## Tech Stack

- Swift (pure game logic)
- SwiftUI (app UI / HUD / overlays)
- SpriteKit (board + tile rendering)
- UserDefaults (high score persistence)

## Project Structure

- `Falling numbers/App` - app entry
- `Falling numbers/Game` - engine, models, rules, systems
- `Falling numbers/Rendering/SpriteKit` - renderer and scene nodes
- `Falling numbers/UI` - SwiftUI screens + view model
- `Falling numbers/Theme` - visual constants
- `Falling numbers/Audio` - haptics/audio client interfaces
- `Falling numbers/Persistence` - high score store
- `Falling numbersTests` - focused gameplay tests

## Current MVP Features

- 10x20 board
- Single falling number tile
- Move left/right, soft drop, hard drop
- Automatic falling tick
- Collision + lock
- Combination detection for connected subsets (not only whole components)
- Deterministic clear resolution (largest-group-first, stable tie-break)
- Gravity + chain reactions
- Score, combo, level, target, high score
- Pause / resume / game over + new game
- Next-piece preview
- Onboarding helper text
- Haptic feedback hooks + UIKit haptics implementation
- Audio placeholder architecture (`AudioClient`, `SoundEvent`)

## Controls

- Buttons: Left / Down / Drop / Right / Pause
- Gestures:
  - Swipe left: move left
  - Swipe right: move right
  - Swipe down: soft drop / hard drop (larger downward swipe)

## Build

```bash
xcodebuild -project "Falling numbers.xcodeproj" -scheme "Falling numbers" -destination 'generic/platform=iOS' build
```

## Test

```bash
xcodebuild -project "Falling numbers.xcodeproj" -scheme "Falling numbers" -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:'Falling numbersTests' test
```

## Notes

- Game rules are implemented in pure Swift engine code, independent from SpriteKit rendering.
- Rendering layer does not mutate game state.
- No ads, accounts, multiplayer, IAP, or online systems in MVP.
