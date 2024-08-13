#!/bin/bash   

inside_git_repo="$(git rev-parse --is-inside-work-tree 2>/dev/null)"
if [ "$inside_git_repo" ]; then
  GIT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
else
  GIT_BRANCH="main"
  >&2 echo "❌ You are not in git repository, git branch "$GIT_BRANCH" will be used"
fi

if [[ -z "${USE_XCFRAMEWORKS}" ]]; then
  echo "no USE_XCFRAMEWORKS. try to check if we could do without ie. have a x86_64 carthage"

  if [[ $(file $(which carthage) | grep "x86_64" | wc -l) -eq 1 ]]; then
    echo "💡 carthage is x86_64. framework could be build in legacy way."
    export USE_XCFRAMEWORKS=0
  else
    >&2 echo "❌ You have no x86_64 carthage installed. we could not build std 'framework'. We will build 'xcframework' instead."
    export USE_XCFRAMEWORKS=1
  fi
  export USE_XCFRAMEWORKS=0
fi
echo "USE_XCFRAMEWORKS=$USE_XCFRAMEWORKS"

CARTHAGE_CHECKOUT_OPTIONS=""
CARTHAGE_BUILD_OPTIONS="--cache-builds --no-use-binaries"
if [ "$USE_XCFRAMEWORKS" -eq 1 ]; then
  CARTHAGE_BUILD_OPTIONS="$CARTHAGE_BUILD_OPTIONS --use-xcframeworks"
  >&2 echo "⚠ xcframeworks activated. Maybe not yet compatible with 4D mobile app build. But you could edit an xcode project and integrate it"
  >&2 echo ""
fi
CARTHAGE_PLATFORM="iOS"
CARTHAGE_LOG_PATH="build.log"
if [[ -z "$SIGN_CERTIFICATE" ]]; then
  SIGN_CERTIFICATE="Developer ID Application"
fi

if [ "$USE_XCFRAMEWORKS" -eq 1 ]; then
  rm -Rf Carthage/Build/$CARTHAGE_PLATFORM
fi

CARTHAGE_REMOVE_CACHE=0
ROME_USE=0
XPROJ_UP_USE=1 # mandatory now because of project that import iOS 8

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

cd "$SCRIPT_DIR" # work only if in script dir

if [[ -z "$(which carthage)" ]]; then
  >&2 echo "❌ You must install carthage:"
  >&2 echo "> brew install carthage"
  exit 2
fi

# Remove cache
if [ "$CARTHAGE_REMOVE_CACHE" -eq 1 ]; then
  echo "🗑️ Removing carthage cache"
  rm -rf ~/Library/Caches/org.carthage.CarthageKit
fi

echo "➡️ Edit cartfile with last QMobile hash"

file="$SCRIPT_DIR/Cartfile.resolved"
echo "- before:"
cat "$file"

# remove QMobile from file
sed -i '' '/QMobile/d' "$file"

qmobiles=$(cat "Cartfile" | grep "QMobile" | sed 's/ "HEAD"//g'| sed 's/github //g'| sed 's/"//g')

for repo in $qmobiles; do
  hash=`git ls-remote https://github.com/$repo.git $GIT_BRANCH | awk '{ print $1}'`
  if [[ -z "$hash" ]]; then
    hash="HEAD" # restore head to avoid empty pinned version
  fi
  line="github \"$repo.git\" \"$hash\""
  echo "$line" >> "$file"
done
echo "- after:"
cat $file

if [[ "$ROME_USE" -eq 1 ]]; then
  if [[ -z "$(which rome)" ]]; then
    >&2 echo "❌ You must install rome if ROME_USE=$ROME_USE"
    exit 2
  fi
  echo "➡️ Rome download (cache with rome)"
  rome download --platform $CARTHAGE_PLATFORM
fi

echo ""
echo "➡️ Carthage checkout"
carthage checkout $CARTHAGE_CHECKOUT_OPTIONS

if [[ "$XPROJ_UP_USE" -eq 1 ]]; then
  echo ""
  echo "⬆️ Upgrade Xcode projects"
  if [[ -z "$(which xprojup)" ]]; then
    >&2 echo "❌ You must install xprojup:"
    >&2 echo "> sudo curl -sL https://phimage.github.io/xprojup/install.sh | bash"
    exit 2
  fi 
  xprojup --recursive Carthage/Checkouts # for project with target iOS 8.0 it could help to build
else
  >&2 echo "You must let activated prj upgrade because of some project lke XCGLogger"
  exit 1
fi

echo ""
echo "➡️ Carthage fix Cartfile"
# Remove Reactivate extension from Moya
echo " Remove Reactivate extension from Moya"

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
echo " Remove xcworkspace of QMobile to use project."

cd "$SCRIPT_DIR/Carthage/Checkouts"
for repo in $qmobiles; do
  repo=${repo#*-}
  echo "$repo: "
  # remove workspace if project exist (avoid compile dependencies and have some umbrella issues)
  if [[ -d "ios-$repo/$repo.xcworkspace" ]]; then
    echo "- remove xcworkspace"
    rm -Rf "ios-$repo/$repo.xcworkspace"
  fi
done
cd "$SCRIPT_DIR"

echo ""
echo "➡️ Carthage build"
if [ "$USE_XCFRAMEWORKS" -eq 1 ]; then
  echo "carthage build $CARTHAGE_BUILD_OPTIONS --platform $CARTHAGE_PLATFORM --log-path '$CARTHAGE_LOG_PATH'"
  carthage build $CARTHAGE_BUILD_OPTIONS --platform $CARTHAGE_PLATFORM --log-path "$CARTHAGE_LOG_PATH"
else
  echo "./carthage.sh build $CARTHAGE_BUILD_OPTIONS --platform $CARTHAGE_PLATFORM --log-path '$CARTHAGE_LOG_PATH'"
  ./carthage.sh build $CARTHAGE_BUILD_OPTIONS --platform $CARTHAGE_PLATFORM --log-path "$CARTHAGE_LOG_PATH"
fi
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

echo ""
"$SCRIPT_DIR/sdklicenses.sh"

echo ""
"$SCRIPT_DIR/sdkversion.sh"

if [[ "$code" -eq 0 ]]; then
  # remove useless things
  echo ""
  "$SCRIPT_DIR/sdkclean.sh"
  if [ "$USE_XCFRAMEWORKS" -ne 1 ]; then
    "$SCRIPT_DIR/sdkstriparch.sh"
  fi

  # sign if possible
  if [[ "$SIGN_CERTIFICATE" != "-" ]]; then
    echo ""
    security find-certificate -c "$SIGN_CERTIFICATE" >/dev/null 2>&1
    certificate_exists=$?

    if [[ $certificate_exists -eq 0 ]]; then
      "$SCRIPT_DIR/sdksign.sh" "$SIGN_CERTIFICATE"
    else
      echo "⚠️  no signature done, signing certificate not found '$SIGN_CERTIFICATE'. You could configure SIGN_CERTIFICATE env variable (set to - to deactivate)"
    fi
  fi
fi

/usr/bin/xcodebuild -version > xcodeVersion

echo ""
if [[ "$code" -eq 0 ]]; then
  echo "✅ Build succeed"

  echo "💡 You could now replace 'Carthage' folder in your generated app"
  if [ "$USE_XCFRAMEWORKS" -eq 1 ]; then
    >&2 echo "⚠ and modify your project, by removing all framework and replace it by xcframework (if 4d mobile app do not do it yet)"
    >&2 echo ""
  fi
  echo "📦 or create an archive ios.zip using script ./sdkarchive.sh"
else
  >&2 echo "❌ Build failed"
fi
# exist with build result
exit $code
