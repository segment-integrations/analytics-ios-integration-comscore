//
//  SEGComScoreIntegration.h
//  Pods
//
//  Created by William Johnson on 5/16/16.
//
//

#import <Foundation/Foundation.h>
#import <ComScore/ComScore.h>

#if defined(__has_include) && __has_include(<Analytics/SEGAnalytics.h>)
#import <Analytics/SEGIntegration.h>
#else
#import <Segment/SEGIntegration.h>
#endif



@protocol SEGStreamingAnalyticsFactory <NSObject>
- (SCORStreamingAnalytics *)create;
@end


@interface SEGRealStreamingAnalyticsFactory : NSObject <SEGStreamingAnalyticsFactory>
@end


@interface SEGComScoreIntegration : NSObject <SEGIntegration>

@property (nonatomic, strong) NSDictionary *settings;
@property (nonatomic, strong) Class scorAnalyticsClass;
@property (nonatomic, strong) SCORStreamingAnalytics *streamAnalytics;
@property (nonatomic) id<SEGStreamingAnalyticsFactory> streamingAnalyticsFactory;
@property (nonatomic, strong) NSMutableDictionary *configurationLabels;
NSNumber *convertFromKBPSToBPS(NSDictionary *src, NSString *key);


- (instancetype)initWithSettings:(NSDictionary *)settings andComScore:(id)scorAnalyticsClass andStreamingAnalyticsFactory:(id<SEGStreamingAnalyticsFactory>)streamingAnalyticsFactory;


@end
