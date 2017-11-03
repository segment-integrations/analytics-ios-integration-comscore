# analytics-ios-integration-comscore

[![CircleCI](https://circleci.com/gh/segment-integrations/analytics-ios-integration-comscore.svg?style=svg)](https://circleci.com/gh/segment-integrations/analytics-ios-integration-comscore)
[![Version](https://img.shields.io/cocoapods/v/Segment-ComScore.svg?style=flat)](http://cocoapods.org/pods/Segment-ComScore)
[![License](https://img.shields.io/cocoapods/l/Segment-ComScore.svg?style=flat)](http://cocoapods.org/pods/Segment-ComScore)
[![Platform](https://img.shields.io/cocoapods/p/Segment-ComScore.svg?style=flat)](http://cocoapods.org/pods/Segment-ComScore)

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Installation

To install the Segment-ComScore integration, simply add this line to your [CocoaPods](http://cocoapods.org) `Podfile`:

```ruby
pod "Segment-ComScore"
```

## Usage

After adding the dependency, you must register the integration with our SDK.  To do this, import the ComScore integration in your `AppDelegate`:

```
#import <Segment-ComScore/SEGComScoreIntegrationFactory.h>
```

And add the following lines:

```
NSString *const SEGMENT_WRITE_KEY = @" ... ";
SEGAnalyticsConfiguration *config = [SEGAnalyticsConfiguration configurationWithWriteKey:SEGMENT_WRITE_KEY];

[config use:[SEGComScoreIntegrationFactory instance]];

[SEGAnalytics setupWithConfiguration:config];

```

## License

Segment-ComScore is available under the MIT license. See the LICENSE file for more info.
