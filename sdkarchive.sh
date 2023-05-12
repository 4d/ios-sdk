#!/bin/bash

name=$1
if [[ -z "$name" ]]; then
  name="ios"
fi

zip -r $name Carthage/Build Cartfile.resolved LICENSES.md Carthage/Checkouts/IBAnimatable
