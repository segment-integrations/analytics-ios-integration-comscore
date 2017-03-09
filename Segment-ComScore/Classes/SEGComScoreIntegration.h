//
//  SEGComScoreIntegration.h
//  Pods
//
//  Created by William Johnson on 5/16/16.
//
//

#import <Foundation/Foundation.h>
#import <Analytics/SEGIntegration.h>
#import <ComScore/ComScore.h>


@interface SEGComScoreIntegration : NSObject <SEGIntegration>

@property (nonatomic, strong) NSDictionary *settings;
@property (nonatomic, strong) SCORAnalytics *comScore;

- (instancetype)initWithSettings:(NSDictionary *)settings;
- (instancetype)initWithSettings:(NSDictionary *)settings andComScore:(SCORAnalytics *)comScore;

@end
