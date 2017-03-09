//
//  SEGComScoreIntegration.m
//  Pods
//
//  Created by William Johnson on 5/16/16.
//
//

#import "SEGComScoreIntegration.h"
#import <Analytics/SEGAnalyticsUtils.h>

@implementation SEGComScoreIntegration

- (instancetype)initWithSettings:(NSDictionary *)settings 
{
    if (self = [super init]) {
        self.settings = settings;
        self.comScore = [SCORAnalytics class];
        
        SCORPublisherConfiguration *config = [SCORPublisherConfiguration publisherConfigurationWithBuilderBlock:^(SCORPublisherConfigurationBuilder *builder) {
            // publisherId is also known as c2 value
            builder.publisherId = settings[@"publisherId"];
            builder.publisherSecret = settings[@"publisherSecret"];
            builder.applicationName = settings[@"appName:"];
            
            if ([settings[@"autoUpdate"] boolValue] && [settings[@"foregroundOnly"] boolValue]) {
                builder.usagePropertiesAutoUpdateMode = SCORUsagePropertiesAutoUpdateModeForegroundOnly;
            } else if ([settings[@"autoUpdate"] boolValue]) {
                builder.usagePropertiesAutoUpdateMode = SCORUsagePropertiesAutoUpdateModeForegroundAndBackground;
            } else {
                builder.usagePropertiesAutoUpdateMode = SCORUsagePropertiesAutoUpdateModeDisabled;
            }
            builder.usagePropertiesAutoUpdateInterval = [settings[@"autoUpdateInterval"] integerValue];
            
            builder.secureTransmission = [settings[@"useHTTPS"] boolValue];
            
            //        TODO: What are these? And do they have equivalents
            
            //        [self.comScoreClass setSecure: [self useHTTPS]];
            //        SEGLog(@"[CSComScore setSecure: %@]", [self useHTTPS] ? @YES : @NO);
            //        [self.comScoreClass setAppContext];
            //        SEGLog(@"[CSComScore setAppContext]");
            
            //        [self.comScoreClass setCustomerC2:[self customerC2]];
            //        SEGLog(@"[CSComScore setCustomerC2: %@]", [self customerC2]);
            

        }];
        [[SCORAnalytics configuration] addClientWithConfiguration:config];
        
        [SCORAnalytics start];
        
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
            [[SCORAnalytics configuration] setPersistentLabelWithName:key value:data];
            SEGLog(@"[[SCORAnalytics configuration] setPersistentLabelWithName: %@ value: %@]", key, data);
        }
    }];
}


- (void)track:(SEGTrackPayload *)payload
{
    NSMutableDictionary *hiddenLabels = [@{@"name": payload.event} mutableCopy];
    [hiddenLabels addEntriesFromDictionary:[SEGComScoreIntegration mapToStrings:payload.properties]];
    [SCORAnalytics notifyHiddenEventWithLabels:hiddenLabels];
    SEGLog(@"[[SCORAnalytics configuration] notifyHiddenEventWithLabels: %@ value: %@]",hiddenLabels);
    
}

- (void)screen:(SEGScreenPayload *)payload
{
    NSMutableDictionary *viewLabels = [@{@"name":payload.name} mutableCopy];
    [viewLabels addEntriesFromDictionary:[SEGComScoreIntegration mapToStrings:payload.properties]];
    [SCORAnalytics notifyViewEventWithLabels:viewLabels];
    SEGLog(@"[[SCORAnalytics configuration] notifyViewEventWithLabels: %@ value: %@]", viewLabels);
}


- (void)flush
{
    SEGLog(@"ComScore flushCache");
    [SCORAnalytics flushOfflineCache];
}

@end
