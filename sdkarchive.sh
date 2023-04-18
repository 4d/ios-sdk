#!/bin/bash

name=$1
if [[ -z "$name" ]]; then
  name="ios"
fi

zip $name Carthage/Build Cartfile.resolved LICENSES.md Carthage/Checkouts/IBAnimatable
