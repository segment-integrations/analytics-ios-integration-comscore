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
        @"ad_type" : @"pre-roll",
        @"total_length" : @"100",
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

    describe(@"returnNullStringIfNotDefined", ^{
        it(@"Accounts for empty String values", ^{
            NSDictionary *testDict = @{ @"key" : @"" };
            expect(returnNullStringIfNotDefined(testDict, @"key")).to.equal(@"*null");
        });
        it(@"Accounts for padded empty String values", ^{
            NSDictionary *testDict = @{ @"key" : @" " };
            expect(returnNullStringIfNotDefined(testDict, @"key")).to.equal(@"*null");
        });

        it(@"Accounts for even more padded empty String values", ^{
            NSDictionary *testDict = @{ @"key" : @"   " };
            expect(returnNullStringIfNotDefined(testDict, @"key")).to.equal(@"*null");
        });
    });

#pragma Playback Events

    it(@"videoPlaybackStarted", ^{
        SEGTrackPayload *payload = [[SEGTrackPayload alloc] initWithEvent:@"Video Playback Started" properties:@{
            @"asset_id" : @"1234",
            @"ad_type" : @"pre-roll",
            @"total_length" : @"100",
            @"video_player" : @"youtube"

        } context:@{}
            integrations:@{}];

        [integration track:payload];
        [verify(streamingAnalytics) createPlaybackSessionWithLabels:@{
            @"ns_st_ci" : @"1234",
            @"ns_st_ad" : @"pre-roll",
            @"ns_st_cl" : @"100",
            @"ns_st_mp" : @"youtube",
            @"c3" : @"*null",
            @"c4" : @"*null",
            @"c6" : @"*null"
        }];

    });

    it(@"videoPlaybackPaused", ^{
        setupWithVideoPlaybackStarted(integration, streamingAnalytics);
        SEGTrackPayload *payload = [[SEGTrackPayload alloc] initWithEvent:@"Video Playback Paused" properties:@{
            @"asset_id" : @"7890",
            @"ad_type" : @"mid-roll",
            @"total_length" : @"200",
            @"video_player" : @"vimeo",
            @"play_position" : @30,
            @"sound" : @100,
            @"full_screen" : @YES
        } context:@{}
                                                             integrations:@{
                                                                 @"c3" : @"test"
                                                             }];

        [integration track:payload];
        [verify(streamingAnalytics) notifyPauseWithPosition:30 labels:@{
            @"ns_st_ci" : @"7890",
            @"ns_st_ad" : @"mid-roll",
            @"ns_st_cl" : @"200",
            @"ns_st_mp" : @"vimeo",
            @"ns_st_vo" : @100,
            @"ns_st_ws" : @"full",
            @"c3" : @"test",
            @"c4" : @"*null",
            @"c6" : @"*null"

        }];
    });


    it(@"videoPlaybackBufferStarted", ^{
        setupWithVideoPlaybackStarted(integration, streamingAnalytics);
        SEGTrackPayload *payload = [[SEGTrackPayload alloc] initWithEvent:@"Video Playback Buffer Started" properties:@{
            @"asset_id" : @"2340",
            @"ad_type" : @"post-roll",
            @"total_length" : @"300",
            @"video_player" : @"youtube",
            @"play_position" : @190,
            @"sound" : @100,
            @"full_screen" : @NO

        } context:@{}
                                                             integrations:@{
                                                                 @"c4" : @"test"
                                                             }];

        [integration track:payload];
        [verify(streamingAnalytics) notifyBufferStartWithPosition:190 labels:@{
            @"ns_st_ci" : @"2340",
            @"ns_st_ad" : @"post-roll",
            @"ns_st_cl" : @"300",
            @"ns_st_mp" : @"youtube",
            @"ns_st_vo" : @100,
            @"ns_st_ws" : @"norm",
            @"c3" : @"*null",
            @"c4" : @"test",
            @"c6" : @"*null"

        }];

    });

    it(@"videoPlaybackBufferCompleted", ^{
        setupWithVideoPlaybackStarted(integration, streamingAnalytics);
        SEGTrackPayload *payload = [[SEGTrackPayload alloc] initWithEvent:@"Video Playback Buffer Completed" properties:@{
            @"asset_id" : @"1230",
            @"ad_type" : @"mid-roll",
            @"total_length" : @"400",
            @"video_player" : @"youtube",
            @"play_position" : @90,
            @"sound" : @100,
            @"full_screen" : @NO

        } context:@{}
            integrations:@{}];

        [integration track:payload];
        [verify(streamingAnalytics) notifyBufferStopWithPosition:90 labels:@{
            @"ns_st_ci" : @"1230",
            @"ns_st_ad" : @"mid-roll",
            @"ns_st_cl" : @"400",
            @"ns_st_mp" : @"youtube",
            @"ns_st_vo" : @100,
            @"c3" : @"*null",
            @"c4" : @"*null",
            @"c6" : @"*null",
            @"ns_st_ws" : @"norm",

        }];
    });

    it(@"videoPlaybackSeekStarted", ^{
        setupWithVideoPlaybackStarted(integration, streamingAnalytics);
        SEGTrackPayload *payload = [[SEGTrackPayload alloc] initWithEvent:@"Video Playback Seek Started" properties:@{
            @"asset_id" : @"6352",
            @"ad_type" : @"pre-roll",
            @"total_length" : @"200",
            @"video_player" : @"vimeo",
            @"play_position" : @20,
            @"sound" : @100,
            @"full_screen" : @YES

        } context:@{}
            integrations:@{}];

        [integration track:payload];
        [verify(streamingAnalytics) notifySeekStartWithPosition:20 labels:@{
            @"ns_st_ci" : @"6352",
            @"ns_st_ad" : @"pre-roll",
            @"ns_st_cl" : @"200",
            @"ns_st_mp" : @"vimeo",
            @"ns_st_vo" : @100,
            @"c3" : @"*null",
            @"c4" : @"*null",
            @"c6" : @"*null",
            @"ns_st_ws" : @"full"
        }];
    });


    it(@"videoPlaybackSeekCompleted", ^{
        setupWithVideoPlaybackStarted(integration, streamingAnalytics);
        SEGTrackPayload *payload = [[SEGTrackPayload alloc] initWithEvent:@"Video Playback Seek Completed" properties:@{
            @"asset_id" : @"6352",
            @"ad_type" : @"pre-roll",
            @"total_length" : @"200",
            @"video_player" : @"vimeo",
            @"play_position" : @20,
            @"sound" : @100,
            @"full_screen" : @YES

        } context:@{}
            integrations:@{}];

        [integration track:payload];
        [verify(streamingAnalytics) notifySeekStartWithPosition:20 labels:@{
            @"ns_st_ci" : @"6352",
            @"ns_st_ad" : @"pre-roll",
            @"ns_st_cl" : @"200",
            @"ns_st_mp" : @"vimeo",
            @"ns_st_vo" : @100,
            @"c3" : @"*null",
            @"c4" : @"*null",
            @"c6" : @"*null",
            @"ns_st_ws" : @"full"
        }];
    });

    it(@"videoPlaybackResumed", ^{
        setupWithVideoPlaybackStarted(integration, streamingAnalytics);
        SEGTrackPayload *payload = [[SEGTrackPayload alloc] initWithEvent:@"Video Playback Resumed" properties:@{
            @"asset_id" : @"2141",
            @"ad_type" : @"mid-roll",
            @"total_length" : @"100",
            @"video_player" : @"youtube",
            @"play_position" : @34,
            @"sound" : @100,
            @"full_screen" : @YES

        } context:@{}
            integrations:@{}];

        [integration track:payload];
        [verify(streamingAnalytics) notifyPlayWithPosition:34 labels:@{
            @"ns_st_ci" : @"2141",
            @"ns_st_ad" : @"mid-roll",
            @"ns_st_cl" : @"100",
            @"ns_st_mp" : @"youtube",
            @"ns_st_vo" : @100,
            @"c3" : @"*null",
            @"c4" : @"*null",
            @"c6" : @"*null",
            @"ns_st_ws" : @"full"

        }];
    });

    //#pragma Content Events

    it(@"videoContentStarted", ^{
        setupWithVideoPlaybackStarted(integration, streamingAnalytics);
        SEGTrackPayload *payload = [[SEGTrackPayload alloc] initWithEvent:@"Video Content Started" properties:@{
            @"asset_id" : @"3543",
            @"pod_id" : @"65462",
            @"title" : @"Big Trouble in Little Sanchez",
            @"keywords" : @"sci-fi",
            @"season" : @"2",
            @"episode" : @"7",
            @"genre" : @"cartoon",
            @"program" : @"Rick and Morty",
            @"channel" : @"Adult Swim",
            @"full_episode" : @"true"
        } context:@{}
            integrations:@{}];

        [integration track:payload];
        [verify(streamingAnalytics) notifyPlayWithLabels:@{
            @"ns_st_ci" : @"3543",
            @"ns_st_ep" : @"Big Trouble in Little Sanchez",
            @"ns_st_ge" : @"sci-fi",
            @"ns_st_sn" : @"2",
            @"ns_st_en" : @"7",
            @"ns_st_ge" : @"cartoon",
            @"ns_st_pr" : @"Rick and Morty",
            @"ns_st_pu" : @"Adult Swim",
            @"ns_st_ce" : @"true",
            @"c3" : @"*null",
            @"c4" : @"*null",
            @"c6" : @"*null"
        }];
    });

    it(@"videoContentPlaying", ^{
        setupWithVideoPlaybackStarted(integration, streamingAnalytics);
        SEGTrackPayload *payload = [[SEGTrackPayload alloc] initWithEvent:@"Video Content Playing" properties:@{
            @"asset_id" : @"3543",
            @"pod_id" : @"65462",
            @"title" : @"Big Trouble in Little Sanchez",
            @"keywords" : @"sci-fi",
            @"season" : @"2",
            @"episode" : @"7",
            @"genre" : @"cartoon",
            @"program" : @"Rick and Morty",
            @"channel" : @"Adult Swim",
            @"full_episode" : @"true",
            @"play_position" : @100
        } context:@{}
            integrations:@{}];

        [integration track:payload];
        [verify(streamingAnalytics) notifyPlayWithPosition:100 labels:@{
            @"ns_st_ci" : @"3543",
            @"ns_st_ep" : @"Big Trouble in Little Sanchez",
            @"ns_st_ge" : @"sci-fi",
            @"ns_st_sn" : @"2",
            @"ns_st_en" : @"7",
            @"ns_st_ge" : @"cartoon",
            @"ns_st_pr" : @"Rick and Morty",
            @"ns_st_pu" : @"Adult Swim",
            @"ns_st_ce" : @"true",
            @"c3" : @"*null",
            @"c4" : @"*null",
            @"c6" : @"*null"
        }];
    });

    it(@"videoContentCompleted", ^{
        setupWithVideoPlaybackStarted(integration, streamingAnalytics);
        SEGTrackPayload *payload = [[SEGTrackPayload alloc] initWithEvent:@"Video Content Completed" properties:@{
            @"pod_id" : @"23425",
            @"type" : @"mid-roll",
            @"publisher" : @"Adult Swim",
            @"total_length" : @"100",
            @"play_position" : @179
        } context:@{}
            integrations:@{}];

        [integration track:payload];
        [verify(streamingAnalytics) notifyEndWithPosition:179 labels:@{
            @"ns_st_ad" : @"mid-roll",
            @"ns_st_pu" : @"Adult Swim",
            @"ns_st_cl" : @"100",
            @"c3" : @"*null",
            @"c4" : @"*null",
            @"c6" : @"*null"
        }];
    });

    //#pragma Ad Events

    it(@"videoAdStarted", ^{
        setupWithVideoPlaybackStarted(integration, streamingAnalytics);
        SEGTrackPayload *payload = [[SEGTrackPayload alloc] initWithEvent:@"Video Ad Started" properties:@{
            @"asset_id" : @"1231312",
            @"pod_id" : @"43434234534",
            @"type" : @"mid-roll",
            @"total_length" : @"110",
            @"play_position" : @43,
            @"title" : @"Rick and Morty Ad"
        } context:@{}
            integrations:@{}];

        [integration track:payload];
        [verify(streamingAnalytics) notifyPlayWithPosition:43 labels:@{
            @"ns_st_ami" : @"1231312",
            @"ns_st_ad" : @"mid-roll",
            @"ns_st_cl" : @"110",
            @"ns_st_amt" : @"Rick and Morty Ad",
            @"c3" : @"*null",
            @"c4" : @"*null",
            @"c6" : @"*null"
        }];
    });

    it(@"videoAdPlaying", ^{
        setupWithVideoPlaybackStarted(integration, streamingAnalytics);
        SEGTrackPayload *payload = [[SEGTrackPayload alloc] initWithEvent:@"Video Ad Playing" properties:@{
            @"asset_id" : @"1231312",
            @"pod_id" : @"43434234534",
            @"type" : @"mid-roll",
            @"total_length" : @"110",
            @"play_position" : @50,
            @"title" : @"Rick and Morty Ad",
        } context:@{}
            integrations:@{}];

        [integration track:payload];
        [verify(streamingAnalytics) notifyPlayWithPosition:50 labels:@{
            @"ns_st_ami" : @"1231312",
            @"ns_st_ad" : @"mid-roll",
            @"ns_st_cl" : @"110",
            @"ns_st_amt" : @"Rick and Morty Ad",
            @"c3" : @"*null",
            @"c4" : @"*null",
            @"c6" : @"*null"
        }];
    });

    it(@"videoAdCompleted", ^{
        setupWithVideoPlaybackStarted(integration, streamingAnalytics);
        SEGTrackPayload *payload = [[SEGTrackPayload alloc] initWithEvent:@"Video Ad Completed" properties:@{
            @"asset_id" : @"1231312",
            @"pod_id" : @"43434234534",
            @"type" : @"mid-roll",
            @"total_length" : @"110",
            @"play_position" : @110,
            @"title" : @"Rick and Morty Ad"

        } context:@{}
            integrations:@{}];

        [integration track:payload];
        [verify(streamingAnalytics) notifyEndWithPosition:110 labels:@{
            @"ns_st_ami" : @"1231312",
            @"ns_st_ad" : @"mid-roll",
            @"ns_st_cl" : @"110",
            @"ns_st_amt" : @"Rick and Morty Ad",
            @"c3" : @"*null",
            @"c4" : @"*null",
            @"c6" : @"*null"
        }];
    });
});

SpecEnd
