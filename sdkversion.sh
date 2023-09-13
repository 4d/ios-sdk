#!/bin/bash

echo "Create version file"
file=sdkVersion

function git_current_branch() {
  local ref
  ref=$(command git symbolic-ref --quiet HEAD 2> /dev/null)
  local ret=$?
  if [[ $ret != 0 ]]; then
    [[ $ret == 128 ]] && return  # no git repo.
    ref=$(command git rev-parse --short HEAD 2> /dev/null) || return
  fi
  echo ${ref#refs/heads/}
}

branch=$(git_current_branch)
buildNumber=local
newBuildNumber=$buildNumber
for f in Carthage/Build/.ios-QMobile*.version; do
    echo "$(basename "$f")"
    hash=$(jq -r .commitish "$f") 
    echo "$hash"
    hash=$(git rev-parse --short "$hash")
    newBuildNumber=$newBuildNumber"."$hash
done

sdkHash=$branch"@"$newBuildNumber
echo "$sdkHash"
echo "$sdkHash" > $file
