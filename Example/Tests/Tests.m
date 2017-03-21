//
//  Segment-ComScoreTests.m
//  Segment-ComScoreTests
//
//  Created by wcjohnson11 on 05/16/2016.
//  Copyright (c) 2016 wcjohnson11. All rights reserved.
//

// https://github.com/Specta/Specta

SpecBegin(InitialSpecs);

describe(@"SEGComScoreIntegrationFactory", ^{
    it(@"factory creates integration with empty settings", ^{
        SEGComScoreIntegration *integration = [[SEGComScoreIntegrationFactory instance] createWithSettings:@{} forAnalytics:nil];

        expect(integration.settings).to.equal(@{});
    });
});

describe(@"SEGComScoreIntegrationFactory", ^{
    it(@"factory creates integration with basic settings", ^{
        SEGComScoreIntegration *integration = [[SEGComScoreIntegrationFactory instance] createWithSettings:@{
            @"c2" : @"1234567",
            @"publisherSecret" : @"publisherSecretString",
            @"setSecure" : @"1",
            @"autoUpdate" : @"1",
            @"foregroundOnly" : @"1",
            @"autoUpdateInterval" : @"2000"
        } forAnalytics:nil];

        expect(integration.settings).to.equal(@{
            @"c2" : @"1234567",
            @"publisherSecret" : @"publisherSecretString",
            @"setSecure" : @"1",
            @"autoUpdate" : @"1",
            @"foregroundOnly" : @"1",
            @"autoUpdateInterval" : @"2000"
        });
    });
});

describe(@"SEGComScoreIntegration", ^{
    __block Class mockComScore;
    __block SEGComScoreIntegration *integration;

    beforeEach(^{
        mockComScore = mockClass([CSComScore class]);
        integration = [[SEGComScoreIntegration alloc] initWithSettings:@{} andCSComScore:mockComScore];
    });

    it(@"identify with Traits", ^{
        SEGIdentifyPayload *payload = [[SEGIdentifyPayload alloc] initWithUserId:@"1111"
            anonymousId:nil
            traits:@{ @"name" : @"Kylo Ren",
                      @"gender" : @"male",
                      @"emotion" : @"angsty" }
            context:@{}
            integrations:@{}];

        [integration identify:payload];

        [verify(mockComScore) setLabel:@"name" value:@"Kylo Ren"];
        [verify(mockComScore) setLabel:@"gender" value:@"male"];
        [verify(mockComScore) setLabel:@"emotion" value:@"angsty"];
    });

    it(@"track with props", ^{
        SEGTrackPayload *payload = [[SEGTrackPayload alloc] initWithEvent:@"Starship Ordered" properties:@{ @"Starship Type" : @"Death Star" } context:@{} integrations:@{}];

        [integration track:payload];

        [verify(mockComScore) hiddenWithLabels:@{
            @"name" : @"Starship Ordered",
            @"Starship Type" : @"Death Star"
        }];
    });

    it(@"screen with props", ^{
        SEGScreenPayload *payload = [[SEGScreenPayload alloc] initWithName:@"Droid Planet" properties:@{ @"resources" : @"unlimited" } context:@{} integrations:@{}];

        [integration screen:payload];

        [verify(mockComScore) viewWithLabels:@{
            @"name" : @"Droid Planet",
            @"resources" : @"unlimited"
        }];
    });


    it(@"flush", ^{
        [integration flush];

        [verify(mockComScore) flushCache];
    });
});

SpecEnd
