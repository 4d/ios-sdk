#!/bin/bash
#
# sdkchecksign.sh - check that the SDK frameworks are code signed.
#
# By default check the frameworks of the current path (Carthage/Build),
# if an archive (ios.zip) is passed as argument, check the frameworks inside it.
#
# Usage: ./sdkchecksign.sh [ios.zip | folder] [options]
#       --authority <name>  expected signing authority (default: $SIGN_CERTIFICATE
#                           or 'Developer ID Application')
#       --any-authority     accept any authority, only refuse unsigned/adhoc
#       --dsym              also fail if the dSYM are not signed (warning otherwise)
#   -q, --quiet             only print the summary
#   -h, --help              show this help
#
# Exit code: 0 if all frameworks are correctly signed, 1 otherwise.

set -uo pipefail

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

target=""
authority="${SIGN_CERTIFICATE:-Developer ID Application}"
any_authority=false
check_dsym=false
quiet=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --authority) authority="$2"; shift 2;;
    --any-authority) any_authority=true; shift;;
    --dsym) check_dsym=true; shift;;
    -q|--quiet) quiet=true; shift;;
    -h|--help) sed -n '2,18p' "$0" | sed 's/^# \{0,1\}//'; exit 0;;
    -*) echo "Unknown option: $1" >&2; exit 2;;
    *) target="$1"; shift;;
  esac
done

# '-' as certificate means signature deactivated, nothing to check
if [[ "$authority" == "-" ]]; then
  echo "ℹ️  signature check deactivated (SIGN_CERTIFICATE=-)"
  exit 0
fi

say() { $quiet || echo "$@"; }

tmpdir=""
cleanup() { [[ -n "$tmpdir" && -d "$tmpdir" ]] && rm -rf "$tmpdir"; }
trap cleanup EXIT

# ----------------------------------------------------------------------------
# where to look for the frameworks
# ----------------------------------------------------------------------------

if [[ -z "$target" ]]; then
  target="$SCRIPT_DIR"
fi

if [[ -f "$target" && "$target" == *.zip ]]; then
  say "🗜  Checking archive $target"
  tmpdir=$(mktemp -d)
  unzip -q "$target" 'Carthage/Build/*' -d "$tmpdir" || {
    echo "❌ Unable to extract 'Carthage/Build' from $target" >&2; exit 1; }
  root="$tmpdir"
elif [[ -d "$target" ]]; then
  root="$target"
else
  echo "❌ '$target' is not a zip archive nor a folder" >&2
  exit 2
fi

# accept the root of the sdk, a Carthage folder or directly the build folder
if [[ -d "$root/Carthage/Build" ]]; then
  build_dir="$root/Carthage/Build"
elif [[ -d "$root/Build" ]]; then
  build_dir="$root/Build"
else
  build_dir="$root"
fi

shopt -s nullglob
frameworks=("$build_dir"/*.xcframework "$build_dir"/*/*.xcframework "$build_dir"/iOS/*.framework)
shopt -u nullglob

if [[ ${#frameworks[@]} -eq 0 ]]; then
  echo "❌ No framework found in '$build_dir'. Build the SDK first: ./build.sh" >&2
  exit 1
fi

# ----------------------------------------------------------------------------
# check one framework/binary
# ----------------------------------------------------------------------------

signed=0
unsigned=()
adhoc=()
wrong_authority=()
dsym_unsigned=()

# check_one <path> -> 0 ok, 1 not signed, 2 adhoc, 3 wrong authority
check_one() {
  local path="$1" output
  output=$(codesign -dvv "$path" 2>&1)
  if grep -qF "code object is not signed at all" <<< "$output"; then
    return 1
  fi
  if grep -qF "Signature=adhoc" <<< "$output"; then
    return 2
  fi
  if ! $any_authority; then
    grep -qF "Authority=$authority" <<< "$output" || return 3
  fi
  return 0
}

report() {
  local path="$1" label="$2" code="$3"
  case "$code" in
    0) signed=$((signed + 1)); say "  ✅ $label";;
    1) unsigned+=("$label"); say "  ❌ $label: not signed at all";;
    2) adhoc+=("$label"); say "  ❌ $label: adhoc signature only";;
    3) wrong_authority+=("$label"); say "  ❌ $label: not signed by '$authority'";;
  esac
}

for framework in "${frameworks[@]}"; do
  filename=$(basename "$framework")
  name="${filename%.*}"
  extension="${framework##*.}"
  say "📦 $name"

  if [[ "$extension" == "xcframework" ]]; then
    shopt -s nullglob
    for platform_folder in "$framework"/*/; do
      platform_name=$(basename "$platform_folder")
      inner="$platform_folder/$name.framework"
      if [[ -d "$inner" ]]; then
        check_one "$inner"; report "$inner" "$name ($platform_name)" $?
      fi
      for dsym in "$platform_folder"dSYMs/*.dSYM; do
        dsym_file="$dsym/Contents/Resources/DWARF/$name"
        [[ -f "$dsym_file" ]] || continue
        if ! check_one "$dsym_file"; then
          dsym_unsigned+=("$name ($platform_name) dSYM")
          say "  ⚠️  $name ($platform_name): dSYM not signed"
        fi
      done
    done
    shopt -u nullglob
  else
    check_one "$framework"; report "$framework" "$name" $?
    dsym_file="$framework.dSYM/Contents/Resources/DWARF/$name"
    if [[ -f "$dsym_file" ]] && ! check_one "$dsym_file"; then
      dsym_unsigned+=("$name dSYM")
      say "  ⚠️  $name: dSYM not signed"
    fi
  fi
done

# ----------------------------------------------------------------------------
# summary
# ----------------------------------------------------------------------------

problems=$(( ${#unsigned[@]} + ${#adhoc[@]} + ${#wrong_authority[@]} ))
$check_dsym && problems=$(( problems + ${#dsym_unsigned[@]} ))

echo ""
if [[ $problems -eq 0 ]]; then
  echo "✅ $signed signed binaries, all signed with '$authority'"
  if [[ ${#dsym_unsigned[@]} -gt 0 ]]; then
    echo "⚠️  ${#dsym_unsigned[@]} dSYM not signed"
  fi
  exit 0
fi

echo "❌ SDK is not correctly signed: $problems problem(s) on $((signed + problems)) binaries"
[[ ${#unsigned[@]}         -gt 0 ]] && echo "   not signed at all    : ${#unsigned[@]} (${unsigned[0]}…)"
[[ ${#adhoc[@]}            -gt 0 ]] && echo "   adhoc signature      : ${#adhoc[@]} (${adhoc[0]}…)"
[[ ${#wrong_authority[@]}  -gt 0 ]] && echo "   wrong authority      : ${#wrong_authority[@]} (${wrong_authority[0]}…)"
$check_dsym && [[ ${#dsym_unsigned[@]} -gt 0 ]] && echo "   dSYM not signed      : ${#dsym_unsigned[@]}"
echo ""
echo "💡 Install the '$authority' certificate in your keychain then build again:"
echo "   security find-certificate -c '$authority'   # to check it is available"
echo "   ./build.sh                                  # or ./sdksign.sh '$authority'"
exit 1
