#!/bin/bash

function parse_git_dirty() {
  git diff --quiet --ignore-submodules HEAD 2>/dev/null; [ $? -eq 1 ] && echo "*"
}

# gets the current git branch
function parse_git_branch() {
  git branch --no-color 2> /dev/null | sed -e '/^[^*]/d' -e "s/* \(.*\)/\1$(parse_git_dirty)/"
}

# get last commit hash prepended with @ (i.e. @8a323d0)
function parse_git_hash() {
  git rev-parse --short HEAD 2> /dev/null | sed "s/\(.*\)/@\1/"
}
bnumber=55

# DEMO
GIT_BRANCH=$(parse_git_branch)$(parse_git_hash)
echo ${GIT_BRANCH}
sdkHash=$(parse_git_branch)@$bnumber

cd ..

for f in *; do
    if [[ -d $f ]]; then
      if [[ $f == QMobile* ]]; then
          hash=`git -C $f rev-parse --short HEAD`

          sdkHash=$sdkHash"."$hash
      fi
    fi
done
echo $sdkHash