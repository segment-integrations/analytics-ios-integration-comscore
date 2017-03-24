//
//  SEGAppDelegate.m
//  Segment-ComScore
//
//  Created by wcjohnson11 on 05/16/2016.
//  Copyright (c) 2016 wcjohnson11. All rights reserved.
//

#import "SEGAppDelegate.h"
#import <Analytics/SEGAnalytics.h>
#import "Segment-ComScore/SEGComScoreIntegrationFactory.h"


@implementation SEGAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [SEGAnalytics debug:YES];

    SEGAnalyticsConfiguration *configuration = [SEGAnalyticsConfiguration configurationWithWriteKey:@"ACIG3kwqCUsWZBfYxZDu0anuGwP3XtWW"];
    configuration.trackApplicationLifecycleEvents = YES;
    configuration.trackAttributionData = YES;
    configuration.flushAt = 1;
    [configuration use:[SEGComScoreIntegrationFactory instance]];

    [SEGAnalytics setupWithConfiguration:configuration];

    [[SEGAnalytics sharedAnalytics] identify:@"234"];
    [[SEGAnalytics sharedAnalytics] track:@"comScore Example Launched"];
    [[SEGAnalytics sharedAnalytics] track:@"comScore Example Testing"];
    [[SEGAnalytics sharedAnalytics] track:@"comScore Example Testing 2"];
    [[SEGAnalytics sharedAnalytics] track:@"Video Ad Completed"];


    [[SEGAnalytics sharedAnalytics] flush];
    return YES;
}


@end
