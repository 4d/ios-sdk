#!/bin/bash   

#GIT_BRANCH="main"
GIT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
GIT_URL=https://github.com/4d/ios-

CARTHAGE_CHECKOUT_OPTIONS=""
CARTHAGE_BUILD_OPTIONS="--cache-builds --no-use-binaries"
CARTHAGE_PLATFORM="iOS"
CARTHAGE_LOG_PATH="build.log"

CARTHAGE_REMOVE_CACHE=0
ROME_USE=0
XPROJ_UP_USE=1 # mandatory now because of project that import iOS 8

# Remove cache
if [ "$CARTHAGE_REMOVE_CACHE" -eq 1 ]; then
  echo "🗑️ Removing carthage cache"
  rm -rf ~/Library/Caches/org.carthage.CarthageKit
fi

echo "➡️ Edit cartfile with last QMobile hash"

file=Cartfile.resolved
echo "- before:"
cat $file

# remove QMobile from file
sed -i '' '/QMobile/d' $file

for folder in *; do
    if [[ -d $folder ]]; then
      if [[ $folder == QMobile* ]]; then
          #hash=`git -C $f rev-parse HEAD`
          echo $folder
          hash=`git ls-remote $GIT_URL$folder.git $GIT_BRANCH | awk '{ print $1}'`
          echo $hash
          line="git \"$GIT_URL$folder.git\" \"$hash\""

          echo "$line" >> "$file"
      fi
    fi
done
echo "- after:"
cat $file

if [[ "$ROME_USE" -eq 1 ]]; then
  echo "➡️ Rome download (cache with rome)"
  rome download --platform $CARTHAGE_PLATFORM
fi

echo "➡️ Carthage checkout"
carthage checkout $CARTHAGE_CHECKOUT_OPTIONS

if [[ "$XPROJ_UP_USE" -eq 1 ]]; then
  echo "⬆️ Upgrade Xcode projects"
  xprojup --recursive Carthage/Checkouts # for project with target iOS 8.0 it could help to build
fi

echo "➡️ Carthage fix Cartfile"
# Remove Reactivate extension from Moya
echo "Remove Reactivate extension from Moya"

## Sources
rm -Rf Carthage/Checkouts/Reactive*
rm -Rf Carthage/Checkouts/Rx*

## Build artifact
rm -Rf Carthage/Build/Reactive*
rm -Rf Carthage/Build/Rx*

## Build scheme
rm -Rf Carthage/Checkouts/Moya/Moya.xcodeproj/xcshareddata/xcschemes/Reactive*
rm -Rf Carthage/Checkouts/Moya/Moya.xcodeproj/xcshareddata/xcschemes/Rx*

# SimLinks
rm -Rf Carthage/Checkouts/Moya/Carthage/Checkouts/Reactive*
rm -Rf Carthage/Checkouts/Moya/Carthage/Checkouts/Rx*

## In Cartfile (mandatory or carthage will try to compile or resolve dependencies)
sed -i '' '/Reactive/d' Cartfile.resolved
sed -i '' '/Rx/d' Cartfile.resolved

sed -i '' '/Reactive/d' Carthage/Checkouts/Moya/Cartfile.resolved
sed -i '' '/Rx/d' Carthage/Checkouts/Moya/Cartfile.resolved

sed -i '' '/Reactive/d' Carthage/Checkouts/Moya/Cartfile
sed -i '' '/Rx/d' Carthage/Checkouts/Moya/Cartfile

# use last version of alamofire if 4.7.3
sed -i.bak 's/4.7.3/4.8.0/' Carthage/Checkouts/Moya/Cartfile.resolved

# # # # # # # # # # # # # # 
echo "Remove xcworkspace of QMobile to use project."

cd Carthage/Checkouts
for folder in *; do
  if [[ -d $folder ]]; then
    if [[ $folder == QMobile* ]]; then
      echo "$folder: "
      # remove workspace if project exist (avoid compile dependencies and have some umbrella issues)
      if [[ -d $folder/$folder.xcworkspace ]]; then
        echo "- remove xcworkspace"
        rm -Rf $folder/$folder.xcworkspace
      fi
    fi
  fi
done
cd ../../ # replace by a cd root

echo "➡️ Carthage build"
echo "carthage build $CARTHAGE_BUILD_OPTIONS --platform $CARTHAGE_PLATFORM --log-path '$CARTHAGE_LOG_PATH'"
./carthage.sh build $CARTHAGE_BUILD_OPTIONS --platform $CARTHAGE_PLATFORM --log-path "$CARTHAGE_LOG_PATH"
code=$? # or maybe log in other script

if [ -f "$CARTHAGE_LOG_PATH" ]; then
  # Pretty log
  if [ -x "$(command -v xcpretty)" ]; then
    cat "$CARTHAGE_LOG_PATH" | xcpretty
  else
    echo 'xcpretty not installed'
  fi
else
  echo "no log file"
fi

if [[ "$ROME_USE" -eq 1 ]]; then
  echo "➡️ Rome upload (cache with rome)"
  rome upload --platform $CARTHAGE_PLATFORM
fi

# remove useless files
rm -Rf Carthage/Checkouts/ZIPFoundation/Tests/ZIPFoundationTests/Resources

## demo
rm -Rf Carthage/Checkouts/IBAnimatable/IBAnimatableApp
rm -Rf Carthage/Checkouts/Kingfisher/Demo
rm -Rf Carthage/Checkouts/SwiftMessages/Demo
rm -Rf Carthage/Checkouts/XCGLogger/DemoApps
rm -Rf Carthage/Checkouts/Eureka/Example
rm -Rf Carthage/Checkouts/DeviceKit/Example
rm -Rf Carthage/Checkouts/Alamofire/Example
rm -Rf Carthage/Checkouts/SwiftyJSON/Example
rm -Rf Carthage/Checkouts/Prephirences/Example
rm -Rf Carthage/Checkouts/Moya/Examples
rm -Rf Carthage/Checkouts/CallbackURLKit/SampleApp
rm -Rf Carthage/Checkouts/SwiftMessages/iMessageDemo

## docs
rm -Rf Carthage/Checkouts/Guitar/docs
rm -Rf Carthage/Checkouts/Kingfisher/docs
rm -Rf Carthage/Checkouts/IBAnimatable/Documentation
rm -Rf Carthage/Checkouts/Alamofire/Documentation
rm -Rf Carthage/Checkouts/Alamofire/docs
rm -Rf Carthage/Checkouts/Moya/docs
rm -Rf Carthage/Checkouts/Moya/docs_CN
rm -Rf Carthage/Checkouts/Eureka/Documentation
rm -Rf Carthage/Checkouts/BrightFutures/Documentation

## resources
rm -Rf Carthage/Checkouts/SwiftMessages/Design
rm -Rf Carthage/Checkouts/Moya/Tests/testImage.png
rm -Rf Carthage/Checkouts/Kingfisher/images
rm -Rf Carthage/Checkouts/Eureka/*.png
rm -Rf Carthage/Checkouts/Eureka/*.jpg
rm -Rf Carthage/Checkouts/Moya/web
rm -Rf Carthage/Checkouts/XCGLogger/ReadMeImages
rm -Rf Carthage/Checkouts/Prephirences/Xcodes/Mac/*.gif

# exist with build result
exit $code