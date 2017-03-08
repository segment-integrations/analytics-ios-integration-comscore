//
//  SEGComScoreIntegration.h
//  Pods
//
//  Created by William Johnson on 5/16/16.
//
//

#import <Foundation/Foundation.h>
#import <Analytics/SEGIntegration.h>
//#import <ComScore/ComScore.h>


@interface SEGComScoreIntegration : NSObject <SEGIntegration>

@property (nonatomic, strong) NSDictionary *settings;

- (instancetype)initWithSettings:(NSDictionary *)settings;

@end
