#!/bin/bash
#
# release.sh - publish ios.zip as a new GitHub release.
#
# The release name/tag is derived from the `xcodeVersion` file stored inside
# the archive (ie. the Xcode used to build it), following the naming of the
# previous release (ex: tag `xcode-26`, title `Xcode 26`).
#
# Usage: ./release.sh [options]
#   -z, --zip <file>     archive to upload (default: ios.zip)
#   -t, --tag <tag>      force the tag name
#   -n, --title <title>  force the release title
#       --notes <text>   release notes (default: generated)
#       --draft          create the release as a draft
#       --prerelease     create the release as a pre-release
#   -b, --build          build and archive before releasing (build.sh + sdkarchive.sh)
#   -y, --yes            do not ask for confirmation
#   -h, --help           show this help

set -euo pipefail

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd "$SCRIPT_DIR"

zip_file="ios.zip"
tag=""
title=""
notes=""
draft=false
prerelease=false
do_build=false
assume_yes=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    -z|--zip) zip_file="$2"; shift 2;;
    -t|--tag) tag="$2"; shift 2;;
    -n|--title) title="$2"; shift 2;;
    --notes) notes="$2"; shift 2;;
    --draft) draft=true; shift;;
    --prerelease) prerelease=true; shift;;
    -b|--build) do_build=true; shift;;
    -y|--yes) assume_yes=true; shift;;
    -h|--help) sed -n '2,19p' "$0" | sed 's/^# \{0,1\}//'; exit 0;;
    *) echo "Unknown option: $1" >&2; exit 1;;
  esac
done

info()  { echo "▶️  $*"; }
warn()  { echo "⚠️  $*" >&2; }
fail()  { echo "❌ $*" >&2; exit 1; }

is_tty() { [[ -t 0 && -t 1 ]]; }

confirm() {
  $assume_yes && return 0
  is_tty || fail "Not a terminal, use --yes to confirm: $1"
  local answer
  read -r -p "❓ $1 [y/N] " answer
  [[ "$answer" =~ ^[yY] ]]
}

# ----------------------------------------------------------------------------
# 1. github cli & account with access to the current repository
# ----------------------------------------------------------------------------

command -v gh >/dev/null 2>&1 || fail "GitHub CLI (gh) not found. Install it: brew install gh"

git rev-parse --is-inside-work-tree >/dev/null 2>&1 || fail "Not inside a git repository"
remote_url=$(git remote get-url origin 2>/dev/null) || fail "No 'origin' remote found"

login_flow() {
  is_tty || fail "Not logged to GitHub and not a terminal. Run 'gh auth login' or set GH_TOKEN."
  info "Not authenticated to GitHub, starting login…"
  gh auth login --hostname github.com --git-protocol https --web --scopes repo || fail "GitHub login failed"
}

gh auth status --hostname github.com >/dev/null 2>&1 || login_flow

# repository targeted by the current directory
repo=$(gh repo view --json nameWithOwner --jq .nameWithOwner 2>/dev/null || true)
if [[ -z "$repo" ]]; then
  # can happen if the active account cannot even see the repository
  repo=$(sed -E 's#^git@github.com:##; s#^https://github.com/##; s#\.git$##' <<< "$remote_url")
fi
[[ -n "$repo" ]] || fail "Unable to resolve the GitHub repository from $remote_url"

# permission of the active account on that repository
repo_permission() {
  gh api "repos/$repo" --jq '[.permissions | to_entries[] | select(.value) | .key] | join(",")' 2>/dev/null \
    || gh repo view "$repo" --json viewerPermission --jq '.viewerPermission // empty' 2>/dev/null \
    || true
}

has_write() {
  local push
  push=$(gh api "repos/$repo" --jq '.permissions.push // false' 2>/dev/null || echo false)
  [[ "$push" == "true" ]] && return 0
  # fallback if the REST permissions are not available
  case "$(gh repo view "$repo" --json viewerPermission --jq '.viewerPermission // empty' 2>/dev/null)" in
    ADMIN|MAINTAIN|WRITE) return 0;;
    *) return 1;;
  esac
}

current_account() { gh auth status --hostname github.com --active 2>/dev/null | sed -n 's/.*account \([^ ]*\).*/\1/p' | head -1; }

account=$(current_account)
if ! has_write; then
  warn "Account '${account:-unknown}' has no write access to $repo"
  # try the other accounts known by gh before asking for a new login
  switched=false
  while read -r other; do
    [[ -z "$other" || "$other" == "$account" ]] && continue
    info "Trying account '$other'…"
    if gh auth switch --hostname github.com --user "$other" >/dev/null 2>&1 && has_write; then
      account="$other"; switched=true; break
    fi
  done < <(gh auth status --hostname github.com 2>/dev/null | sed -n 's/.*Logged in to github.com account \([^ ]*\).*/\1/p')

  if ! $switched; then
    [[ -n "$account" ]] && gh auth switch --hostname github.com --user "$account" >/dev/null 2>&1 || true
    warn "No logged account can write to $repo"
    warn "If the organization uses SAML SSO, authorize your token first: gh auth refresh -h github.com -s repo"
    login_flow
    account=$(current_account)
    has_write || fail "Account '${account:-unknown}' still has no write access to $repo"
  fi
fi
info "Using GitHub account '$account' on $repo ($(repo_permission))"

# ----------------------------------------------------------------------------
# 2. the archive
# ----------------------------------------------------------------------------

if $do_build; then
  info "Building…"
  ./build.sh
  ./sdkarchive.sh "$(basename "${zip_file%.zip}")"
fi

[[ -f "$zip_file" ]] || fail "Archive '$zip_file' not found. Build it first: ./build.sh && ./sdkarchive.sh"

# xcode version used to build, stored inside the archive
xcode_version_content=$(unzip -p "$zip_file" xcodeVersion 2>/dev/null || true)
[[ -n "$xcode_version_content" ]] || fail "No 'xcodeVersion' file inside $zip_file"

xcode_version=$(grep -m1 -oE '[0-9]+(\.[0-9]+)*' <<< "$xcode_version_content" || true)
[[ -n "$xcode_version" ]] || fail "Unable to parse the Xcode version from: $xcode_version_content"
xcode_build=$(sed -n 's/.*Build version \(.*\)/\1/p' <<< "$xcode_version_content" | head -1)
sdk_version=$(unzip -p "$zip_file" sdkVersion 2>/dev/null | head -1 || true)

info "Archive $zip_file built with Xcode $xcode_version${xcode_build:+ ($xcode_build)}"

# ----------------------------------------------------------------------------
# 3. name of the release, following the previous one
# ----------------------------------------------------------------------------

# previous release, to keep the same naming (ex: `xcode-16.4`, `Xcode 16.4`)
previous=$(gh release list --repo "$repo" --limit 30 --json tagName,name,isLatest \
  --jq '[.[] | select(.tagName | test("(?i)xcode"))][0] // empty' 2>/dev/null || true)
previous_tag=$(jq -r '.tagName // empty' <<< "${previous:-{\}}")
previous_name=$(jq -r '.name // empty' <<< "${previous:-{\}}")

tag_prefix="xcode-"
name_prefix="Xcode "
if [[ -n "$previous_tag" ]]; then
  info "Previous release: $previous_name ($previous_tag)"
  # everything before the first digit is the prefix used by the previous release
  p=$(sed -E 's/[0-9].*$//' <<< "$previous_tag"); [[ -n "$p" ]] && tag_prefix="$p"
  p=$(sed -E 's/[0-9].*$//' <<< "$previous_name"); [[ -n "$p" ]] && name_prefix="$p"
  # keep the usual casing/separator (`xcode-16.4` / `Xcode 16.4`) whatever the last one used
  [[ "$tag_prefix" =~ ^[Xx]code[-_\ ]?$ ]] && tag_prefix="xcode-"
  [[ "$name_prefix" =~ ^[Xx]code[-_\ ]?$ ]] && name_prefix="Xcode "
fi

[[ -n "$tag" ]] || tag="${tag_prefix}${xcode_version}"
[[ -n "$title" ]] || title="${name_prefix}${xcode_version}"

if [[ -z "$notes" ]]; then
  notes="Built with Xcode ${xcode_version}"
  [[ -n "$xcode_build" ]] && notes+=" (build ${xcode_build})"
  [[ -n "$sdk_version" ]] && notes+=$'\n'"SDK version: \`${sdk_version}\`"
  [[ -n "$previous_tag" ]] && notes+=$'\n'"Previous release: ${previous_tag}"
fi

# ----------------------------------------------------------------------------
# 4. publish
# ----------------------------------------------------------------------------

if gh release view "$tag" --repo "$repo" >/dev/null 2>&1; then
  warn "Release '$tag' already exists on $repo"
  confirm "Upload $zip_file to the existing release '$tag' (replacing the asset)?" \
    || fail "Aborted. Use --tag to release under another name."
  gh release upload "$tag" "$zip_file" --repo "$repo" --clobber
  info "Asset uploaded to $(gh release view "$tag" --repo "$repo" --json url --jq .url)"
  exit 0
fi

echo
echo "  repository : $repo"
echo "  tag        : $tag"
echo "  title      : $title"
echo "  asset      : $zip_file ($(du -h "$zip_file" | cut -f1))"
echo "  target     : $(git rev-parse --abbrev-ref HEAD) $(git rev-parse --short HEAD)"
$draft && echo "  draft      : yes"
$prerelease && echo "  prerelease : yes"
echo

confirm "Create this release?" || fail "Aborted"

args=(release create "$tag" "$zip_file" --repo "$repo" --title "$title" --notes "$notes" --target "$(git rev-parse HEAD)")
$draft && args+=(--draft)
$prerelease && args+=(--prerelease)

gh "${args[@]}"
info "Released 🎉 $(gh release view "$tag" --repo "$repo" --json url --jq .url)"
