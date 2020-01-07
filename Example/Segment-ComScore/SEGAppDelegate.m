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
    [[SEGAnalytics sharedAnalytics] track:@"comScore Example Launched v2019"];

    [[SEGAnalytics sharedAnalytics] track:@"Video Playback Started"
                               properties:nil
                                  options:@{
                                            @"integrations": @{
                                                    @"com-score": @{
                                                            @"c4":@"testing-v2019"
                                                            }
                                                    }
                                            }];

    [[SEGAnalytics sharedAnalytics] track:@"Video Content Started"
                               properties:@{
                                   @"content_asset_id" : @"1231312"
                               }
                                  options:@{
                                            @"integrations": @{
                                                    @"com-score": @{
                                                            @"c4":@"testing-v2019"
                                                            }
                                                    }
                                            }];
    
    [[SEGAnalytics sharedAnalytics] track:@"Video Ad Started"
                            properties:@{
                                @"asset_id" : @"1231312",
                                @"pod_id" : @"43434234534",
                                @"type" : @"mid-roll",
                                @"total_length" : @110,
                                @"position" : @43,
                                @"publisher" : @"Adult Swim",
                                @"title" : @"Rick and Morty Ad"
                            }
                           options:@{
                                     @"integrations": @{
                                             @"com-score": @{
                                                     @"c4":@"testing-v2019"
                                                     }
                                             }
                                     }];
    
    [[SEGAnalytics sharedAnalytics] flush];

    return YES;
}

@end
