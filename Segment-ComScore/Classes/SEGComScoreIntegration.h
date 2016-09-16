//
//  SEGComScoreIntegration.h
//  Pods
//
//  Created by William Johnson on 5/16/16.
//
//

#import <Foundation/Foundation.h>
#import <Analytics/SEGIntegration.h>
#import <ComScore/CSComScore.h>


@interface SEGComScoreIntegration : NSObject <SEGIntegration>

@property (nonatomic, strong) NSDictionary *settings;
@property (nonatomic, strong) Class comScoreClass;

- (instancetype)initWithSettings:(NSDictionary *)settings;

- (instancetype)initWithSettings:(NSDictionary *)settings andCSComScore:(id)comScoreClass;

@end
