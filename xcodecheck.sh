#!/bin/bash
#
# xcodecheck.sh - find the Xcode installed on this machine.
#
# Without argument, print the Xcode currently selected (xcode-select).
# With a version, look for a matching installed Xcode: the version could be
# partial, '16' matches '16.4', and the most recent match is used.
#
# Usage: ./xcodecheck.sh [version] [options]
#   -l, --list       list all the Xcode found (version, build, path)
#   -p, --path       print only the DEVELOPER_DIR of the matching Xcode
#   -q, --quiet      do not print anything, only set the exit code
#   -h, --help       show this help
#
# Exit code: 0 if a matching Xcode is installed, 1 if not.

set -uo pipefail

wanted=""
do_list=false
path_only=false
quiet=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    -l|--list) do_list=true; shift;;
    -p|--path) path_only=true; shift;;
    -q|--quiet) quiet=true; shift;;
    -h|--help) sed -n '2,17p' "$0" | sed 's/^# \{0,1\}//'; exit 0;;
    -*) echo "Unknown option: $1" >&2; exit 2;;
    *) wanted="$1"; shift;;
  esac
done

# everything but the path goes to stderr, so `xcodecheck.sh 16 --path` can be used in $(…)
say()  { $quiet || >&2 echo "$@"; }
fail() { $quiet || >&2 echo "❌ $*"; }

plist_value() { /usr/libexec/PlistBuddy -c "Print :$2" "$1/Contents/version.plist" 2>/dev/null; }

# `version<tab>build<tab>path` of every Xcode found, sorted by version
xcode_list() {
  local app version build current
  {
    mdfind "kMDItemCFBundleIdentifier == 'com.apple.dt.Xcode'" 2>/dev/null
    for app in /Applications/Xcode*.app "$HOME/Applications"/Xcode*.app; do
      [[ -d "$app" ]] && echo "$app"
    done
    # the selected one could be anywhere (ex: a beta moved out of /Applications)
    current=$(xcode-select -p 2>/dev/null)
    [[ "$current" == *"/Contents/Developer" ]] && echo "${current%/Contents/Developer}"
  } | sed 's#/*$##' | sort -u | while read -r app; do
    [[ -d "$app/Contents/Developer" ]] || continue
    version=$(plist_value "$app" CFBundleShortVersionString)
    [[ -n "$version" ]] || continue
    build=$(plist_value "$app" ProductBuildVersion)
    printf '%s\t%s\t%s\n' "$version" "${build:-?}" "$app"
  done | sort -V -u
}

# '16' matches '16', '16.4' and '16.4.1' but not '161'
version_matches() {
  [[ "$2" == "$1" || "$2" == "$1".* ]]
}

installed=$(xcode_list)

if [[ -z "$installed" ]]; then
  fail "No Xcode found on this machine. Install it from the App Store or https://developer.apple.com/download/all/"
  exit 1
fi

selected_dir=$(xcode-select -p 2>/dev/null)

print_list() {
  local version build app mark
  while IFS=$'\t' read -r version build app; do
    mark=" "
    [[ "$selected_dir" == "$app/Contents/Developer" ]] && mark="*"
    >&2 printf '%s %-8s %-10s %s\n' "$mark" "$version" "($build)" "$app"
  done <<< "$installed"
  >&2 echo "  (* currently selected by xcode-select)"
}

if $do_list; then
  say "🔨 Xcode installed:"
  print_list
  [[ -z "$wanted" ]] && exit 0
fi

# ----------------------------------------------------------------------------
# no version asked: just report the selected one
# ----------------------------------------------------------------------------

if [[ -z "$wanted" ]]; then
  while IFS=$'\t' read -r version build app; do
    if [[ "$selected_dir" == "$app/Contents/Developer" ]]; then
      $path_only && echo "$selected_dir"
      say "🔨 Xcode $version ($build) selected: $app"
      exit 0
    fi
  done <<< "$installed"
  $path_only && echo "$selected_dir"
  say "🔨 Selected developer directory: ${selected_dir:-none}"
  exit 0
fi

# ----------------------------------------------------------------------------
# look for the wanted version, the most recent match wins
# ----------------------------------------------------------------------------

found_version=""; found_build=""; found_app=""
while IFS=$'\t' read -r version build app; do
  if version_matches "$wanted" "$version"; then
    found_version="$version"; found_build="$build"; found_app="$app"
  fi
done <<< "$installed"

if [[ -z "$found_app" ]]; then
  fail "Xcode $wanted is not installed."
  if ! $quiet; then
    >&2 echo "   Available:"
    print_list
    >&2 echo "   Download it from https://developer.apple.com/download/all/ (or use xcodes: brew install xcodesorg/made/xcodes)"
  fi
  exit 1
fi

$path_only && echo "$found_app/Contents/Developer"
say "🔨 Xcode $found_version ($found_build) found: $found_app"
exit 0
