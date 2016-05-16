//
//  SEGComScoreIntegrationFactory.h
//  Pods
//
//  Created by William Johnson on 5/16/16.
//
//

#import <Foundation/Foundation.h>
#import <Analytics/SEGIntegrationFactory.h>

@interface SEGComScoreIntegrationFactory : NSObject<SEGIntegrationFactory>

+ (instancetype)instance;

@end