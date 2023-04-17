# SDK

## Prerequisites

First be on macOS, iOS native development is only possible on this openrating system.

To build iOS SDK some tools to be installed:

- [Xcode](https://apps.apple.com/fr/app/xcode/id497799835?mt=12)
- [Carthage](https://github.com/Carthage/Carthage/issues/1194)
  - could be installed with [brew](https://brew.sh/) `brew upgrade carthage`

Not mandatory but helpful
- [xcpretty](https://github.com/xcpretty/xcpretty) to have better log
- [xprojup](https://github.com/phimage/xprojup) to remove warning on imported project by upgrading it

## Build with Carthage

:construction:

## Deploy

Copy content of project into cache folder.

By default the iOS SDK must be installed into: `/Library/Caches/com.4D.mobile/sdk/<version>/iOS/sdk`
- with `version`, the 4d version represented as 4 digits (for instance v20=2000 , v20R2=2020)
