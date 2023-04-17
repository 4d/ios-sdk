# SDK

## Prerequisites

First be on macOS, iOS native development is only possible on this openrating system.

To build iOS SDK some tools to be installed:

- [Xcode](https://apps.apple.com/fr/app/xcode/id497799835?mt=12)
- [Carthage](https://github.com/Carthage/Carthage/issues/1194)
  - could be installed with [brew](https://brew.sh/) `brew upgrade carthage`
- [xprojup](https://github.com/phimage/xprojup) to upgrade third party projects
  - `sudo curl -sL https://phimage.github.io/xprojup/install.sh | bash`

Not mandatory but helpful

- [xcpretty](https://github.com/xcpretty/xcpretty) to have better log
- [rome](https://github.com/tmspzz/Rome) to speed up some recurrent build by managing the cache

## Build

### with Carthage

```bash
./build.sh
```

## Update license file from sources

```bash
swift acknowledge.swift # generate LICENSES.md
swift acknowledge.swift json # generate LICENSES.json
```

## Deploy

Copy content of project into cache folder.

By default the iOS SDK must be installed into: `/Library/Caches/com.4D.mobile/sdk/<version>/iOS/sdk`

- with `version`, the 4d version represented as 4 digits (for instance v20=2000 , v20R2=2020)
