#!/bin/bash

# remove useless sources

echo "🗑️ Removing 3rd parties example and doc from sources"

rm -Rf Carthage/Checkouts/ZIPFoundation/Tests/ZIPFoundationTests/Resources

## demo
rm -Rf Carthage/Checkouts/IBAnimatable/IBAnimatableApp
rm -Rf Carthage/Checkouts/Kingfisher/Demo
rm -Rf Carthage/Checkouts/SwiftMessages/Demo
rm -Rf Carthage/Checkouts/XCGLogger/DemoApps
rm -Rf Carthage/Checkouts/Eureka/Example
rm -Rf Carthage/Checkouts/DeviceKit/Example
rm -Rf Carthage/Checkouts/Alamofire/Example
rm -Rf Carthage/Checkouts/SwiftyJSON/Example
rm -Rf Carthage/Checkouts/Prephirences/Example
rm -Rf Carthage/Checkouts/Moya/Examples
rm -Rf Carthage/Checkouts/CallbackURLKit/SampleApp
rm -Rf Carthage/Checkouts/SwiftMessages/iMessageDemo

## docs
rm -Rf Carthage/Checkouts/Guitar/docs
rm -Rf Carthage/Checkouts/Kingfisher/docs
rm -Rf Carthage/Checkouts/IBAnimatable/Documentation
rm -Rf Carthage/Checkouts/Alamofire/Documentation
rm -Rf Carthage/Checkouts/Alamofire/docs
rm -Rf Carthage/Checkouts/Moya/docs
rm -Rf Carthage/Checkouts/Moya/docs_CN
rm -Rf Carthage/Checkouts/Eureka/Documentation
rm -Rf Carthage/Checkouts/BrightFutures/Documentation

## resources
rm -Rf Carthage/Checkouts/SwiftMessages/Design
rm -Rf Carthage/Checkouts/Moya/Tests/testImage.png
rm -Rf Carthage/Checkouts/Kingfisher/images
rm -Rf Carthage/Checkouts/Eureka/*.png
rm -Rf Carthage/Checkouts/Eureka/*.jpg
rm -Rf Carthage/Checkouts/Moya/web
rm -Rf Carthage/Checkouts/XCGLogger/ReadMeImages
rm -Rf Carthage/Checkouts/Prephirences/Xcodes/Mac/*.gif