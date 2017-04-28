//
//  SEGComScoreIntegration.m
//  Pods
//
//  Created by William Johnson on 5/16/16.
//
//

#import "SEGComScoreIntegration.h"
#import <Analytics/SEGAnalyticsUtils.h>
#import <ComScore/SCORStreamingAnalytics.h>


@implementation SEGRealStreamingAnalyticsFactory

- (SCORStreamingAnalytics *)create;
{
    return [[SCORStreamingAnalytics alloc] init];
}

@end


@implementation SEGComScoreIntegration

- (instancetype)initWithSettings:(NSDictionary *)settings andComScore:(id)scorAnalyticsClass andStreamingAnalyticsFactory:(id<SEGStreamingAnalyticsFactory>)streamingAnalyticsFactory
{
    if (self = [super init]) {
        self.settings = settings;
        self.scorAnalyticsClass = scorAnalyticsClass;
        self.streamingAnalyticsFactory = streamingAnalyticsFactory;

        SCORPublisherConfiguration *config = [SCORPublisherConfiguration publisherConfigurationWithBuilderBlock:^(SCORPublisherConfigurationBuilder *builder) {
            // publisherId is also known as c2 value
            builder.publisherId = settings[@"c2"];
            builder.publisherSecret = settings[@"publisherSecret"];
            builder.applicationName = settings[@"appName:"];
            builder.usagePropertiesAutoUpdateInterval = [settings[@"autoUpdateInterval"] integerValue];
            builder.secureTransmission = [(NSNumber *)[self.settings objectForKey:@"useHTTPS"] boolValue];
            builder.liveTransmissionMode = SCORLiveTransmissionModeLan;

            if ([(NSNumber *)[self.settings objectForKey:@"autoUpdate"] boolValue] && [(NSNumber *)[self.settings objectForKey:@"foregroundOnly"] boolValue]) {
                builder.usagePropertiesAutoUpdateMode = SCORUsagePropertiesAutoUpdateModeForegroundOnly;
            } else if ([(NSNumber *)[self.settings objectForKey:@"autoUpdate"] boolValue]) {
                builder.usagePropertiesAutoUpdateMode = SCORUsagePropertiesAutoUpdateModeForegroundAndBackground;
            } else {
                builder.usagePropertiesAutoUpdateMode = SCORUsagePropertiesAutoUpdateModeDisabled;
            }
        }];

        SCORPartnerConfiguration *partnerConfig = [SCORPartnerConfiguration partnerConfigurationWithBuilderBlock:^(SCORPartnerConfigurationBuilder *builder) {
            builder.partnerId = @"23243060";
        }];

        [[self.scorAnalyticsClass configuration] addClientWithConfiguration:partnerConfig];
        [[self.scorAnalyticsClass configuration] addClientWithConfiguration:config];

        [self.scorAnalyticsClass start];
    }
    return self;
}


+ (NSDictionary *)mapToStrings:(NSDictionary *)dictionary
{
    NSMutableDictionary *mapped = [NSMutableDictionary dictionaryWithDictionary:dictionary];

    [dictionary enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSString *obj, BOOL *stop) {
        id data = [mapped objectForKey:key];
        if (!![data isKindOfClass:[NSString class]]) {
            [mapped setObject:[NSString stringWithFormat:@"%@", data] forKey:key];
        }
    }];

    return [mapped copy];
}

- (void)identify:(SEGIdentifyPayload *)payload
{
    NSDictionary *mappedTraits = [SEGComScoreIntegration mapToStrings:payload.traits];
    [mappedTraits enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSString *obj, BOOL *stop) {
        id data = [payload.traits objectForKey:key];
        if (data != nil && [data length] != 0) {
            SCORConfiguration *configuration = [self.scorAnalyticsClass configuration];
            [configuration setPersistentLabelWithName:key value:data];
            SEGLog(@"[[SCORAnalytics configuration] setPersistentLabelWithName: %@]", key, data);
        }
    }];
}


- (void)track:(SEGTrackPayload *)payload
{
    if ([payload.event isEqualToString:@"Video Playback Started"]) {
        [self videoPlaybackStarted:payload.properties withOptions:payload.integrations];
        return;
    }

    if ([payload.event isEqualToString:@"Video Playback Paused"]) {
        [self videoPlaybackPaused:payload.properties withOptions:payload.integrations];
        return;
    }

    if ([payload.event isEqualToString:@"Video Playback Buffer Started"]) {
        [self videoPlaybackBufferStarted:payload.properties withOptions:payload.integrations];
        return;
    }

    if ([payload.event isEqualToString:@"Video Playback Buffer Completed"]) {
        [self videoPlaybackBufferCompleted:payload.properties withOptions:payload.integrations];
        return;
    }

    if ([payload.event isEqualToString:@"Video Playback Seek Started"]) {
        [self videoPlaybackSeekStarted:payload.properties withOptions:payload.integrations];
        return;
    }

    if ([payload.event isEqualToString:@"Video Playback Seek Completed"]) {
        [self videoPlaybackSeekCompleted:payload.properties withOptions:payload.integrations];
        return;
    }

    if ([payload.event isEqualToString:@"Video Playback Resumed"]) {
        [self videoPlaybackResumed:payload.properties withOptions:payload.integrations];
        return;
    }


    if ([payload.event isEqualToString:@"Video Content Started"]) {
        [self videoContentStarted:payload.properties withOptions:payload.integrations];
        return;
    }

    if ([payload.event isEqualToString:@"Video Content Playing"]) {
        [self videoContentPlaying:payload.properties withOptions:payload.integrations];
        return;
    }

    if ([payload.event isEqualToString:@"Video Content Completed"]) {
        [self videoContentCompleted:payload.properties withOptions:payload.integrations];
        return;
    }

    if ([payload.event isEqualToString:@"Video Ad Started"]) {
        [self videoAdStarted:payload.properties withOptions:payload.integrations];
        return;
    }

    if ([payload.event isEqualToString:@"Video Ad Playing"]) {
        [self videoAdPlaying:payload.properties withOptions:payload.integrations];
        return;
    }

    if ([payload.event isEqualToString:@"Video Ad Completed"]) {
        [self videoAdCompleted:payload.properties withOptions:payload.integrations];
        return;
    }

    NSMutableDictionary *hiddenLabels = [@{ @"name" : payload.event } mutableCopy];
    [hiddenLabels addEntriesFromDictionary:[SEGComScoreIntegration mapToStrings:payload.properties]];

    [self.scorAnalyticsClass notifyHiddenEventWithLabels:hiddenLabels];
    SEGLog(@"[[SCORAnalytics configuration] notifyHiddenEventWithLabels: %@]", hiddenLabels);
}

- (void)screen:(SEGScreenPayload *)payload
{
    NSMutableDictionary *viewLabels = [@{ @"name" : payload.name } mutableCopy];
    [viewLabels addEntriesFromDictionary:[SEGComScoreIntegration mapToStrings:payload.properties]];
    [self.scorAnalyticsClass notifyViewEventWithLabels:viewLabels];
    SEGLog(@"[[SCORAnalytics configuration] notifyViewEventWithLabels: %@]", viewLabels);
}


- (void)flush
{
    [self.scorAnalyticsClass flushOfflineCache];
    SEGLog(@"[SCORAnalytics flushOfflineCache]");
}

#pragma mark - Video Tracking


NSString *returnNullStringIfNotDefined(NSDictionary *src, NSString *key)
{
    NSString *value = [src valueForKey:key];
    NSString *trimmedValue = [value stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (value && [trimmedValue length] != 0) {
        return [value description];
    } else {
        return @"*null";
    }
}


#pragma Playback Events

- (void)videoPlaybackStarted:(NSDictionary *)properties withOptions:(NSDictionary *)integrations
{
    self.streamAnalytics = [self.streamingAnalyticsFactory create];

    NSDictionary *map = @{
        @"ns_st_ci" : properties[@"asset_id"],
        @"ns_st_ad" : properties[@"ad_type"],
        @"ns_st_cl" : properties[@"total_length"],
        @"ns_st_mp" : properties[@"video_player"],
        @"c3" : returnNullStringIfNotDefined(integrations, @"c3"),
        @"c4" : returnNullStringIfNotDefined(integrations, @"c4"),
        @"c6" : returnNullStringIfNotDefined(integrations, @"c6")

    };

    [self.streamAnalytics createPlaybackSessionWithLabels:map];
    SEGLog(@"[[SCORStreamingAnalytics streamAnalytics] createPlaybackSessionWithLabels: %@]", map);
}


- (void)videoPlaybackPaused:(NSDictionary *)properties withOptions:(NSDictionary *)integrations
{
    long playPosition = [properties[@"play_position"] longValue];

    NSDictionary *map = @{ @"ns_st_ci" : properties[@"asset_id"],
                           @"ns_st_ad" : properties[@"ad_type"],
                           @"ns_st_cl" : properties[@"total_length"],
                           @"ns_st_mp" : properties[@"video_player"],
                           @"ns_st_vo" : properties[@"sound"],
                           @"c3" : returnNullStringIfNotDefined(integrations, @"c3"),
                           @"c4" : returnNullStringIfNotDefined(integrations, @"c4"),
                           @"c6" : returnNullStringIfNotDefined(integrations, @"c6")

    };

    [self.streamAnalytics notifyPauseWithPosition:playPosition labels:map];
    SEGLog(@"[[SCORStreamingAnalytics streamAnalytics] notifyEndWithPosition:%ld labels:%@]", playPosition, map);
}

- (void)videoPlaybackBufferStarted:(NSDictionary *)properties withOptions:(NSDictionary *)integrations
{
    long playPosition = [properties[@"play_position"] longValue];

    NSDictionary *map = @{ @"ns_st_ci" : properties[@"asset_id"],
                           @"ns_st_ad" : properties[@"ad_type"],
                           @"ns_st_cl" : properties[@"total_length"],
                           @"ns_st_mp" : properties[@"video_player"],
                           @"ns_st_vo" : properties[@"sound"],
                           @"c3" : returnNullStringIfNotDefined(integrations, @"c3"),
                           @"c4" : returnNullStringIfNotDefined(integrations, @"c4"),
                           @"c6" : returnNullStringIfNotDefined(integrations, @"c6")


    };
    [self.streamAnalytics notifyBufferStartWithPosition:playPosition labels:map];
    SEGLog(@"[[SCORStreamingAnalytics streamAnalytics] notifyBufferStartWithPosition: %ld labels: %@]", playPosition, map);
}

- (void)videoPlaybackBufferCompleted:(NSDictionary *)properties withOptions:(NSDictionary *)integrations
{
    long playPosition = [properties[@"play_position"] longValue];

    NSDictionary *map = @{ @"ns_st_ci" : properties[@"asset_id"],
                           @"ns_st_ad" : properties[@"ad_type"],
                           @"ns_st_cl" : properties[@"total_length"],
                           @"ns_st_mp" : properties[@"video_player"],
                           @"ns_st_vo" : properties[@"sound"],
                           @"c3" : returnNullStringIfNotDefined(integrations, @"c3"),
                           @"c4" : returnNullStringIfNotDefined(integrations, @"c4"),
                           @"c6" : returnNullStringIfNotDefined(integrations, @"c6")


    };

    [self.streamAnalytics notifyBufferStopWithPosition:playPosition labels:map];
    SEGLog(@"[[SCORStreamingAnalytics streamAnalytics] notifyBufferStopWithPosition:%ld labels:%@]", playPosition, map);
}


- (void)videoPlaybackSeekStarted:(NSDictionary *)properties withOptions:(NSDictionary *)integrations
{
    long playPosition = [properties[@"play_position"] longValue];

    NSDictionary *map = @{ @"ns_st_ci" : properties[@"asset_id"],
                           @"ns_st_ad" : properties[@"ad_type"],
                           @"ns_st_cl" : properties[@"total_length"],
                           @"ns_st_mp" : properties[@"video_player"],
                           @"ns_st_vo" : properties[@"sound"],
                           @"c3" : returnNullStringIfNotDefined(integrations, @"c3"),
                           @"c4" : returnNullStringIfNotDefined(integrations, @"c4"),
                           @"c6" : returnNullStringIfNotDefined(integrations, @"c6")
    };

    [self.streamAnalytics notifySeekStartWithPosition:playPosition labels:map];
    SEGLog(@"[[SCORStreamAnalytics streamAnalytics] notifySeekStartWithPosition:%ld labels:%@", playPosition, map);
}

- (void)videoPlaybackSeekCompleted:(NSDictionary *)properties withOptions:(NSDictionary *)integrations
{
    long playPostition = [properties[@"play_position"] longValue];

    NSDictionary *map = @{
        @"ns_st_ci" : properties[@"asset_id"],
        @"ns_st_ad" : properties[@"ad_type"],
        @"ns_st_cl" : properties[@"total_length"],
        @"ns_st_mp" : properties[@"video_player"],
        @"ns_st_vo" : properties[@"sound"],
        @"c3" : returnNullStringIfNotDefined(integrations, @"c3"),
        @"c4" : returnNullStringIfNotDefined(integrations, @"c4"),
        @"c6" : returnNullStringIfNotDefined(integrations, @"c6")
    };
    [self.streamAnalytics notifySeekStartWithPosition:playPostition labels:map];
    SEGLog(@"[[SCORStreamingAnalytics streamAnalytics] notifySeekStartWithPosition:%ld labels:%@", playPostition, map);
}


- (void)videoPlaybackResumed:(NSDictionary *)properties withOptions:(NSDictionary *)integrations
{
    long playPosition = [properties[@"play_position"] longValue];

    NSDictionary *map = @{ @"ns_st_ci" : properties[@"asset_id"],
                           @"ns_st_ad" : properties[@"ad_type"],
                           @"ns_st_cl" : properties[@"total_length"],
                           @"ns_st_mp" : properties[@"video_player"],
                           @"ns_st_vo" : properties[@"sound"],
                           @"c3" : returnNullStringIfNotDefined(integrations, @"c3"),
                           @"c4" : returnNullStringIfNotDefined(integrations, @"c4"),
                           @"c6" : returnNullStringIfNotDefined(integrations, @"c6")


    };

    [self.streamAnalytics notifyPlayWithPosition:playPosition labels:map];
    SEGLog(@"[[SCORStreamingAnalytics streamAnalytics] notifyPlayWithPosition:&ld labels: %@]", playPosition, map);
}

#pragma Content Events

- (void)videoContentStarted:(NSDictionary *)properties withOptions:(NSDictionary *)integrations
{
    long playPosition = [properties[@"play_position"] longValue];

    NSDictionary *map = @{ @"ns_st_ci" : properties[@"asset_id"],
                           @"ns_st_ep" : properties[@"title"],
                           @"ns_st_ge" : properties[@"keywords"],
                           @"ns_st_sn" : properties[@"season"],
                           @"ns_st_en" : properties[@"episode"],
                           @"ns_st_ge" : properties[@"genre"],
                           @"ns_st_pr" : properties[@"program"],
                           @"ns_st_pu" : properties[@"channel"],
                           @"ns_st_ce" : properties[@"full_episode"],
                           @"c3" : returnNullStringIfNotDefined(integrations, @"c3"),
                           @"c4" : returnNullStringIfNotDefined(integrations, @"c4"),
                           @"c6" : returnNullStringIfNotDefined(integrations, @"c6")

    };


    [self.streamAnalytics notifyPlayWithLabels:map];
    SEGLog(@"[[SCORStreamingAnalytics streamAnalytics] notifyPlayWithLabels: %@", map);
}

- (void)videoContentPlaying:(NSDictionary *)properties withOptions:(NSDictionary *)integrations
{
    long playPosition = [properties[@"play_position"] longValue];

    NSDictionary *map = @{ @"ns_st_ci" : properties[@"asset_id"],
                           @"ns_st_ep" : properties[@"title"],
                           @"ns_st_ge" : properties[@"keywords"],
                           @"ns_st_sn" : properties[@"season"],
                           @"ns_st_en" : properties[@"episode"],
                           @"ns_st_ge" : properties[@"genre"],
                           @"ns_st_pr" : properties[@"program"],
                           @"ns_st_pu" : properties[@"channel"],
                           @"ns_st_ce" : properties[@"full_episode"],
                           @"c3" : returnNullStringIfNotDefined(integrations, @"c3"),
                           @"c4" : returnNullStringIfNotDefined(integrations, @"c4"),
                           @"c6" : returnNullStringIfNotDefined(integrations, @"c6")

    };

    [self.streamAnalytics notifyPlayWithPosition:playPosition labels:map];
    SEGLog(@"[[SCORStreamingAnalytics streamAnalytics] notifyPlayWithPosition: %ld labels: %@", playPosition, map);
}


- (void)videoContentCompleted:(NSDictionary *)properties withOptions:(NSDictionary *)integrations
{
    long playPosition = [properties[@"play_position"] longValue];

    NSDictionary *map = @{ @"ns_st_ad" : properties[@"type"],
                           @"ns_st_pu" : properties[@"publisher"],
                           @"ns_st_cl" : properties[@"total_length"],
                           @"c3" : returnNullStringIfNotDefined(integrations, @"c3"),
                           @"c4" : returnNullStringIfNotDefined(integrations, @"c4"),
                           @"c6" : returnNullStringIfNotDefined(integrations, @"c6")

    };

    [self.streamAnalytics notifyEndWithPosition:playPosition labels:map];
    SEGLog(@"[[SCORStreamingAnalytics streamAnalytics] notifyEndWithPosition:%ld labels:%@", playPosition, map);
}

#pragma Ad Events


- (void)videoAdStarted:(NSDictionary *)properties withOptions:(NSDictionary *)integrations
{
    long playPosition = [properties[@"play_position"] longValue];

    NSDictionary *map = @{ @"ns_st_ami" : properties[@"asset_id"],
                           @"ns_st_ad" : properties[@"type"],
                           @"ns_st_cl" : properties[@"total_length"],
                           @"ns_st_amt" : properties[@"title"],
                           @"c3" : returnNullStringIfNotDefined(integrations, @"c3"),
                           @"c4" : returnNullStringIfNotDefined(integrations, @"c4"),
                           @"c6" : returnNullStringIfNotDefined(integrations, @"c6")

    };

    [self.streamAnalytics notifyPlayWithPosition:playPosition labels:map];
    SEGLog(@"[[SCORStreamingAnalytics streamAnalytics] notifyPlayWithPosition:%ld labels:%@", playPosition, map);
}

- (void)videoAdPlaying:(NSDictionary *)properties withOptions:(NSDictionary *)integrations
{
    long playPosition = [properties[@"play_position"] longValue];

    NSDictionary *map = @{ @"ns_st_ami" : properties[@"asset_id"],
                           @"ns_st_ad" : properties[@"type"],
                           @"ns_st_cl" : properties[@"total_length"],
                           @"ns_st_amt" : properties[@"title"],
                           @"c3" : returnNullStringIfNotDefined(integrations, @"c3"),
                           @"c4" : returnNullStringIfNotDefined(integrations, @"c4"),
                           @"c6" : returnNullStringIfNotDefined(integrations, @"c6")

    };

    [self.streamAnalytics notifyPlayWithPosition:playPosition labels:map];
    SEGLog(@"[[SCORStreamingAnalytics streamAnalytics] notifyPlayWithPosition:%ld map:%@", playPosition, map);
}

- (void)videoAdCompleted:(NSDictionary *)properties withOptions:(NSDictionary *)integrations
{
    long playPosition = [properties[@"play_position"] longValue];

    NSDictionary *map = @{ @"ns_st_ami" : properties[@"asset_id"],
                           @"ns_st_ad" : properties[@"type"],
                           @"ns_st_cl" : properties[@"total_length"],
                           @"ns_st_amt" : properties[@"title"],
                           @"c3" : returnNullStringIfNotDefined(integrations, @"c3"),
                           @"c4" : returnNullStringIfNotDefined(integrations, @"c4"),
                           @"c6" : returnNullStringIfNotDefined(integrations, @"c6")

    };

    [self.streamAnalytics notifyEndWithPosition:playPosition labels:map];
    SEGLog(@"[[SCORStreamingAnalytics streamAnalytics] notifyEndWithPosition:%ld labels:%@", playPosition, map);
}

@end
