# SDK

## Prerequisites

First be on macOS, iOS native development is only possible on this openrating system.

To build iOS SDK some tools to be installed:

- [Xcode](https://apps.apple.com/fr/app/xcode/id497799835?mt=12)
- [Carthage](https://github.com/Carthage/Carthage/issues/1194)
  - could be installed with [brew](https://brew.sh/) `brew install carthage`
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

### with Swift Package Manager

`Package.swift` exists but not tested often, and not integrated with "4D Mobile App" component. (but could be implemented)

## Deploy

Copy content of project into cache folder.

By default the iOS SDK must be installed into: `/Library/Caches/com.4D.mobile/sdk/<version>/iOS/sdk`

- with `version`, the 4d version represented as 4 digits (for instance v20=2000 , v20R2=2020)



## Info about files in this project

- `build.sh`: build using carthage
  - `carthage.sh`: allow to deactivate some architecture when building due to issue if we do framework, and not xcframework
  - `sdkstriparch.sh`: remove useless architectures
  - `sdkclean.sh`: remove some files from sources
  - `sdksign.sh`: with a certificate installed you could sign it (useful if embeded in a mac os app before mobile one)
  - `sdklicenses.sh`: update Licenses files

- `sdkarchive.sh`: if we want to archive to zip with mandatory files

### configuration files

- `Cartfile` & `Cartfile.resolved`: for `carthage` to define list of projects.
- `Romefile` for `rome` to define cache path
- `Package.swift` for swift package manager to define list of swift projects.


## SDK frameworks

### SDK ones (ie. QMobile)

| Name | License | Usefulness |
|-|-|-|
| [QMobileAPI](https://github.com/4d/ios-QMobileAPI) | [4D](https://github.com/4d/ios-QMobileAPI/blob/master/LICENSE.md) | Network api |
| [QMobileDataStore](https://github.com/4d/ios-QMobileDataStore) | [4D](https://github.com/4d/ios-QMobileDataStore/blob/master/LICENSE.md) | Store data |
| [QMobileDataSync](https://github.com/4d/ios-QMobileDataSync) | [4D](https://github.com/4d/ios-QMobileDataSync/blob/master/LICENSE.md) | Synchronize data |
| [QMobileUI](https://github.com/4d/ios-QMobileUI) | [4D](https://github.com/4d/ios-QMobileUI/blob/master/LICENSE.md) | Graphic, Application, Features |

### 3rd parties

| Name | License | Usefulness |
|-|-|-|
| [Prephirences](https://github.com/phimage/Prephirences) | [MIT](https://github.com/phimage/Prephirences/blob/master/LICENSE) | Application settings |
| [XCGLogger](https://github.com/DaveWoodCom/XCGLogger) | [MIT](https://github.com/DaveWoodCom/XCGLogger/blob/master/LICENSE) | Log | 
| [FileKit](https://github.com/nvzqz/FileKit) | [MIT](https://github.com/nvzqz/FileKit/blob/master/LICENSE.md) | Files |

#### Network/API

| Name | License | Usefulness |
|-|-|-|
| [Alamofire](https://github.com/Alamofire/Alamofire ) | [MIT](https://github.com/Alamofire/Alamofire/blob/master/LICENSE) | Network layer |
| [Moya](https://github.com/Moya/Moya) | [MIT](https://github.com/Moya/Moya/blob/master/License.md) | API abstraction layer |
| [Kingfisher](https://github.com/onevcat/Kingfisher ) | [MIT](https://github.com/onevcat/Kingfisher/blob/master/LICENSE) | Download remote image and cache |
| [SwiftyJSON](https://github.com/SwiftyJSON/SwiftyJSON ) | [MIT](https://github.com/SwiftyJSON/SwiftyJSON/blob/master/LICENSE) | Decode/Encode JSON |

#### UI

| Name | License | Usefulness |
|-|-|-|
| [SwiftMessages](https://github.com/SwiftKickMobile/SwiftMessages ) | [MIT](https://github.com/SwiftKickMobile/SwiftMessages/blob/master/LICENSE.md) | Message/Notification UI | 
| [IBAnimatable](https://github.com/IBAnimatable/IBAnimatable) | [MIT](https://github.com/IBAnimatable/IBAnimatable/blob/master/LICENSE) | Design in interface builder | 
| [ValueTransformerKit](https://github.com/phimage/ValueTransformerKit) | [MIT](https://github.com/phimage/ValueTransformerKit/blob/master/LICENSE) | Binding: transform data | 
| [Eureka](https://github.com/xmartlabs/Eureka ) | [MIT](https://github.com/xmartlabs/Eureka/blob/master/LICENSE) | Show form for action |

#### Others

##### Testing

| Name | License | Usefulness |
|-|-|-|
| [CallbackURLKit](https://github.com/phimage/CallbackURLKit ) | [MIT](https://github.com/phimage/CallbackURLKit/blob/master/LICENSE) | x-callback-url protocol | 
| [MomXML](https://github.com/phimage/MomXML) | [MIT](https://github.com/phimage/MomXML/blob/master/LICENSE) | Play with core data model |

##### Templates 3rd parties

| Name | License | Usefulness |
|-|-|-|
| [AnimatedCollectionViewLayout](https://github.com/KelvinJin/AnimatedCollectionViewLayout) | [MIT](https://github.com/KelvinJin/AnimatedCollectionViewLayout/blob/master/LICENSE) | template (not in SDK) |
| [mosaic-layout]( https://github.com/vinnyoodles/mosaic-layout) | [MIT](https://github.com/vinnyoodles/mosaic-layout/blob/master/LICENSE) | template (not in SDK) |

