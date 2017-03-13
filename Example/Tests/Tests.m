//
//  Segment-ComScoreTests.m
//  Segment-ComScoreTests
//
//  Created by wcjohnson11 on 05/16/2016.
//  Copyright (c) 2016 wcjohnson11. All rights reserved.
//

// https://github.com/Specta/Specta

SpecBegin(InitialSpecs)

describe(@"SEGComScoreIntegrationFactory", ^{
    it(@"factory creates integration with basic settings", ^{
        SEGComScoreIntegration *integration = [[SEGComScoreIntegrationFactory instance] createWithSettings:@{
            @"c2" : @"1234567",
            @"publisherSecret": @"publisherSecretString",
            @"setSecure": @"1",
            @"autoUpdate": @"1",
            @"foregroundOnly": @"1",
            @"autoUpdateInterval": @"2000"
        } forAnalytics:nil];
        
        expect(integration.settings).to.equal(@{
            @"c2": @"1234567",
            @"publisherSecret": @"publisherSecretString",
            @"setSecure": @"1",
            @"autoUpdate": @"1",
            @"foregroundOnly": @"1",
            @"autoUpdateInterval": @"2000"
        }); 
    });
});

describe(@"SEGComScoreIntegration", ^{
    __block SCORAnalytics *comScore;
    __block SEGComScoreIntegration *integration;
    
    beforeEach(^{
        comScore = mock([SCORAnalytics class]);
        integration = [[SEGComScoreIntegration alloc] initWithSettings:@{
                                                                         @"c2" : @"23243060",
                                                                         @"publisherSecret": @"7e529e62366db3423ef3728ca910b8b8"
                                                                         
        } andComScore:comScore];
    });
    
    it(@"identify with Traits", ^{
        SEGIdentifyPayload *payload = [[SEGIdentifyPayload alloc] initWithUserId:@"44"
                                                                     anonymousId:nil
                                                                          traits:@{@"name":@"Milhouse Van Houten",
                                                                                   @"gender": @"male",
                                                                                   @"emotion": @"nerdy"}
                                                                         context:@{} integrations:@{}];
        
        [integration identify:payload];
        
        [verify(comScore) setPersistentLabelWithName: @"name" value: @"Milhouse Van Houten"];
        [verify(comScore) setPersistentLabelWithName: @"gender" value: @"male"];
        [verify(comScore) setPersistentLabelWithName: @"emotion" value: @"nerdy"];
    });
    
    it(@"track with props", ^{
        SEGTrackPayload *payload = [[SEGTrackPayload alloc] initWithEvent:@"Order Completed" properties:@{@"Type": @"Flood"} context:@{} integrations:@{}];
        
        [integration track:payload];
        
        [verify(comScore) notifyHiddenEventWithLabels:@{
                                                 @"name": @"Order Completed",
                                                 @"Type": @"Flood"}];
    });
    
    it(@"screen with props", ^{
        SEGScreenPayload *payload = [[SEGScreenPayload alloc] initWithName:@"Home" properties:@{@"Ad":@"Flood Pants"} context:@{} integrations:@{}];
        
        [integration screen:payload];
        
        [verify(comScore) notifyViewEventWithLabels:@{
                                               @"name": @"Home",
                                               @"Ad": @"Flood Pants"
                                               }];
    });

    
    it(@"flush", ^{
        [integration flush];
        
        [verify(comScore) flushOfflineCache];
    });
});

SpecEnd

