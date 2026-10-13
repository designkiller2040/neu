# Neu

A minimal SwiftUI cycle tracker. Data stays on device (JSON in the app's Documents folder).

- **Today** – cycle-day ring, phase, days until next period, one-tap "Period started/ended"
- **Calendar** – month view with logged, expected and ovulation days; tap any day to log flow, mood, symptoms, notes
- **Cycles** – history and running averages (last 6 cycles) that drive predictions

## Run

Requires Xcode 15+ (iOS 17). The project file is generated with [XcodeGen](https://github.com/yonaskolb/XcodeGen):

```sh
brew install xcodegen
xcodegen
open Neu.xcodeproj
```

Predictions are estimates from your own history, not medical advice.
