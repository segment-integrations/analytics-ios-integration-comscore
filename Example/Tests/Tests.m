//
//  Segment-ComScoreTests.m
//  Segment-ComScoreTests
//
//  Created by wcjohnson11 on 05/16/2016.
//  Copyright (c) 2016 wcjohnson11. All rights reserved.
//

// https://github.com/Specta/Specta


@interface SEGMockStreamingAnalyticsFactory : NSObject <SEGStreamingAnalyticsFactory>

@property (nonatomic, strong) SCORStreamingAnalytics *streamingAnalytics;

@end


@implementation SEGMockStreamingAnalyticsFactory

- (SCORStreamingAnalytics *)create;
{
    return self.streamingAnalytics;
}

@end

void setupWithVideoPlaybackStarted(SEGComScoreIntegration *integration, SCORStreamingAnalytics *streamingAnalytics)
{
    SEGTrackPayload *payload = [[SEGTrackPayload alloc] initWithEvent:@"Video Playback Started" properties:@{
        @"asset_id" : @"1234",
        @"content_pod_id" : @"45567",
        @"ad_type" : @"pre-roll",
        @"length" : @"100",
        @"video_player" : @"youtube"
    } context:@{}
        integrations:@{}];

    [integration track:payload];
};

SpecBegin(InitialSpecs);

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
    __block Class scorAnalyticsClassMock;
    __block SCORStreamingAnalytics *streamingAnalytics;
    __block SEGComScoreIntegration *integration;

    beforeEach(^{
        scorAnalyticsClassMock = mockClass([SCORAnalytics class]);
        streamingAnalytics = mock([SCORStreamingAnalytics class]);
        SEGMockStreamingAnalyticsFactory *mockStreamAnalyticsFactory = [[SEGMockStreamingAnalyticsFactory alloc] init];
        mockStreamAnalyticsFactory.streamingAnalytics = streamingAnalytics;

        integration = [[SEGComScoreIntegration alloc] initWithSettings:@{
            @"c2" : @"23243060",
            @"publisherSecret" : @"7e529e62366db3423ef3728ca910b8b8"
        } andComScore:scorAnalyticsClassMock andStreamingAnalyticsFactory:mockStreamAnalyticsFactory];
    });

    it(@"identify with Traits", ^{
        SCORConfiguration *configuration = mock([SCORConfiguration class]);
        [given([scorAnalyticsClassMock configuration]) willReturn:configuration];

        SEGIdentifyPayload *payload = [[SEGIdentifyPayload alloc] initWithUserId:@"44"
            anonymousId:nil
            traits:@{ @"name" : @"Milhouse Van Houten",
                      @"gender" : @"male",
                      @"emotion" : @"nerdy" }
            context:@{}
            integrations:@{}];

        [integration identify:payload];


        [verify(configuration) setPersistentLabelWithName:@"name" value:@"Milhouse Van Houten"];
        [verify(configuration) setPersistentLabelWithName:@"gender" value:@"male"];
        [verify(configuration) setPersistentLabelWithName:@"emotion" value:@"nerdy"];
    });

    it(@"track with props", ^{
        SEGTrackPayload *payload = [[SEGTrackPayload alloc] initWithEvent:@"Order Completed" properties:@{ @"Type" : @"Flood" } context:@{} integrations:@{}];

        [integration track:payload];

        [verify(scorAnalyticsClassMock) notifyHiddenEventWithLabels:@{
            @"name" : @"Order Completed",
            @"Type" : @"Flood"
        }];
    });

    it(@"screen with props", ^{
        SEGScreenPayload *payload = [[SEGScreenPayload alloc] initWithName:@"Home" properties:@{ @"Ad" : @"Flood Pants" } context:@{} integrations:@{}];

        [integration screen:payload];

        [verify(scorAnalyticsClassMock) notifyViewEventWithLabels:@{
            @"name" : @"Home",
            @"Ad" : @"Flood Pants"
        }];
    });

    it(@"flush", ^{
        [integration flush];
        [verify(scorAnalyticsClassMock) flushOfflineCache];
    });

#pragma mark - Video Tracking


#pragma Playback Events

    it(@"videoPlaybackStarted", ^{
        SEGTrackPayload *payload = [[SEGTrackPayload alloc] initWithEvent:@"Video Playback Started" properties:@{
            @"asset_id" : @"1234",
            @"content_pod_id" : @"45567",
            @"ad_type" : @"pre-roll",
            @"length" : @"100",
            @"video_player" : @"youtube"
        } context:@{}
            integrations:@{}];


        [integration track:payload];


        [verify(streamingAnalytics) createPlaybackSessionWithLabels:@{
            @"ns_st_ci" : @"1234",
            @"ns_st_pn" : @"45567",
            @"ns_st_ad" : @"pre-roll",
            @"ns_st_cl" : @"100",
            @"ns_st_st" : @"youtube"
        }];

    });

    it(@"videoPlaybackPaused", ^{
        setupWithVideoPlaybackStarted(integration, streamingAnalytics);
        SEGTrackPayload *payload = [[SEGTrackPayload alloc] initWithEvent:@"Video Playback Paused" properties:@{
            @"asset_id" : @"7890",
            @"content_pod_id" : @"4324",
            @"ad_type" : @"mid-roll",
            @"length" : @"200",
            @"video_player" : @"vimeo"
        } context:@{}
            integrations:@{}];
        [integration track:payload];

        [verify(streamingAnalytics) notifyEndWithLabels:@{
            @"ns_st_ci" : @"7890",
            @"ns_st_pn" : @"4324",
            @"ns_st_ad" : @"mid-roll",
            @"ns_st_cl" : @"200",
            @"ns_st_st" : @"vimeo"
        }];
    });


    it(@"videoPlaybackBufferStarted", ^{
        setupWithVideoPlaybackStarted(integration, streamingAnalytics);
        SEGTrackPayload *payload = [[SEGTrackPayload alloc] initWithEvent:@"Video Playback Buffer Started" properties:@{
            @"asset_id" : @"2340",
            @"content_pod_id" : @"6859",
            @"ad_type" : @"post-roll",
            @"length" : @"300",
            @"video_player" : @"youtube"
        } context:@{}
            integrations:@{}];
        [integration track:payload];
        [verify(streamingAnalytics) notifyBufferStartWithLabels:@{
            @"ns_st_ci" : @"2340",
            @"ns_st_pn" : @"6859",
            @"ns_st_ad" : @"post-roll",
            @"ns_st_cl" : @"300",
            @"ns_st_st" : @"youtube"
        }];

    });

    it(@"videoPlaybackBufferCompleted", ^{
        setupWithVideoPlaybackStarted(integration, streamingAnalytics);
        SEGTrackPayload *payload = [[SEGTrackPayload alloc] initWithEvent:@"Video Playback Buffer Completed" properties:@{
            @"asset_id" : @"1230",
            @"content_pod_id" : @"0912",
            @"ad_type" : @"mid-roll",
            @"length" : @"400",
            @"video_player" : @"youtube"
        } context:@{}
            integrations:@{}];

        [integration track:payload];
        [verify(streamingAnalytics) notifyBufferStopWithLabels:@{
            @"ns_st_ci" : @"1230",
            @"ns_st_pn" : @"0912",
            @"ns_st_ad" : @"mid-roll",
            @"ns_st_cl" : @"400",
            @"ns_st_st" : @"youtube"
        }];
    });
    //
    //    it(@"videoPlaybackSeekStarted", ^{
    //    });
    //
    //    it(@"videoPlaybackSeekCompleted", ^{
    //    });
    //
    //    it(@"videoPlaybackResumed", ^{
    //    });
    //
    //#pragma Content Events
    //
    //    it(@"videoContentStarted", ^{
    //    });
    //
    //    it(@"videoContentPlaying", ^{
    //    });
    //
    //    it(@"videoContentCompleted", ^{
    //    });
    //
    //#pragma Ad Events
    //
    //    it(@"videoAdStarted", ^{
    //    });
    //
    //    it(@"videoAdPlaying", ^{
    //    });
    //
    //    it(@"videoAdCompleted", ^{
    //    });
});

SpecEnd
