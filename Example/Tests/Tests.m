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
        SEGComScoreIntegration *integration = [[SEGComScoreIntegrationFactory instance] createWithSettings:@{
                                                                                                               } forAnalytics:nil];
        
        expect(integration.settings).to.equal(@{});
    });
});

describe(@"SEGComScoreIntegrationFactory", ^{
    it(@"factory creates integration with basic settings", ^{
        SEGComScoreIntegration *integration = [[SEGComScoreIntegrationFactory instance] createWithSettings:@{
            @"customerC2" : @"1234567",
            @"publisherSecret": @"publisherSecretString",
            @"setSecure": @"1",
            @"autoUpdateInterval": @"background"
        } forAnalytics:nil];
        
        expect(integration.settings).to.equal(@{
            @"customerC2": @"1234567",
            @"publisherSecret": @"publisherSecretString",
            @"setSecure": @"1",
            @"autoUpdateInterval": @"background"
        });
    });
});

SpecEnd

