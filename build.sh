#!/bin/bash   

inside_git_repo="$(git rev-parse --is-inside-work-tree 2>/dev/null)"
if [ "$inside_git_repo" ]; then
  GIT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
else
  GIT_BRANCH="main"
  >&2 echo "❌ You are not in git repository, git branch "$GIT_BRANCH" will be used"
fi

if [[ -z "${USE_XCFRAMEWORKS}" ]]; then
  USE_XCFRAMEWORKS=1
fi

CARTHAGE_CHECKOUT_OPTIONS=""
CARTHAGE_BUILD_OPTIONS="--cache-builds --no-use-binaries"
if [ "$USE_XCFRAMEWORKS" -eq 1 ]; then
  CARTHAGE_BUILD_OPTIONS="$CARTHAGE_BUILD_OPTIONS --use-xcframeworks"
  >&2 echo ""
fi
CARTHAGE_PLATFORM="iOS"
CARTHAGE_LOG_PATH="build.log"
if [[ -z "$SIGN_CERTIFICATE" ]]; then
  SIGN_CERTIFICATE="Developer ID Application"
fi
# Set SIGN_MANDATORY to 1 to fail the build if the sdk could not be signed (ex: to release it)
if [[ -z "$SIGN_MANDATORY" ]]; then
  SIGN_MANDATORY=0
fi

if [ "$USE_XCFRAMEWORKS" -eq 1 ]; then
  rm -Rf Carthage/Build/$CARTHAGE_PLATFORM
fi

CARTHAGE_REMOVE_CACHE=0
ROME_USE=0
XPROJ_UP_USE=1 # mandatory now because of project that import iOS 8

# Some dependencies (IBAnimatable...) run swiftlint in a build phase when the binary is found.
# We do not want to lint third party code, so a fake swiftlint is put first in PATH during the build.
# Set DISABLE_SWIFTLINT=0 to keep the real one.
if [[ -z "${DISABLE_SWIFTLINT}" ]]; then
  DISABLE_SWIFTLINT=1
fi

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

cd "$SCRIPT_DIR" # work only if in script dir

if [[ -z "$(which carthage)" ]]; then
  >&2 echo "❌ You must install carthage:"
  >&2 echo "> brew install carthage"
  exit 2
fi

# Install a fake swiftlint (and friends) in a temporary folder put first in PATH.
# The folder is removed when this script exits, whatever the result.
FAKE_BIN_DIR=""
cleanup_fake_bin() {
  if [[ -n "$FAKE_BIN_DIR" && -d "$FAKE_BIN_DIR" ]]; then
    rm -rf "$FAKE_BIN_DIR"
  fi
}
if [[ "$DISABLE_SWIFTLINT" -eq 1 ]]; then
  if [[ -n "$(which swiftlint)" ]]; then
    FAKE_BIN_DIR="$(mktemp -d -t iossdk-fakebin)"
    trap cleanup_fake_bin EXIT INT TERM
    cat > "$FAKE_BIN_DIR/swiftlint" <<'EOF'
#!/bin/sh
# Fake swiftlint installed by ios-sdk build.sh, does nothing and succeeds.
case "$1" in
  version|--version) echo "0.0.0" ;;
  *) echo "swiftlint deactivated by build.sh" >&2 ;;
esac
exit 0
EOF
    chmod +x "$FAKE_BIN_DIR/swiftlint"
    export PATH="$FAKE_BIN_DIR:$PATH"
    echo "🚫 swiftlint deactivated for this build (fake one in $FAKE_BIN_DIR, set DISABLE_SWIFTLINT=0 to keep the real one)"
  fi
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
  XPROJUP_MIN_VERSION="0.1.0"
  XPROJUP_VERSION="$(xprojup --version 2>/dev/null | grep -Eo '[0-9]+\.[0-9]+\.[0-9]+' | head -1)" # versions before $XPROJUP_MIN_VERSION do not support --version
  if [[ -z "$XPROJUP_VERSION" ]]; then
    >&2 echo "❌ Unable to detect xprojup version (must be >= $XPROJUP_MIN_VERSION), please update it:"
    >&2 echo "> sudo curl -sL https://phimage.github.io/xprojup/install.sh | bash"
    exit 2
  fi
  if [[ "$(printf '%s\n' "$XPROJUP_MIN_VERSION" "$XPROJUP_VERSION" | sort -V | head -1)" != "$XPROJUP_MIN_VERSION" ]]; then
    >&2 echo "❌ xprojup $XPROJUP_VERSION is too old (must be >= $XPROJUP_MIN_VERSION), please update it:"
    >&2 echo "> sudo curl -sL https://phimage.github.io/xprojup/install.sh | bash"
    exit 2
  fi
  xprojup --recursive --fix-deployment-target Carthage/Checkouts # for project with target iOS 8.0 it could help to build
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

  # sign if possible (set SIGN_CERTIFICATE to - to deactivate, SIGN_MANDATORY to 1 to make it a build error)
  if [[ "$SIGN_CERTIFICATE" != "-" ]]; then
    echo ""
    security find-certificate -c "$SIGN_CERTIFICATE" >/dev/null 2>&1
    certificate_exists=$?

    if [[ $certificate_exists -eq 0 ]]; then
      "$SCRIPT_DIR/sdksign.sh" "$SIGN_CERTIFICATE"

      # do not produce an sdk that could be released unsigned
      echo ""
      if ! "$SCRIPT_DIR/sdkchecksign.sh" --quiet --authority "$SIGN_CERTIFICATE"; then
        if [[ "$SIGN_MANDATORY" -eq 1 ]]; then
          >&2 echo "❌ signature check failed, the sdk must not be released (SIGN_MANDATORY=1)"
          code=1
        else
          >&2 echo "⚠️  signature check failed, do not release this sdk. Set SIGN_MANDATORY to 1 to make it a build error"
        fi
      fi
    else
      if [[ "$SIGN_MANDATORY" -eq 1 ]]; then
        >&2 echo "❌ no signature done, signing certificate not found '$SIGN_CERTIFICATE'. You could configure SIGN_CERTIFICATE env variable (set to - to deactivate)"
        code=1
      else
        echo "⚠️  no signature done, signing certificate not found '$SIGN_CERTIFICATE'. You could configure SIGN_CERTIFICATE env variable (set to - to deactivate)"
      fi
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
