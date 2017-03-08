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
//        self.comScoreClass = [CSComScore class];
//        
//        [self.comScoreClass setAppContext];
//        SEGLog(@"[CSComScore setAppContext]");
//        [self.comScoreClass setCustomerC2:[self customerC2]];
//        SEGLog(@"[CSComScore setCustomerC2: %@]", [self customerC2]);
//        [self.comScoreClass setPublisherSecret:[self publisherSecret]];
//        SEGLog(@"[CSComScore setPublisherSecret: %@]", [self publisherSecret]);
//        [self.comScoreClass setAppName: [self appName]];
//        SEGLog(@"[CSComScore setAppName: %@]", [self appName]);
//        [self.comScoreClass setSecure: [self useHTTPS]];
//        SEGLog(@"[CSComScore setSecure: %@]", [self useHTTPS] ? @YES : @NO);
//        if ([self autoUpdate]) {
//            if ([self foregroundOnly]) {
//                [self.comScoreClass enableAutoUpdate:[self autoUpdateInterval] foregroundOnly: YES];
//                SEGLog(@"[CSComScore enableAutoUpdate: %@ foregroundOnly: YES]", [self autoUpdateInterval]);
//            } else {
//                [self.comScoreClass enableAutoUpdate:[self autoUpdateInterval] foregroundOnly: NO];
//                SEGLog(@"[CSComScore enableAutoUpdate: %@ foregroundOnly: NO]", [self autoUpdateInterval]);
//            }
//        }
    }
    return self;
}

//- (instancetype)initWithSettings:(NSDictionary *)settings andCSComScore:(Class)comScoreClass
//{
//    if (self = [super init]) {
//        self.settings = settings;
//        self.comScoreClass = comScoreClass;
//    }
//    return self;
//
//}
//
//+ (NSDictionary *)mapToStrings:(NSDictionary *)dictionary
//{
//    NSMutableDictionary *mapped = [NSMutableDictionary dictionaryWithDictionary:dictionary];
//    
//    [dictionary enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSString *obj, BOOL *stop) {
//        id data = [mapped objectForKey:key];
//        if (!![data isKindOfClass:[NSString class]]) {
//            [mapped setObject:[NSString stringWithFormat:@"%@", data] forKey:key];
//        }
//    }];
//    
//    return [mapped copy];
//}
//
//- (void)identify:(SEGIdentifyPayload *)payload
//{
//    NSDictionary *mappedTraits = [SEGComScoreIntegration mapToStrings:payload.traits];
//    [mappedTraits enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSString *obj, BOOL *stop) {
//        id data = [payload.traits objectForKey:key];
//        if (data != nil && [data length] != 0) {
//            [self.comScoreClass setLabel: key value: data];
//            SEGLog(@"[CSComScore setLabel: %@ value: %@]", key, data);
//        }
//    }];
//}
//
//
//- (void)track:(SEGTrackPayload *)payload
//{
//    NSMutableDictionary *hiddenLabels = [@{@"name":payload.event} mutableCopy];
//    [hiddenLabels addEntriesFromDictionary:[SEGComScoreIntegration mapToStrings:payload.properties]];
//    [self.comScoreClass hiddenWithLabels:hiddenLabels];
//    
//}
//
//- (void)screen:(SEGScreenPayload *)payload
//{
//    NSMutableDictionary *viewLabels = [@{@"name":payload.name} mutableCopy];
//    [viewLabels addEntriesFromDictionary:[SEGComScoreIntegration mapToStrings:payload.properties]];
//    [self.comScoreClass viewWithLabels:viewLabels];
//}
//
//- (void)flush
//{
//    SEGLog(@"ComScore flushCache");
//    [self.comScoreClass flushCache];
//}
//
//- (NSString *)customerC2
//{
//    return self.settings[@"c2"];
//}
//
//- (NSString *)publisherSecret
//{
//    return (NSString *)[self.settings objectForKey:@"publisherSecret"];
//}
//
//- (NSString *)appName
//{
//    return (NSString *)[self.settings objectForKey:@"appName"];
//}
//
//- (BOOL)autoUpdate
//{
//    return [(NSNumber *)[self.settings objectForKey:@"autoUpdate"] boolValue];
//}
//
//- (BOOL)foregroundOnly
//{
//    return [(NSNumber *)[self.settings objectForKey:@"foregroundOnly"] boolValue];
//}
//
//- (int)autoUpdateInterval
//{
//    return [(NSNumber *)[self.settings objectForKey:@"autoUpdateInterval"] intValue];
//}
//
//- (BOOL)useHTTPS
//{
//    return [(NSNumber *)[self.settings objectForKey:@"useHTTPS"] boolValue];
//}

@end
