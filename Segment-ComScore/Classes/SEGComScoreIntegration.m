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
        self.comScoreClass = [CSComScore class];
        
        [self.comScoreClass setAppContext];
        SEGLog(@"[CSComScore setAppContext]");
        [self.comScoreClass setCustomerC2:[self customerC2]];
        SEGLog(@"[CSComScore setCustomerC2: %@]", [self customerC2]);
        [self.comScoreClass setPublisherSecret:[self publisherSecret]];
        SEGLog(@"[CSComScore setPublisherSecret: %@]", [self publisherSecret]);
        [self.comScoreClass setSecure: [self useHTTPS]];
        SEGLog(@"[CSComScore setSecure: %@]", [self useHTTPS]);
        if ([[[self autoUpdateMode] lowercaseString] isEqualToString:@"foreground"]) {
            [self.comScoreClass enableAutoUpdate:[self autoUpdateInterval] foregroundOnly: YES];
            SEGLog(@"[CSComScore enableAutoUpdate: %@ foregroundOnly: YES]", [self autoUpdateInterval]);
        } else if ([[[self autoUpdateMode] lowercaseString] isEqualToString:@"background"]) {
            [self.comScoreClass enableAutoUpdate:[self autoUpdateInterval] foregroundOnly: YES];
            SEGLog(@"[CSComScore enableAutoUpdate: %@ backgroundOnly: YES]", [self autoUpdateInterval]);
        } else {
            [self.comScoreClass disableAutoUpdate];
        }
    }
    return self;
}

- (instancetype)initWithSettings:(NSDictionary *)settings andCSComScore:(Class)comScoreClass
{
    if (self = [super init]) {
        self.settings = settings;
        self.comScoreClass = comScoreClass;
    }
    return self;

}

- (NSString *)customerC2
{
    return self.settings[@"customerC2"];
}

- (NSString *)publisherSecret
{
    return (NSString *)[self.settings objectForKey:@"publisherSecret"];
}

- (NSString *)autoUpdateMode
{
    return (NSString *)[self.settings objectForKey:@"autoUpdateMode"];
}

- (NSNumber *)autoUpdateInterval
{
    return (NSNumber *)[self.settings objectForKey:@"autoUpdateInterval"];
}

- (NSNumber *)useHTTPS
{
    return (NSNumber *)[self.settings objectForKey:@"useHTTPS"];
}

@end