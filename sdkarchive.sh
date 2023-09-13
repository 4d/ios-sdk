#!/bin/bash

name=$1
if [[ -z "$name" ]]; then
  name="ios"
fi

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd "$SCRIPT_DIR"

rm "$name.zip"
zip -r -y $name Carthage/Build Cartfile.resolved LICENSES.md sdkVersion Carthage/Checkouts
