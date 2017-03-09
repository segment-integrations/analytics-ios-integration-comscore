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
    it(@"factory creates integration with empty settings", ^{
        SEGComScoreIntegration *integration = [[SEGComScoreIntegrationFactory instance] createWithSettings:@{} forAnalytics:nil];
        
        expect(integration.settings).to.equal(@{});
    });
});

describe(@"SEGComScoreIntegrationFactory", ^{
    it(@"factory creates integration with basic settings", ^{
        SEGComScoreIntegration *integration = [[SEGComScoreIntegrationFactory instance] createWithSettings:@{
            @"publisherId" : @"1234567",
            @"publisherSecret": @"publisherSecretString",
            @"autoUpdate": @"1",
            @"foregroundOnly": @"1",
            @"autoUpdateInterval": @"2000"
            
        } forAnalytics:nil];
        
        expect(integration.settings).to.equal(@{
            @"publisherId": @"1234567",
            @"publisherSecret": @"publisherSecretString",
            @"autoUpdate": @"1",
            @"foregroundOnly": @"1",
            @"autoUpdateInterval": @"2000"
        }); 
    });
});

describe(@"SEGComScoreIntegration", ^{
    __block SEGComScoreIntegration *integration;
    __block SCORAnalytics *mockComScore;
    
    beforeEach(^{
        mockComScore = mock([SCORAnalytics class]);
        integration = [[SEGComScoreIntegration alloc] initWithSettings:@{} andComScore: mockComScore];
    });
    
    it(@"identify with Traits", ^{
        SEGIdentifyPayload *payload = [[SEGIdentifyPayload alloc] initWithUserId:@"1111"
                                                                     anonymousId:nil
                                                                          traits:@{@"name":@"Kylo Ren",
                                                                                   @"gender": @"male",
                                                                                   @"emotion": @"angsty"}
                                                                         context:@{} integrations:@{}];
        
        [integration identify:payload];
        
        [verify(mockComScore) setPersistentLabelWithName: @"name" value: @"Kylo Ren"];
        [verify(mockComScore) setPersistentLabelWithName: @"gender" value: @"male"];
        [verify(mockComScore) setPersistentLabelWithName: @"emotion" value: @"angsty"];
    });
    
    it(@"track with props", ^{
        SEGTrackPayload *payload = [[SEGTrackPayload alloc] initWithEvent:@"Starship Ordered" properties:@{@"Starship Type": @"Death Star"} context:@{} integrations:@{}];
        
        [integration track:payload];
        
        [verify(mockComScore) notifyHiddenEventWithLabels:@{
                                                 @"name": @"Starship Ordered",
                                                 @"Starship Type": @"Death Star"}];
    });
    
    it(@"screen with props", ^{
        SEGScreenPayload *payload = [[SEGScreenPayload alloc] initWithName:@"Droid Planet" properties:@{@"resources":@"unlimited"} context:@{} integrations:@{}];
        
        [integration screen:payload];
        
        [verify(mockComScore) notifyViewEventWithLabels:@{
                                               @"name": @"Droid Planet",
                                               @"resources": @"unlimited"
                                               }];
    });

    
    it(@"flush", ^{
        [integration flush];
        
        [verify(mockComScore) flushOfflineCache];
    });
});

SpecEnd

