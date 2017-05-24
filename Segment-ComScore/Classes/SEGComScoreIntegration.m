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

    if ([payload.event isEqualToString:@"Video Playback Interrupted"]) {
        [self videoPlaybackInterrupted:payload.properties withOptions:payload.integrations];
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

NSString *returnFullScreenStatus(NSDictionary *src, NSString *key)
{
    NSNumber *value = [src valueForKey:key];
    if (value == @YES) {
        return @"full";
    } else if (value == @NO) {
        return @"norm";
    }
}

// comScore expects bitrate to converted from KBPS be BPS
NSNumber *convertFromKBPSToBPS(NSDictionary *src, NSString *key)
{
    NSNumber *value = [src valueForKey:key];
    if ([value isKindOfClass:[NSNumber class]]) {
        int KBPS = [value intValue];
        int BPS = KBPS * 1000;
        return [NSNumber numberWithInt:BPS];
    }
    return nil;
}

NSString *defaultAdType(NSDictionary *src, NSString *key)
{
    NSString *value = [src valueForKey:key];

    if ((value == @"pre-roll") || (value == @"mid-roll") || (value == @"post-roll")) {
        return value;
    } else {
        return @"1";
    }
}

// comScore expects total to be milliseconds
NSNumber *convertFromSecondsToMilliseconds(NSDictionary *src, NSString *key)
{
    NSNumber *value = [src valueForKey:key];
    if ([value isKindOfClass:[NSNumber class]]) {
        int seconds = [value intValue];
        int milliseconds = seconds * 1000;
        return [NSNumber numberWithInt:milliseconds];
    }
    return nil;
}


#pragma Playback Events

NSDictionary *returnMappedPlaybackProperties(NSDictionary *properties, NSDictionary *integrations)
{
    NSDictionary *integration = [integrations valueForKey:@"comScore"];

    NSDictionary *map = @{ @"ns_st_ci" : properties[@"content_asset_id"] ?: @"*null",
                           @"ns_st_ad" : properties[@"ad_type"] ?: @"*null",
                           @"ns_st_mp" : properties[@"video_player"] ?: @"*null",
                           @"ns_st_vo" : properties[@"sound"] ?: @"*null",
                           @"ns_st_br" : convertFromKBPSToBPS(properties, @"bitrate"),
                           @"ns_st_ws" : returnFullScreenStatus(properties, @"full_screen"),
                           @"c3" : integration[@"c3"] ?: @"*null",
                           @"c4" : integration[@"c4"] ?: @"*null",
                           @"c6" : integration[@"c6"] ?: @"*null"

    };
    return map;
}

- (void)videoPlaybackStarted:(NSDictionary *)properties withOptions:(NSDictionary *)integrations
{
    self.streamAnalytics = [self.streamingAnalyticsFactory create];

    NSDictionary *integration = [integrations valueForKey:@"comScore"];


    NSDictionary *map = @{
        @"ns_st_ci" : properties[@"content_asset_id"] ?: @"*null",
        @"ns_st_ad" : properties[@"ad_type"] ?: @"*null",
        @"ns_st_mp" : properties[@"video_player"] ?: @"*null",
        @"c3" : integration[@"c3"] ?: @"*null",
        @"c4" : integration[@"c4"] ?: @"*null",
        @"c6" : integration[@"c6"] ?: @"*null"

    };

    [self.streamAnalytics createPlaybackSessionWithLabels:map];
    SEGLog(@"[[SCORStreamingAnalytics streamAnalytics] createPlaybackSessionWithLabels: %@]", map);
}


- (void)videoPlaybackPaused:(NSDictionary *)properties withOptions:(NSDictionary *)integrations
{
    NSDictionary *map = returnMappedPlaybackProperties(properties, integrations);

    if ([properties[@"position"] longValue]) {
        long playPosition = [properties[@"position"] longValue];
        [self.streamAnalytics notifyPauseWithPosition:playPosition labels:map];
        SEGLog(@"[[SCORStreamingAnalytics streamAnalytics] notifyEndWithPosition:%ld labels:%@]", playPosition, map);
    } else {
        [self.streamAnalytics notifyPauseWithLabels:map];
        SEGLog(@"[[SCORStreamingAnalytics streamAnalytics] notifyPauseWithLabels:%@]", map);
    }
}

- (void)videoPlaybackInterrupted:(NSDictionary *)properties withOptions:(NSDictionary *)integrations
{
    NSDictionary *map = returnMappedPlaybackProperties(properties, integrations);

    if ([properties[@"position"] longValue]) {
        long playPosition = [properties[@"position"] longValue];
        [self.streamAnalytics notifyPauseWithPosition:playPosition labels:map];
        SEGLog(@"[[SCORStreamingAnalytics streamAnalytics] notifyEndWithPosition:%ld labels:%@]", playPosition, map);
    } else {
        [self.streamAnalytics notifyPauseWithLabels:map];
        SEGLog(@"[[SCORStreamingAnalytics streamAnalytics] notifyPauseWithLabels:%@]", map);
    }
}

- (void)videoPlaybackBufferStarted:(NSDictionary *)properties withOptions:(NSDictionary *)integrations
{
    NSDictionary *map = returnMappedPlaybackProperties(properties, integrations);
    if ([properties[@"position"] longValue]) {
        long playPosition = [properties[@"position"] longValue];
        [self.streamAnalytics notifyBufferStartWithPosition:playPosition labels:map];
        SEGLog(@"[[SCORStreamingAnalytics streamAnalytics] notifyBufferStartWithPosition: %ld labels: %@]", playPosition, map);
    } else {
        [self.streamAnalytics notifyBufferStartWithLabels:map];
        SEGLog(@"[[SCORStreamingAnalytics streamAnalytics] notifyBufferStartWithLabels: %@]", map);
    }
}

- (void)videoPlaybackBufferCompleted:(NSDictionary *)properties withOptions:(NSDictionary *)integrations
{
    NSDictionary *map = returnMappedPlaybackProperties(properties, integrations);
    if ([properties[@"position"] longValue]) {
        long playPosition = [properties[@"position"] longValue];
        [self.streamAnalytics notifyBufferStopWithPosition:playPosition labels:map];
        SEGLog(@"[[SCORStreamingAnalytics streamAnalytics] notifyBufferStopWithPosition:%ld labels:%@]", playPosition, map);
    } else {
        [self.streamAnalytics notifyBufferStopWithLabels:map];
        SEGLog(@"[[SCORStreamingAnalytics streamAnalytics] notifyBufferStopWithLabels:%@]", map);
    }
}


- (void)videoPlaybackSeekStarted:(NSDictionary *)properties withOptions:(NSDictionary *)integrations
{
    NSDictionary *map = returnMappedPlaybackProperties(properties, integrations);
    if ([properties[@"seek_position"] longValue]) {
        long seekPosition = [properties[@"seek_position"] longValue];
        [self.streamAnalytics notifySeekStartWithPosition:seekPosition labels:map];
        SEGLog(@"[[SCORStreamAnalytics streamAnalytics] notifySeekStartWithPosition:%ld labels:%@", seekPosition, map);
    } else {
        [self.streamAnalytics notifySeekStartWithLabels:map];
        SEGLog(@"[[SCORStreamAnalytics streamAnalytics] notifySeekStartWithLabels:%@", map);
    }
}

- (void)videoPlaybackSeekCompleted:(NSDictionary *)properties withOptions:(NSDictionary *)integrations
{
    NSDictionary *map = returnMappedPlaybackProperties(properties, integrations);
    if ([properties[@"seek_position"] longValue]) {
        long seekPosition = [properties[@"seek_position"] longValue];
        [self.streamAnalytics notifySeekStartWithPosition:seekPosition labels:map];
        SEGLog(@"[[SCORStreamingAnalytics streamAnalytics] notifySeekStartWithPosition:%ld labels:%@", seekPosition, map);
    } else {
        [self.streamAnalytics notifySeekStartWithLabels:map];
        SEGLog(@"[[SCORStreamingAnalytics streamAnalytics] notifySeekStartWithLabels:%@", map);
    }
}


- (void)videoPlaybackResumed:(NSDictionary *)properties withOptions:(NSDictionary *)integrations
{
    NSDictionary *map = returnMappedPlaybackProperties(properties, integrations);
    if ([properties[@"position"] longValue]) {
        long playPosition = [properties[@"position"] longValue];
        [self.streamAnalytics notifyPlayWithPosition:playPosition labels:map];
        SEGLog(@"[[SCORStreamingAnalytics streamAnalytics] notifyPlayWithPosition:&ld labels: %@]", playPosition, map);
    } else {
        [self.streamAnalytics notifyPlayWithLabels:map];
        SEGLog(@"[[SCORStreamingAnalytics streamAnalytics] notifyPlayWithLabels: %@]", map);
    }
}

#pragma Content Events

NSDictionary *returnMappedContentProperties(NSDictionary *properties, NSDictionary *integrations)
{
    NSDictionary *integration = [integrations valueForKey:@"comScore"];

    NSDictionary *map = @{ @"ns_st_ci" : properties[@"asset_id"] ?: @"*null",
                           @"ns_st_ep" : properties[@"title"] ?: @"*null",
                           @"ns_st_sn" : properties[@"season"] ?: @"*null",
                           @"ns_st_en" : properties[@"episode"] ?: @"*null",
                           @"ns_st_ge" : properties[@"genre"] ?: @"*null",
                           @"ns_st_pr" : properties[@"program"] ?: @"*null",
                           @"ns_st_ce" : properties[@"full_episode"] ?: @"*null",
                           @"ns_st_cl" : convertFromSecondsToMilliseconds(properties, @"total_length"),
                           @"ns_st_pu" : properties[@"publisher"] ?: @"*null",
                           @"ns_st_st" : properties[@"channel"] ?: @"*null",
                           @"ns_st_ddt" : integration[@"digitalAirdate"] ?: @"*null",
                           @"ns_st_tdt" : integration[@"tvAirdate"] ?: @"*null",
                           @"c3" : integration[@"c3"] ?: @"*null",
                           @"c4" : integration[@"c4"] ?: @"*null",
                           @"c6" : integration[@"c6"] ?: @"*null",
                           @"ns_st_ct" : integration[@"contentClassificationType"] ?: @"vc00"

    };
    return map;
}

- (void)videoContentStarted:(NSDictionary *)properties withOptions:(NSDictionary *)integrations
{
    NSDictionary *map = returnMappedContentProperties(properties, integrations);

    if ([properties[@"position"] longValue]) {
        long playPosition = [properties[@"position"] longValue];
        [[self.streamAnalytics playbackSession] setAssetWithLabels:map];
        [self.streamAnalytics notifyPlayWithPosition:playPosition];
        SEGLog(@"[[SCORStreamingAnalytics streamAnalytics] notifyPlayWithPosition:%ld; [[SCORStreamingAnalytics playbackSession] setAssetWithLabels:%@", playPosition, map);
    } else {
        [[self.streamAnalytics playbackSession] setAssetWithLabels:map];
        [self.streamAnalytics notifyPlay];
        SEGLog(@"[[SCORStreamingAnalytics streamAnalytics] notifyPlay; [[SCORStreamingAnalytics playbackSession] setAssetWithLabels:%@", map);
    }
}

- (void)videoContentPlaying:(NSDictionary *)properties withOptions:(NSDictionary *)integrations
{
    NSDictionary *map = returnMappedContentProperties(properties, integrations);

    if ([properties[@"position"] longValue]) {
        long playPosition = [properties[@"position"] longValue];
        [[self.streamAnalytics playbackSession] setAssetWithLabels:map];
        [self.streamAnalytics notifyPlayWithPosition:playPosition];
        SEGLog(@"[[SCORStreamingAnalytics streamAnalytics] notifyPlayWithPosition:%ld; [[SCORStreamingAnalytics playbackSession] setAssetWithLabels:%@", playPosition, map);
    } else {
        [[self.streamAnalytics playbackSession] setAssetWithLabels:map];
        [self.streamAnalytics notifyPlay];
        SEGLog(@"[[SCORStreamingAnalytics streamAnalytics] notifyPlay; [[SCORStreamingAnalytics playbackSession] setAssetWithLabels:%@", map);
    }
}


- (void)videoContentCompleted:(NSDictionary *)properties withOptions:(NSDictionary *)integrations
{
    NSDictionary *map = returnMappedContentProperties(properties, integrations);

    if ([properties[@"position"] longValue]) {
        long playPosition = [properties[@"position"] longValue];
        [[self.streamAnalytics playbackSession] setAssetWithLabels:map];
        [self.streamAnalytics notifyEndWithPosition:playPosition];
        SEGLog(@"[[SCORStreamingAnalytics streamAnalytics] notifyPlayWithPosition:%ld; [[SCORStreamingAnalytics playbackSession] setAssetWithLabels:%@", playPosition, map);
    } else {
        [[self.streamAnalytics playbackSession] setAssetWithLabels:map];
        [self.streamAnalytics notifyEnd];
        SEGLog(@"[[SCORStreamingAnalytics streamAnalytics] notifyEnd; [[SCORStreamingAnalytics playbackSession] setAssetWithLabels:%@", map);
    }
}

#pragma Ad Events

NSDictionary *returnMappedAdProperties(NSDictionary *properties, NSDictionary *integrations)
{
    NSDictionary *integration = [integrations valueForKey:@"comScore"];

    NSDictionary *map = @{ @"ns_st_ami" : properties[@"asset_id"] ?: @"*null",
                           @"ns_st_ad" : defaultAdType(properties, @"type"),
                           @"ns_st_cl" : convertFromSecondsToMilliseconds(properties, @"total_length"),
                           @"ns_st_amt" : properties[@"title"] ?: @"*null",
                           @"c3" : integration[@"c3"] ?: @"*null",
                           @"c4" : integration[@"c4"] ?: @"*null",
                           @"c6" : integration[@"c6"] ?: @"*null",
                           @"ns_st_ct" : integration[@"adClassificationType"] ?: @"va00"

    };
    return map;
}

- (void)videoAdStarted:(NSDictionary *)properties withOptions:(NSDictionary *)integrations
{
    NSDictionary *map = returnMappedAdProperties(properties, integrations);

    if ([properties[@"position"] longValue]) {
        long playPosition = [properties[@"position"] longValue];
        [[self.streamAnalytics playbackSession] setAssetWithLabels:map];
        [self.streamAnalytics notifyPlayWithPosition:playPosition];
        SEGLog(@"[[SCORStreamingAnalytics streamAnalytics] notifyPlayWithPosition:%ld ; [[SCORStreamingAnalytics playbackSession] setAssetWithLabels:%@", playPosition, map);
    } else {
        [[self.streamAnalytics playbackSession] setAssetWithLabels:map];
        [self.streamAnalytics notifyPlay];
        SEGLog(@"[[SCORStreamingAnalytics streamAnalytics] notifyPlay; [[SCORStreamingAnalytics playbackSession] setAssetWithLabels:%@", map);
    }
}

- (void)videoAdPlaying:(NSDictionary *)properties withOptions:(NSDictionary *)integrations
{
    NSDictionary *map = returnMappedAdProperties(properties, integrations);

    if ([properties[@"position"] longValue]) {
        long playPosition = [properties[@"position"] longValue];
        [[self.streamAnalytics playbackSession] setAssetWithLabels:map];
        [self.streamAnalytics notifyPlayWithPosition:playPosition];
        SEGLog(@"[[SCORStreamingAnalytics streamAnalytics] notifyPlayWithPosition:%ld ; [[SCORStreamingAnalytics playbackSession] setAssetWithLabels:%@", playPosition, map);
    } else {
        [[self.streamAnalytics playbackSession] setAssetWithLabels:map];
        [self.streamAnalytics notifyPlay];
        SEGLog(@"[[SCORStreamingAnalytics streamAnalytics] notifyPlay; [[SCORStreamingAnalytics playbackSession] setAssetWithLabels:%@", map);
    }
}

- (void)videoAdCompleted:(NSDictionary *)properties withOptions:(NSDictionary *)integrations
{
    NSDictionary *map = returnMappedAdProperties(properties, integrations);

    if ([properties[@"position"] longValue]) {
        long playPosition = [properties[@"position"] longValue];
        [[self.streamAnalytics playbackSession] setAssetWithLabels:map];
        [self.streamAnalytics notifyEndWithPosition:playPosition];
        SEGLog(@"[[SCORStreamingAnalytics streamAnalytics] notifyEndWithPosition:%ld ; [[SCORStreamingAnalytics playbackSession] setAssetWithLabels:%@", playPosition, map);
    } else {
        [[self.streamAnalytics playbackSession] setAssetWithLabels:map];
        [self.streamAnalytics notifyEnd];
        SEGLog(@"[[SCORStreamingAnalytics streamAnalytics] notifyEnd; [[SCORStreamingAnalytics playbackSession] setAssetWithLabels:%@", map);
    }
}

@end
