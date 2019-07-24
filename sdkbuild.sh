
name=1.zip

# trash cache
rm -rf ~/Library/Caches/org.carthage.CarthageKit
[ -f "Cartfile.resolved" ] && rm "Cartfile.resolved"

# dl dependencies
carthage update --platform ios --new-resolver && rome upload

# generate LICENSES
swift acknowledge.swift

# package it
zip $name Carthage/Build Cartfile.resolved LICENSES.md Carthage/Checkouts/IBAnimatable
