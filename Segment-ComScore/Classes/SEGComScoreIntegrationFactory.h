//
//  SEGComScoreIntegrationFactory.h
//  Pods
//
//  Created by William Johnson on 5/16/16.
//
//

#import <Foundation/Foundation.h>

#if defined(__has_include) && __has_include(<Analytics/SEGAnalytics.h>)
#import <Analytics/SEGIntegrationFactory.h>
#else
#import <Segment/SEGIntegrationFactory.h>
#endif


@interface SEGComScoreIntegrationFactory : NSObject <SEGIntegrationFactory>

+ (instancetype)instance;

@end
