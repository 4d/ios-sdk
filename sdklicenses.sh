#!/bin/bash

# generate licenses files
echo "⚖️ Generating licenses files:"

if [[ -z "$(which swift)" ]]; then
  >&2 echo "❌ You must install swift with Xcode"
  exit 2
fi

swift acknowledge.swift # generate LICENSES.md
swift acknowledge.swift json # generate LICENSES.json

if [[ -z "$(which jq)" ]]; then
  >&2 echo "⚠️ Install jq to sort json keys of LICENSES.json"
else
  jq -S . LICENSES.json > LICENSES.json.tmp
  rm LICENSES.json
  mv LICENSES.json.tmp LICENSES.json
fi
