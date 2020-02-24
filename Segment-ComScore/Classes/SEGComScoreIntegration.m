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

@interface SCORStreamingConfiguration(Private)
@property(copy) NSDictionary *labels;
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
            builder.secureTransmissionEnabled = [(NSNumber *)[self.settings objectForKey:@"useHTTPS"] boolValue];
        }];

        NSInteger usagePropertyAutoUpdateMode = SCORUsagePropertiesAutoUpdateModeDisabled;
        if ([(NSNumber *)[self.settings objectForKey:@"autoUpdate"] boolValue] && [(NSNumber *)[self.settings objectForKey:@"foregroundOnly"] boolValue]) {
            usagePropertyAutoUpdateMode = SCORUsagePropertiesAutoUpdateModeForegroundOnly;
        } else if ([(NSNumber *)[self.settings objectForKey:@"autoUpdate"] boolValue]) {
            usagePropertyAutoUpdateMode = SCORUsagePropertiesAutoUpdateModeForegroundAndBackground;
        }
        SCORAnalytics.configuration.usagePropertiesAutoUpdateMode = usagePropertyAutoUpdateMode;

        SCORAnalytics.configuration.usagePropertiesAutoUpdateInterval = [settings[@"autoUpdateInterval"] intValue];

        SCORAnalytics.configuration.liveTransmissionMode = SCORLiveTransmissionModeLan;

        SCORAnalytics.configuration.applicationName = settings[@"appName"];

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
        if ([self isDataValid:data]) {
            [mapped setObject:[NSString stringWithFormat:@"%@", data] forKey:key];
        }
    }];

    return [mapped copy];
}

+(BOOL)isDataValid:(id)data {
    return (!![data isKindOfClass:[NSString class]] ||
            !![data isKindOfClass:[NSArray class]] ||
            !![data isKindOfClass:[NSNumber class]]);
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


NSDictionary *coerceToString(NSDictionary *map)
{
    NSMutableDictionary *newMap = [NSMutableDictionary dictionaryWithDictionary:map];

    for (id key in map) {
        id value = [map objectForKey:key];
        if (![value isKindOfClass:[NSString class]]) {
            [newMap setObject:[NSString stringWithFormat:@"%@", value] forKey:key];
        }
    }

    return [newMap copy];
}

NSString *returnFullScreenStatus(NSDictionary *src, NSString *key)
{
    NSNumber *value = [src valueForKey:key];
    if ([value isEqual:@YES]) {
        return @"full";
    }
    return @"norm";
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

    if (([value isEqualToString:@"pre-roll"]) || ([value isEqualToString:@"mid-roll"]) || ([value isEqualToString:@"post-roll"])) {
        return value;
    }
    return @"1";
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
    NSDictionary *integration = [integrations valueForKey:@"com-score"];

    NSDictionary *map = @{ @"ns_st_mp" : properties[@"video_player"] ?: @"*null",
                           @"ns_st_vo" : properties[@"sound"] ?: @"*null",
                           @"ns_st_br" : convertFromKBPSToBPS(properties, @"bitrate") ?: @"*null",
                           @"ns_st_ws" : returnFullScreenStatus(properties, @"full_screen") ?: @"norm",
                           @"c3" : integration[@"c3"] ?: @"*null",
                           @"c4" : integration[@"c4"] ?: @"*null",
                           @"c6" : integration[@"c6"] ?: @"*null"

    };
    return coerceToString(map);
}

- (void)videoPlaybackStarted:(NSDictionary *)properties withOptions:(NSDictionary *)integrations
{
    self.streamAnalytics = [self.streamingAnalyticsFactory create];

    NSDictionary *map = @{
        @"ns_st_mp" : properties[@"video_player"] ?: @"*null",
        @"ns_st_ci" : properties[@"content_asset_id"] ?: @"0"
    };

    [self.streamAnalytics createPlaybackSession];

    SCORStreamingContentMetadata *playbackMetaData = [self instantiateContentMetaData:map];

    [self.streamAnalytics.configuration addLabels:map];
    [self.streamAnalytics setMetadata:playbackMetaData];

    SEGLog(@"[[SCORStreamingAnalytics streamAnalytics] createPlaybackSessionWithLabels: %@]", map);
}


- (void)videoPlaybackPaused:(NSDictionary *)properties withOptions:(NSDictionary *)integrations
{
    NSDictionary *map = returnMappedPlaybackProperties(properties, integrations);
    SCORStreamingContentMetadata *playbackMetaData = [self instantiateContentMetaData:map];

    // [self.streamAnalytics.configuration addLabels:map]; TBD if needed
    [self.streamAnalytics setMetadata:playbackMetaData];

    [self.streamAnalytics notifyPause];
    SEGLog(@"[[SCORStreamingAnalytics streamAnalytics] notifyPause]");
}

- (void)videoPlaybackInterrupted:(NSDictionary *)properties withOptions:(NSDictionary *)integrations
{
    NSDictionary *map = returnMappedPlaybackProperties(properties, integrations);
    SCORStreamingContentMetadata *playbackMetaData = [self instantiateContentMetaData:map];

    [self.streamAnalytics setMetadata:playbackMetaData];

    [self.streamAnalytics notifyPause];
    SEGLog(@"[[SCORStreamingAnalytics streamAnalytics] notifyPause]");
}

- (void)videoPlaybackBufferStarted:(NSDictionary *)properties withOptions:(NSDictionary *)integrations
{
    NSDictionary *map = returnMappedPlaybackProperties(properties, integrations);
    SCORStreamingContentMetadata *playbackMetaData = [self instantiateContentMetaData:map];

    [self.streamAnalytics setMetadata:playbackMetaData];

    [self movePosition:properties];
    [self.streamAnalytics notifyBufferStart];
    SEGLog(@"[[SCORStreamingAnalytics streamAnalytics] notifyBufferStart]");
}

- (void)videoPlaybackBufferCompleted:(NSDictionary *)properties withOptions:(NSDictionary *)integrations
{
    NSDictionary *map = returnMappedPlaybackProperties(properties, integrations);
    SCORStreamingContentMetadata *playbackMetaData = [self instantiateContentMetaData:map];

    [self.streamAnalytics setMetadata:playbackMetaData];

    [self movePosition:properties];
    [self.streamAnalytics notifyBufferStop];
    SEGLog(@"[[SCORStreamingAnalytics streamAnalytics] notifyBufferStop]");
}

- (void)videoPlaybackSeekStarted:(NSDictionary *)properties withOptions:(NSDictionary *)integrations
{
    NSDictionary *map = returnMappedPlaybackProperties(properties, integrations);
    SCORStreamingContentMetadata *playbackMetaData = [self instantiateContentMetaData:map];

    [self.streamAnalytics setMetadata:playbackMetaData];

    [self seekPosition:properties];
    [self.streamAnalytics notifySeekStart];
    SEGLog(@"[[SCORStreamAnalytics streamAnalytics] notifySeekStart]");
}

- (void)videoPlaybackSeekCompleted:(NSDictionary *)properties withOptions:(NSDictionary *)integrations
{
    NSDictionary *map = returnMappedPlaybackProperties(properties, integrations);
    SCORStreamingContentMetadata *playbackMetaData = [self instantiateContentMetaData:map];

    [self.streamAnalytics setMetadata:playbackMetaData];

    [self seekPosition:properties];
    [self.streamAnalytics notifyPlay];
    SEGLog(@"[[SCORStreamingAnalytics streamAnalytics] notifyPlay]");
}


- (void)videoPlaybackResumed:(NSDictionary *)properties withOptions:(NSDictionary *)integrations
{
    NSDictionary *map = returnMappedPlaybackProperties(properties, integrations);
    SCORStreamingContentMetadata *playbackMetaData = [self instantiateContentMetaData:map];

    [self.streamAnalytics setMetadata:playbackMetaData];

    [self movePosition:properties];
    [self.streamAnalytics notifyPlay];
    SEGLog(@"[[SCORStreamingAnalytics streamAnalytics] notifyPlay]");
}

#pragma Content Events

NSDictionary *returnMappedContentProperties(NSDictionary *properties, NSDictionary *integrations)
{
    NSDictionary *integration = [integrations valueForKey:@"com-score"];

    NSDictionary *map = @{ @"ns_st_ci" : properties[@"asset_id"] ?: @"0",
                           @"ns_st_ep" : properties[@"title"] ?: @"*null",
                           @"ns_st_sn" : properties[@"season"] ?: @"*null",
                           @"ns_st_en" : properties[@"episode"] ?: @"*null",
                           @"ns_st_ge" : properties[@"genre"] ?: @"*null",
                           @"ns_st_pr" : properties[@"program"] ?: @"*null",
                           @"ns_st_pn" : properties[@"pod_id"] ?: @"*null",
                           @"ns_st_ce" : properties[@"full_episode"] ?: @"*null",
                           @"ns_st_cl" : convertFromSecondsToMilliseconds(properties, @"total_length") ?: @"*null",
                           @"ns_st_pu" : properties[@"publisher"] ?: @"*null",
                           @"ns_st_st" : properties[@"channel"] ?: @"*null",
                           @"ns_st_ddt" : integration[@"digitalAirdate"] ?: @"*null",
                           @"ns_st_tdt" : integration[@"tvAirdate"] ?: @"*null",
                           @"c3" : integration[@"c3"] ?: @"*null",
                           @"c4" : integration[@"c4"] ?: @"*null",
                           @"c6" : integration[@"c6"] ?: @"*null",
                           @"ns_st_ct" : integration[@"contentClassificationType"] ?: @"vc00"

    };

    return coerceToString(map);
}

- (void)videoContentStarted:(NSDictionary *)properties withOptions:(NSDictionary *)integrations
{
    NSDictionary *map = returnMappedContentProperties(properties, integrations);
    SCORStreamingContentMetadata *contentMetadata = [self instantiateContentMetaData:map];

    [self.streamAnalytics.configuration addLabels:map];
    [self.streamAnalytics setMetadata:contentMetadata];

    SEGLog(@"[SCORStreamingAnalytics setMetadata:%@", contentMetadata);

    [self movePosition:properties];
    [self.streamAnalytics notifyPlay];
    SEGLog(@"[[SCORStreamingAnalytics streamAnalytics] notifyPlay;");
}

- (void)videoContentPlaying:(NSDictionary *)properties withOptions:(NSDictionary *)integrations
{
    NSDictionary *contentMap = returnMappedContentProperties(properties, integrations);
    SCORStreamingContentMetadata *contentMetadata = [self instantiateContentMetaData:contentMap];

    // The presence of ns_st_ad on the StreamingAnalytics's asset means that we just exited an ad break, so
    // we need to call setAsset with the content metadata.  If ns_st_ad is not present, that means the last
    // observed event was related to content, in which case a setAsset call should not be made (because asset
    // did not change).
    NSDictionary *labels = self.streamAnalytics.configuration.labels;
    NSString *previousAdAssetId = [labels objectForKey:@"ns_st_ad"];

    if (previousAdAssetId) {
        [self.streamAnalytics setMetadata:contentMetadata];
    }
    
    [self movePosition:properties];

    [self.streamAnalytics notifyPlay];
    SEGLog(@"[[SCORStreamingAnalytics streamAnalytics] notifyPlay]");
}


- (void)videoContentCompleted:(NSDictionary *)properties withOptions:(NSDictionary *)integrations
{
    [self.streamAnalytics notifyEnd];
    SEGLog(@"[[SCORStreamingAnalytics streamAnalytics] notifyEnd]");
}

#pragma Ad Events

NSDictionary *returnMappedAdProperties(NSDictionary *properties, NSDictionary *integrations)
{
    NSDictionary *integration = [integrations valueForKey:@"com-score"];

    NSDictionary *map = @{ @"ns_st_ami" : properties[@"asset_id"] ?: @"*null",
                           @"ns_st_ad" : defaultAdType(properties, @"type") ?: @"1",
                           @"ns_st_cl" : convertFromSecondsToMilliseconds(properties, @"total_length") ?: @"*null",
                           @"ns_st_amt" : properties[@"title"] ?: @"*null",
                           @"ns_st_pu" : properties[@"publisher"] ?: @"*null",
                           @"c3" : integration[@"c3"] ?: @"*null",
                           @"c4" : integration[@"c4"] ?: @"*null",
                           @"c6" : integration[@"c6"] ?: @"*null",
                           @"ns_st_ct" : integration[@"adClassificationType"] ?: @"va00"

    };

    return coerceToString(map);
}

- (void)videoAdStarted:(NSDictionary *)properties withOptions:(NSDictionary *)integrations
{
    NSDictionary *map = returnMappedAdProperties(properties, integrations);

    // The ID for content is not available on Ad Start events, however it will be available on the current
    // StreamingAnalytics's asset. This is because ns_st_ci will have already been set via asset_id in a
    // Content Started calls (if this is a mid or post-roll), or via content_asset_id on Video Playback
    // Started (if this is a pre-roll).
    NSDictionary *labels = self.streamAnalytics.configuration.labels;
    NSString *contentId = [labels objectForKey:@"ns_st_ci"] ?: @"0";

    NSMutableDictionary *mapWithContentId = [NSMutableDictionary dictionaryWithDictionary:map];
    [mapWithContentId setValue:contentId forKey:@"ns_st_ci"];

    SCORStreamingContentMetadata *contentMetadata = [self instantiateContentMetaData:mapWithContentId];
    NSString *adType = [properties valueForKey:@"type"];
    __block NSInteger setMediaType;
    if ([adType isEqualToString:@"pre-roll"]) {
        setMediaType = SCORStreamingAdvertisementTypeBrandedOnDemandPreRoll;
    } else if ([adType isEqualToString:@"mid-roll"]) {
        setMediaType = SCORStreamingAdvertisementTypeBrandedOnDemandMidRoll;
    } else if ([adType isEqualToString:@"post-roll"]) {
        setMediaType = SCORStreamingAdvertisementTypeBrandedOnDemandPostRoll;
    } else {
        setMediaType = SCORStreamingAdvertisementTypeOther;
    }

    SCORStreamingAdvertisementMetadata *advertisingMetaData = [SCORStreamingAdvertisementMetadata advertisementMetadataWithBuilderBlock:^(SCORStreamingAdvertisementMetadataBuilder *builder) {
        [builder setMediaType: setMediaType];
        [builder setCustomLabels: mapWithContentId];
        [builder setRelatedContentMetadata: contentMetadata];
    }];

    [self.streamAnalytics setMetadata:advertisingMetaData];

    [self movePosition: properties];
    [self.streamAnalytics notifyPlay];
    SEGLog(@"[[SCORStreamingAnalytics streamAnalytics] notifyPlay]");
}

- (void)videoAdPlaying:(NSDictionary *)properties withOptions:(NSDictionary *)integrations
{
    [self movePosition:properties];
    [self.streamAnalytics notifyPlay];
    SEGLog(@"[[SCORStreamingAnalytics streamAnalytics] notifyPlay]");
}

- (void)videoAdCompleted:(NSDictionary *)properties withOptions:(NSDictionary *)integrations
{
    [self movePosition:properties];
    [self.streamAnalytics notifyEnd];
    SEGLog(@"[[SCORStreamingAnalytics streamAnalytics] notifyEnd]");
}


#pragma mark - Helper functions

- (void)movePosition:(NSDictionary *)properties {
    if ([properties[@"position"] longValue]) {
        long playPosition = [properties[@"position"] longValue];
        if (self.streamAnalytics != NULL) {
            [self.streamAnalytics startFromPosition:playPosition];
        }
    }
}

- (void)seekPosition:(NSDictionary *)properties {
    if ([properties[@"seek_position"] longValue]) {
        long seekPosition = [properties[@"seek_position"] longValue];
        if (self.streamAnalytics != NULL) {
            [self.streamAnalytics startFromPosition:seekPosition];
        }

    }
}

- (SCORStreamingContentMetadata *)instantiateContentMetaData:(NSDictionary *)properties {

    SCORStreamingContentMetadata *contentMetaData = [SCORStreamingContentMetadata contentMetadataWithBuilderBlock:^(SCORStreamingContentMetadataBuilder *builder) {
        [builder setCustomLabels:properties];

        if (properties[@"ns_st_ge"]) {
            [builder setGenreName:properties[@"genre"]];
        }
    }];

    return contentMetaData;
}

@end
