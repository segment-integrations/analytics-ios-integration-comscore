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

@implementation SEGComScoreIntegration

- (instancetype)initWithSettings:(NSDictionary *)settings andComScore:(id)scorAnalyticsClass
{
    if (self = [super init]) {
        
        self.settings = settings;
        self.scorAnalyticsClass = scorAnalyticsClass;
    
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
        
        // Required for every call so comScore differentiate events coming in from Segment
        SCORPartnerConfiguration *partnerConfig = [SCORPartnerConfiguration
                                                   partnerConfigurationWithBuilderBlock:^(SCORPartnerConfigurationBuilder *builder) {
                                                       builder.partnerId = @"23243060"; // Segment Test Account c2 id
                                                    }];
        

        [[SCORAnalytics configuration] addClientWithConfiguration:partnerConfig];
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
    
    if ([payload.event isEqualToString:@"Video Playback Started"]){
    
        [self videoPlaybackStarted:payload.properties];
        return;
    }
    
    if ([payload.event isEqualToString:@"Video Playback Paused"]){
        
        [self videoPlaybackPaused:payload.properties];
        return;
    }
    
    if ([payload.event isEqualToString:@"Video Playback Buffer Started"]){
        
        [self videoPlaybackBufferStarted:payload.properties];
        return;
    }
    
    if ([payload.event isEqualToString:@"Video Playback Buffer Completed"]){
        
        [self videoPlaybackBufferCompleted:payload.properties];
        return;
    }
    
    if ([payload.event isEqualToString:@"Video Playback Seek Started"]){
        
        [self videoPlaybackSeekStarted:payload.properties];
        return;
    }
    
    if ([payload.event isEqualToString:@"Video Playback Seek Completed"]){
        
        [self videoPlaybackSeekCompleted:payload.properties];
        return;
    }
    
    if ([payload.event isEqualToString:@"Video Playback Resumed"]){
        
        [self videoPlaybackResumed:payload.properties];
        return;
    }
    
    
    if([payload.event isEqualToString:@"Video Content Started"]){
    
        [self videoContentStarted:payload.properties];
        return;
    }
    
    if([payload.event isEqualToString:@"Video Content Playing"]){
        [self videoContentPlaying:payload.properties];
        return;
    }
    
    if([payload.event isEqualToString:@"Video Content Completed"]){
        [self videoContentCompleted:payload.properties];
        return;
    }
    
    if([payload.event isEqualToString:@"Video Ad Started"]){
        [self videoAdStarted:payload.properties];
        return;
    }
    
    if([payload.event isEqualToString:@"Video Ad Playing"]){
        [self videoAdPlaying:payload.properties];
        return;
    }
    
    if([payload.event isEqualToString:@"Video Ad Completed"]){
        [self videoAdCompleted:payload.properties];
        return;
    }
    
    
    NSMutableDictionary *hiddenLabels = [@{@"name": payload.event} mutableCopy];
    [hiddenLabels addEntriesFromDictionary:[SEGComScoreIntegration mapToStrings:payload.properties]];
    [self.scorAnalyticsClass notifyHiddenEventWithLabels:hiddenLabels];
    SEGLog(@"[[SCORAnalytics configuration] notifyHiddenEventWithLabels: %@]",hiddenLabels);
    
}

- (void)screen:(SEGScreenPayload *)payload
{
    NSMutableDictionary *viewLabels = [@{@"name":payload.name} mutableCopy];
    [viewLabels addEntriesFromDictionary:[SEGComScoreIntegration mapToStrings:payload.properties]];
    [self.scorAnalyticsClass notifyViewEventWithLabels:viewLabels];
    SEGLog(@"[[SCORAnalytics configuration] notifyViewEventWithLabels: %@]", viewLabels);
}


- (void)flush
{
    SEGLog(@"[SCORAnalytics flushOfflineCache]");
    [self.scorAnalyticsClass flushOfflineCache];
}

#pragma mark - Video Tracking

#pragma Playback Events

-(void)videoPlaybackStarted: (NSDictionary *)properties
{
    self.streamAnalytics = [[SCORStreamingAnalytics alloc] init];
    
    NSDictionary *map = [NSDictionary dictionaryWithObjectsAndKeys:
                         @"ns_st_ci", @"asset_id",
                         @"ns_st_pn", @"content_pod_id",
                         @"ns_st_ad", @"ad_type",
                         @"ns_st_cl", @"length",
                         @"ns_st_st", @"video_player", nil];
    
    [self.streamAnalytics createPlaybackSessionWithLabels:map];

}


-(void)videoPlaybackPaused: (NSDictionary *)properties
{
    NSDictionary *map = [NSDictionary dictionaryWithObjectsAndKeys:
                         @"ns_st_ci", @"asset_id",
                         @"ns_st_pn", @"content_pod_id",
                         @"ns_st_ad", @"ad_type",
                         @"ns_st_cl", @"length",
                         @"ns_st_st", @"video_player", nil];
    
    [self.streamAnalytics notifyEndWithLabels:map];

}

-(void)videoPlaybackBufferStarted: (NSDictionary *)properties
{
    NSDictionary *map = [NSDictionary dictionaryWithObjectsAndKeys:
                         @"ns_st_ci", @"asset_id",
                         @"ns_st_pn", @"content_pod_id",
                         @"ns_st_ad", @"ad_type",
                         @"ns_st_cl", @"length",
                         @"ns_st_st", @"video_player", nil];
    
    [self.streamAnalytics notifyBufferStartWithLabels:map];
}

-(void)videoPlaybackBufferCompleted: (NSDictionary *)properties
{
    NSDictionary *map = [NSDictionary dictionaryWithObjectsAndKeys:
                         @"ns_st_ci", @"asset_id",
                         @"ns_st_pn", @"content_pod_id",
                         @"ns_st_ad", @"ad_type",
                         @"ns_st_cl", @"length",
                         @"ns_st_st", @"video_player", nil];
    
    [self.streamAnalytics notifyBufferStopWithLabels:map];
}


-(void)videoPlaybackSeekStarted: (NSDictionary *)properties
{
    NSDictionary *map = [NSDictionary dictionaryWithObjectsAndKeys:
                         @"ns_st_ci", @"asset_id",
                         @"ns_st_pn", @"content_pod_id",
                         @"ns_st_ad", @"ad_type",
                         @"ns_st_cl", @"length",
                         @"ns_st_st", @"video_player", nil];
    
    [self.streamAnalytics notifySeekStartWithLabels:map];
}


// Pinging comScore for comparable event to map to
-(void)videoPlaybackSeekCompleted: (NSDictionary *)properites
{
}

-(void)videoPlaybackResumed: (NSDictionary *)properites
{
    NSDictionary *map = [NSDictionary dictionaryWithObjectsAndKeys:
                         @"ns_st_ci", @"asset_id",
                         @"ns_st_pn", @"content_pod_id",
                         @"ns_st_ad", @"ad_type",
                         @"ns_st_cl", @"length",
                         @"ns_st_st", @"video_player", nil];
    
    [self.streamAnalytics notifyPlayWithLabels:map];
}

# pragma Content Events

-(void)videoContentStarted: (NSDictionary *)properties
{
    NSDictionary *map = [NSDictionary dictionaryWithObjectsAndKeys:
                         @"ns_st_ci", @"asset_id",
                         @"ns_st_pn", @"pod_id",
                         @"ns_st_ep", @"title",
                         @"ns_st_ge", @"keywords",
                         @"ns_st_sn", @"season",
                         @"ns_st_ep", @"episode",
                         @"ns_st_ge", @"genre",
                         @"ns_st_pr", @"program",
                         @"ns_st_pu", @"channel",
                         @"ns_st_ce", @"full_episode", nil];
    
    [self.streamAnalytics notifyPlayWithLabels:map];
}

-(void)videoContentPlaying: (NSDictionary *)properites
{
    int playPosition;
    
    NSDictionary *map = [NSDictionary dictionaryWithObjectsAndKeys:
                         @"ns_st_ci", @"asset_id",
                         @"ns_st_pn", @"pod_id",
                         @"ns_st_ep", @"title",
                         @"ns_st_ge", @"keywords",
                         @"ns_st_sn", @"season",
                         @"ns_st_ep", @"episode",
                         @"ns_st_ge", @"genre",
                         @"ns_st_pr", @"program",
                         @"ns_st_pu", @"channel",
                         @"ns_st_ce", @"full_episode", nil];
    
    [self.streamAnalytics notifyPlayWithPosition:playPosition labels: map];
}

#pragma Ad Events

-(void)videoContentCompleted: (NSDictionary *)properties
{
    NSDictionary *map = [NSDictionary dictionaryWithObjectsAndKeys:
                         @"ns_st_cl", @"asset_id",
                         @"ns_st_pn", @"pod_id",
                         @"ns_st_ad", @"type",
                         @"ns_st_pu", @"publisher",
                         @"ns_st_cl", @"length", nil];
    
    [self.streamAnalytics notifyEndWithLabels:map];
}

-(void)videoAdStarted: (NSDictionary *)properties
{
    NSDictionary *map = [NSDictionary dictionaryWithObjectsAndKeys:
                         @"ns_st_cl", @"asset_id",
                         @"ns_st_pn", @"pod_id",
                         @"ns_st_ad", @"type",
                         @"ns_st_pu", @"publisher",
                         @"ns_st_cl", @"length", nil];
    
    [self.streamAnalytics notifyPlayWithLabels:map];
}

-(void)videoAdPlaying: (NSDictionary *)properties
{
    int playPosition;
    
    NSDictionary *map = [NSDictionary dictionaryWithObjectsAndKeys:
                         @"ns_st_cl", @"asset_id",
                         @"ns_st_pn", @"pod_id",
                         @"ns_st_ad", @"type",
                         @"ns_st_pu", @"publisher",
                         @"ns_st_cl", @"length", nil];

    [self.streamAnalytics notifyPlayWithPosition:(playPosition) labels:map];
}

-(void)videoAdCompleted: (NSDictionary *)properties
{
    NSDictionary *map = [NSDictionary dictionaryWithObjectsAndKeys:
                         @"ns_st_cl", @"asset_id",
                         @"ns_st_pn", @"pod_id",
                         @"ns_st_ad", @"type",
                         @"ns_st_pu", @"publisher",
                         @"ns_st_cl", @"length", nil];
    
    [self.streamAnalytics notifyEndWithLabels:map];
}



@end
