//
//  SEGComScoreIntegrationFactory.m
//  Pods
//
//  Created by William Johnson on 5/16/16.
//
//

#import "SEGComScoreIntegrationFactory.h"
#import "SEGComScoreIntegration.h"

@implementation SEGComScoreIntegrationFactory

+ (instancetype)instance
{
    static dispatch_once_t once;
    static SEGComScoreIntegrationFactory *sharedInstance;
    dispatch_once(&once, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init
{
    self = [super init];
    return self;
}

- (id<SEGIntegration>)createWithSettings:(NSDictionary *)settings forAnalytics:(SEGAnalytics *)analytics
{
    return [[SEGComScoreIntegration alloc] initWithSettings:settings];
}

- (NSString *)key
{
    return @"comScore";
}

@end
