//
//  SEGPayloadBuilder.h
//  Segment-ComScore
//
//  Created by William Johnson on 5/17/16.
//  Copyright © 2016 wcjohnson11. All rights reserved.
//

@import Foundation;
@import Analytics;


@interface SEGPayloadBuilder : NSObject

+ (SEGTrackPayload *)track:(NSString *)event;

+ (SEGTrackPayload *)track:(NSString *)event withProperties:(NSDictionary *)properties;

+ (SEGScreenPayload *)screen:(NSString *)name;

+ (SEGIdentifyPayload *)identify:(NSString *)userId;

+ (SEGIdentifyPayload *)identify:(NSString *)userId withTraits:(NSDictionary *)traits;

+ (SEGAliasPayload *)alias:(NSString *)newId;

@end
