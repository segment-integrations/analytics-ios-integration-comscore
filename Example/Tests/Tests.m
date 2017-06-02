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

    describe((@"convertFromKBPSToBPS"), ^{
        it(@"Will convert from KBPS to BPS", ^{
            NSDictionary *testDict = @{ @"key" : @17 };
            expect(convertFromKBPSToBPS(testDict, @"key")).to.equal(@17000);
        });

        it(@"Will skip String value", ^{
            NSDictionary *testDict = @{ @"key" : @"17" };
            expect(convertFromKBPSToBPS(testDict, @"key")).to.beNil();
        });

        it(@"Will skip NSDictionary value", ^{
            NSDictionary *contactDict = @{ @"addresses" : @{@"street" : @"2 Elm St.", @"city" : @"Reston"} };
            NSNumber *result = convertFromKBPSToBPS(contactDict, @"addresses");
            expect(result).to.beNil();
        });

        it(@"Will skip nested NSDictionary value", ^{
            NSDictionary *homeAddressDict = @{ @"street" : @"2 Elm St.",
                                               @"city" : @"Reston" };
            NSDictionary *addressesDict = @{ @"home" : homeAddressDict };
            NSDictionary *contactDict = @{ @"name" : @"Jim Ray",
                                           @"addresses" : addressesDict };
            expect(convertFromKBPSToBPS(contactDict, @"key")).to.beNil();
        });
    });

#pragma Playback Events

    it(@"videoPlaybackStarted", ^{
        SEGTrackPayload *payload = [[SEGTrackPayload alloc] initWithEvent:@"Video Playback Started" properties:@{
            @"content_asset_id" : @"1234",
            @"ad_type" : @"pre-roll",
            @"video_player" : @"youtube",

        } context:@{}
            integrations:@{}];

        [integration track:payload];
        [verify(streamingAnalytics) createPlaybackSessionWithLabels:@{
            @"ns_st_mp" : @"youtube"
        }];
        [[verify(streamingAnalytics) playbackSession] setAssetWithLabels:@{
            @"ns_st_ci" : @"1234",
        }];

    });

    it(@"videoPlaybackPaused with playPosition", ^{
        setupWithVideoPlaybackStarted(integration, streamingAnalytics);
        SEGTrackPayload *payload = [[SEGTrackPayload alloc] initWithEvent:@"Video Playback Paused" properties:@{
            @"content_asset_id" : @"7890",
            @"ad_type" : @"mid-roll",
            @"video_player" : @"vimeo",
            @"position" : @30,
            @"sound" : @100,
            @"full_screen" : @YES,
            @"bitrate" : @50
        } context:@{}
                                                             integrations:@{
                                                                 @"comScore" : @{
                                                                     @"c3" : @"test"
                                                                 }
                                                             }];

        [integration track:payload];
        [verify(streamingAnalytics) notifyPauseWithPosition:30];
        [[verifyCount(streamingAnalytics, times(2)) playbackSession] setLabels:@{
            @"ns_st_mp" : @"vimeo",
            @"ns_st_vo" : @"100",
            @"ns_st_ws" : @"full",
            @"ns_st_br" : @"50000",
            @"c3" : @"test",
            @"c4" : @"*null",
            @"c6" : @"*null"

        }];
    });

    it(@"videoPlaybackPaused fallsback to method without position", ^{
        setupWithVideoPlaybackStarted(integration, streamingAnalytics);
        SEGTrackPayload *payload = [[SEGTrackPayload alloc] initWithEvent:@"Video Playback Paused" properties:@{
            @"content_asset_id" : @"7890",
            @"ad_type" : @"mid-roll",
            @"video_player" : @"vimeo",
            @"sound" : @100,
            @"full_screen" : @YES,
            @"bitrate" : @50
        } context:@{}
                                                             integrations:@{
                                                                 @"comScore" : @{
                                                                     @"c3" : @"test"
                                                                 }
                                                             }];

        [integration track:payload];
        [verify(streamingAnalytics) notifyPause];
        [[verifyCount(streamingAnalytics, times(2)) playbackSession] setAssetWithLabels:@{
            @"ns_st_mp" : @"vimeo",
            @"ns_st_vo" : @"100",
            @"ns_st_ws" : @"full",
            @"ns_st_br" : @"50000",
            @"c3" : @"test",
            @"c4" : @"*null",
            @"c6" : @"*null"

        }];

    });

    it(@"videoPlaybackInterrupted with playPosition", ^{
        setupWithVideoPlaybackStarted(integration, streamingAnalytics);
        SEGTrackPayload *payload = [[SEGTrackPayload alloc] initWithEvent:@"Video Playback Interrupted" properties:@{
            @"content_asset_id" : @"7890",
            @"ad_type" : @"mid-roll",
            @"video_player" : @"vimeo",
            @"position" : @30,
            @"sound" : @100,
            @"full_screen" : @YES,
            @"bitrate" : @50
        } context:@{}
                                                             integrations:@{
                                                                 @"comScore" : @{
                                                                     @"c3" : @"test"
                                                                 }
                                                             }];

        [integration track:payload];
        [verify(streamingAnalytics) notifyPauseWithPosition:30];
        [[verifyCount(streamingAnalytics, times(2)) playbackSession] setLabels:@{
            @"ns_st_mp" : @"vimeo",
            @"ns_st_vo" : @"100",
            @"ns_st_ws" : @"full",
            @"ns_st_br" : @"50000",
            @"c3" : @"test",
            @"c4" : @"*null",
            @"c6" : @"*null"

        }];

    });

    it(@"videoPlaybackInterrupted fallsback to method without position", ^{
        setupWithVideoPlaybackStarted(integration, streamingAnalytics);
        SEGTrackPayload *payload = [[SEGTrackPayload alloc] initWithEvent:@"Video Playback Interrupted" properties:@{
            @"content_asset_id" : @"7890",
            @"ad_type" : @"mid-roll",
            @"video_player" : @"vimeo",
            @"sound" : @100,
            @"full_screen" : @YES,
            @"bitrate" : @50
        } context:@{}
                                                             integrations:@{
                                                                 @"comScore" : @{
                                                                     @"c3" : @"test"
                                                                 }
                                                             }];

        [integration track:payload];
        [verify(streamingAnalytics) notifyPause];
        [[verifyCount(streamingAnalytics, times(2)) playbackSession] setLabels:@{
            @"ns_st_mp" : @"vimeo",
            @"ns_st_vo" : @"100",
            @"ns_st_ws" : @"full",
            @"ns_st_br" : @"50000",
            @"c3" : @"test",
            @"c4" : @"*null",
            @"c6" : @"*null"

        }];
    });

    it(@"videoPlaybackBufferStarted with playPosition", ^{
        setupWithVideoPlaybackStarted(integration, streamingAnalytics);
        SEGTrackPayload *payload = [[SEGTrackPayload alloc] initWithEvent:@"Video Playback Buffer Started" properties:@{
            @"content_asset_id" : @"2340",
            @"ad_type" : @"post-roll",
            @"video_player" : @"youtube",
            @"position" : @190,
            @"sound" : @100,
            @"full_screen" : @NO,
            @"bitrate" : @50

        } context:@{}
                                                             integrations:@{
                                                                 @"comScore" : @{
                                                                     @"c4" : @"test"
                                                                 }
                                                             }];

        [integration track:payload];
        [verify(streamingAnalytics) notifyBufferStartWithPosition:190];
        [[verifyCount(streamingAnalytics, times(2)) playbackSession] setLabels:@{
            @"ns_st_ci" : @"2340",
            @"ns_st_ad" : @"post-roll",
            @"ns_st_mp" : @"youtube",
            @"ns_st_vo" : @"100",
            @"ns_st_ws" : @"norm",
            @"c3" : @"*null",
            @"c4" : @"test",
            @"c6" : @"*null",
            @"ns_st_br" : @"50000"

        }];

    });

    it(@"videoPlaybackBufferStarted fallsback to method without position", ^{
        setupWithVideoPlaybackStarted(integration, streamingAnalytics);
        SEGTrackPayload *payload = [[SEGTrackPayload alloc] initWithEvent:@"Video Playback Buffer Started" properties:@{
            @"content_asset_id" : @"2340",
            @"ad_type" : @"post-roll",
            @"video_player" : @"youtube",
            @"sound" : @100,
            @"full_screen" : @NO,
            @"bitrate" : @50

        } context:@{}
                                                             integrations:@{
                                                                 @"comScore" : @{
                                                                     @"c4" : @"test"
                                                                 }
                                                             }];

        [integration track:payload];
        [verify(streamingAnalytics) notifyBufferStart];
        [[verifyCount(streamingAnalytics, times(2)) playbackSession] setLabels:@{
            @"ns_st_mp" : @"youtube",
            @"ns_st_vo" : @"100",
            @"ns_st_ws" : @"norm",
            @"c3" : @"*null",
            @"c4" : @"test",
            @"c6" : @"*null",
            @"ns_st_br" : @"50000"

        }];

    });

    it(@"assigns default values when property not present on videoPlaybackBufferStarted", ^{
        setupWithVideoPlaybackStarted(integration, streamingAnalytics);
        SEGTrackPayload *payload = [[SEGTrackPayload alloc] initWithEvent:@"Video Playback Buffer Started" properties:@{
            @"ad_type" : @"post-roll",
            @"position" : @190,
            @"sound" : @100,
            @"full_screen" : @NO,
            @"bitrate" : @50

        } context:@{}
                                                             integrations:@{
                                                                 @"comScore" : @{
                                                                     @"c4" : @"test"
                                                                 }
                                                             }];

        [integration track:payload];
        [verify(streamingAnalytics) notifyBufferStartWithPosition:190];
        [[verifyCount(streamingAnalytics, times(2)) playbackSession] setLabels:@{
            @"ns_st_mp" : @"*null",
            @"ns_st_vo" : @"100",
            @"ns_st_ws" : @"norm",
            @"c3" : @"*null",
            @"c4" : @"test",
            @"c6" : @"*null",
            @"ns_st_br" : @"50000"

        }];

    });

    it(@"videoPlaybackBufferCompleted with playPosition", ^{
        setupWithVideoPlaybackStarted(integration, streamingAnalytics);
        SEGTrackPayload *payload = [[SEGTrackPayload alloc] initWithEvent:@"Video Playback Buffer Completed" properties:@{
            @"content_asset_id" : @"1230",
            @"ad_type" : @"mid-roll",
            @"video_player" : @"youtube",
            @"position" : @90,
            @"sound" : @100,
            @"full_screen" : @NO,
            @"bitrate" : @50

        } context:@{}
            integrations:@{}];

        [integration track:payload];
        [verify(streamingAnalytics) notifyBufferStopWithPosition:90];
        [[verifyCount(streamingAnalytics, times(2)) playbackSession] setLabels:@{
            @"ns_st_mp" : @"youtube",
            @"ns_st_vo" : @"100",
            @"c3" : @"*null",
            @"c4" : @"*null",
            @"c6" : @"*null",
            @"ns_st_ws" : @"norm",
            @"ns_st_br" : @"50000"

        }];
    });

    it(@"videoPlaybackBufferCompleted fallsback to method without position", ^{
        setupWithVideoPlaybackStarted(integration, streamingAnalytics);
        SEGTrackPayload *payload = [[SEGTrackPayload alloc] initWithEvent:@"Video Playback Buffer Completed" properties:@{
            @"content_asset_id" : @"1230",
            @"ad_type" : @"mid-roll",
            @"video_player" : @"youtube",
            @"sound" : @100,
            @"full_screen" : @NO,
            @"bitrate" : @50

        } context:@{}
            integrations:@{}];

        [integration track:payload];
        [verify(streamingAnalytics) notifyBufferStop];
        [[verifyCount(streamingAnalytics, times(2)) playbackSession] setLabels:@{
            @"ns_st_mp" : @"youtube",
            @"ns_st_vo" : @"100",
            @"c3" : @"*null",
            @"c4" : @"*null",
            @"c6" : @"*null",
            @"ns_st_ws" : @"norm",
            @"ns_st_br" : @"50000"

        }];
    });

    it(@"videoPlaybackSeekStarted with seekPosition", ^{
        setupWithVideoPlaybackStarted(integration, streamingAnalytics);
        SEGTrackPayload *payload = [[SEGTrackPayload alloc] initWithEvent:@"Video Playback Seek Started" properties:@{
            @"content_asset_id" : @"6352",
            @"ad_type" : @"pre-roll",
            @"video_player" : @"vimeo",
            @"seek_position" : @20,
            @"sound" : @100,
            @"full_screen" : @YES,
            @"bitrate" : @50

        } context:@{}
            integrations:@{}];

        [integration track:payload];
        [verify(streamingAnalytics) notifySeekStartWithPosition:20];
        [[verifyCount(streamingAnalytics, times(2)) playbackSession] setLabels:@{
            @"ns_st_mp" : @"vimeo",
            @"ns_st_vo" : @"100",
            @"c3" : @"*null",
            @"c4" : @"*null",
            @"c6" : @"*null",
            @"ns_st_ws" : @"full",
            @"ns_st_br" : @"50000"
        }];
    });

    it(@"videoPlaybackSeekStarted fallsback to method without seek_position", ^{
        setupWithVideoPlaybackStarted(integration, streamingAnalytics);
        SEGTrackPayload *payload = [[SEGTrackPayload alloc] initWithEvent:@"Video Playback Seek Started" properties:@{
            @"content_asset_id" : @"6352",
            @"ad_type" : @"pre-roll",
            @"video_player" : @"vimeo",
            @"sound" : @100,
            @"full_screen" : @YES,
            @"bitrate" : @50

        } context:@{}
            integrations:@{}];

        [integration track:payload];
        [verify(streamingAnalytics) notifySeekStart];
        [[verifyCount(streamingAnalytics, times(2)) playbackSession] setLabels:@{
            @"ns_st_mp" : @"vimeo",
            @"ns_st_vo" : @"100",
            @"c3" : @"*null",
            @"c4" : @"*null",
            @"c6" : @"*null",
            @"ns_st_ws" : @"full",
            @"ns_st_br" : @"50000"
        }];
    });


    it(@"videoPlaybackSeekCompleted with seekPosition", ^{
        setupWithVideoPlaybackStarted(integration, streamingAnalytics);
        SEGTrackPayload *payload = [[SEGTrackPayload alloc] initWithEvent:@"Video Playback Seek Completed" properties:@{
            @"content_asset_id" : @"6352",
            @"ad_type" : @"pre-roll",
            @"video_player" : @"vimeo",
            @"seek_position" : @20,
            @"sound" : @100,
            @"full_screen" : @YES,
            @"bitrate" : @50

        } context:@{}
            integrations:@{}];

        [integration track:payload];
        [verify(streamingAnalytics) notifyPlayWithPosition:20];
        [[verifyCount(streamingAnalytics, times(2)) playbackSession] setLabels:@{
            @"ns_st_mp" : @"vimeo",
            @"ns_st_vo" : @"100",
            @"c3" : @"*null",
            @"c4" : @"*null",
            @"c6" : @"*null",
            @"ns_st_ws" : @"full",
            @"ns_st_br" : @"50000"
        }];
    });

    it(@"videoPlaybackSeekCompleted fallsback to method without seek_position", ^{
        setupWithVideoPlaybackStarted(integration, streamingAnalytics);
        SEGTrackPayload *payload = [[SEGTrackPayload alloc] initWithEvent:@"Video Playback Seek Completed" properties:@{
            @"content_asset_id" : @"6352",
            @"ad_type" : @"pre-roll",
            @"video_player" : @"vimeo",
            @"sound" : @100,
            @"full_screen" : @YES,
            @"bitrate" : @50

        } context:@{}
            integrations:@{}];

        [integration track:payload];
        [verify(streamingAnalytics) notifyPlay];
        [[verifyCount(streamingAnalytics, times(2)) playbackSession] setLabels:@{
            @"ns_st_mp" : @"vimeo",
            @"ns_st_vo" : @"100",
            @"c3" : @"*null",
            @"c4" : @"*null",
            @"c6" : @"*null",
            @"ns_st_ws" : @"full",
            @"ns_st_br" : @"50000"
        }];
    });

    it(@"videoPlaybackResumed with playPosition", ^{
        setupWithVideoPlaybackStarted(integration, streamingAnalytics);
        SEGTrackPayload *payload = [[SEGTrackPayload alloc] initWithEvent:@"Video Playback Resumed" properties:@{
            @"content_asset_id" : @"2141",
            @"ad_type" : @"mid-roll",
            @"video_player" : @"youtube",
            @"position" : @34,
            @"sound" : @100,
            @"full_screen" : @YES,
            @"bitrate" : @50

        } context:@{}
            integrations:@{}];

        [integration track:payload];
        [verify(streamingAnalytics) notifyPlayWithPosition:34];
        [[verifyCount(streamingAnalytics, times(2)) playbackSession] setLabels:@{
            @"ns_st_mp" : @"youtube",
            @"ns_st_vo" : @"100",
            @"c3" : @"*null",
            @"c4" : @"*null",
            @"c6" : @"*null",
            @"ns_st_ws" : @"full",
            @"ns_st_br" : @"50000"

        }];
    });

    it(@"videoPlaybackResumed fallsback to method without position", ^{
        setupWithVideoPlaybackStarted(integration, streamingAnalytics);
        SEGTrackPayload *payload = [[SEGTrackPayload alloc] initWithEvent:@"Video Playback Resumed" properties:@{
            @"content_asset_id" : @"2141",
            @"ad_type" : @"mid-roll",
            @"video_player" : @"youtube",
            @"sound" : @100,
            @"full_screen" : @YES,
            @"bitrate" : @50

        } context:@{}
            integrations:@{}];

        [integration track:payload];
        [verify(streamingAnalytics) notifyPlay];
        [[verifyCount(streamingAnalytics, times(2)) playbackSession] setLabels:@{
            @"ns_st_mp" : @"youtube",
            @"ns_st_vo" : @"100",
            @"c3" : @"*null",
            @"c4" : @"*null",
            @"c6" : @"*null",
            @"ns_st_ws" : @"full",
            @"ns_st_br" : @"50000"

        }];
    });


    //#pragma Content Events

    it(@"videoContentStarted with playPosition", ^{
        setupWithVideoPlaybackStarted(integration, streamingAnalytics);
        SEGTrackPayload *payload = [[SEGTrackPayload alloc] initWithEvent:@"Video Content Started" properties:@{
            @"asset_id" : @"3543",
            @"pod_id" : @"65462",
            @"title" : @"Big Trouble in Little Sanchez",
            @"season" : @"2",
            @"episode" : @"7",
            @"genre" : @"cartoon",
            @"program" : @"Rick and Morty",
            @"total_length" : @400,
            @"full_episode" : @"true",
            @"publisher" : @"Turner Broadcasting Network",
            @"position" : @22,
            @"channel" : @"Cartoon Network"
        } context:@{}
                                                             integrations:@{
                                                                 @"comScore" : @{
                                                                     @"tvAirdate" : @"2017-05-22"
                                                                 }
                                                             }];

        [integration track:payload];
        [verify(streamingAnalytics) notifyPlayWithPosition:22];
        [[verifyCount(streamingAnalytics, times(2)) playbackSession] setAssetWithLabels:@{
            @"ns_st_ci" : @"3543",
            @"ns_st_ep" : @"Big Trouble in Little Sanchez",
            @"ns_st_sn" : @"2",
            @"ns_st_en" : @"7",
            @"ns_st_ge" : @"cartoon",
            @"ns_st_pr" : @"Rick and Morty",
            @"ns_st_cl" : @"400000",
            @"ns_st_ce" : @"true",
            @"ns_st_pu" : @"Turner Broadcasting Network",
            @"ns_st_st" : @"Cartoon Network",
            @"ns_st_pn" : @"*null",
            @"c3" : @"*null",
            @"c4" : @"*null",
            @"c6" : @"*null",
            @"ns_st_tdt" : @"2017-05-22",
            @"ns_st_ddt" : @"*null",
            @"ns_st_ct" : @"vc00"
        }];
    });

    it(@"videoContentStarted fallsback to method without position", ^{
        setupWithVideoPlaybackStarted(integration, streamingAnalytics);
        SEGTrackPayload *payload = [[SEGTrackPayload alloc] initWithEvent:@"Video Content Started" properties:@{
            @"asset_id" : @"3543",
            @"pod_id" : @"65462",
            @"title" : @"Big Trouble in Little Sanchez",
            @"season" : @"2",
            @"episode" : @"7",
            @"genre" : @"cartoon",
            @"program" : @"Rick and Morty",
            @"total_length" : @400,
            @"full_episode" : @"true",
            @"publisher" : @"Turner Broadcasting Network",
            @"pod_id" : @"1",
            @"channel" : @"Cartoon Network"
        } context:@{}
                                                             integrations:@{
                                                                 @"comScore" : @{
                                                                     @"tvAirdate" : @"2017-05-22"
                                                                 }
                                                             }];

        [integration track:payload];
        [verify(streamingAnalytics) notifyPlay];
        [[verifyCount(streamingAnalytics, times(2)) playbackSession] setAssetWithLabels:@{
            @"ns_st_ci" : @"3543",
            @"ns_st_ep" : @"Big Trouble in Little Sanchez",
            @"ns_st_sn" : @"2",
            @"ns_st_en" : @"7",
            @"ns_st_ge" : @"cartoon",
            @"ns_st_pr" : @"Rick and Morty",
            @"ns_st_cl" : @"400000",
            @"ns_st_ce" : @"true",
            @"ns_st_pu" : @"Turner Broadcasting Network",
            @"ns_st_pn" : @"1",
            @"ns_st_st" : @"Cartoon Network",
            @"c3" : @"*null",
            @"c4" : @"*null",
            @"c6" : @"*null",
            @"ns_st_tdt" : @"2017-05-22",
            @"ns_st_ddt" : @"*null",
            @"ns_st_ct" : @"vc00"
        }];
    });


    it(@"videoContentPlaying with playPosition", ^{
        setupWithVideoPlaybackStarted(integration, streamingAnalytics);
        SEGTrackPayload *payload = [[SEGTrackPayload alloc] initWithEvent:@"Video Content Playing" properties:@{
            @"asset_id" : @"3543",
            @"pod_id" : @"65462",
            @"title" : @"Big Trouble in Little Sanchez",
            @"season" : @"2",
            @"episode" : @"7",
            @"genre" : @"cartoon",
            @"program" : @"Rick and Morty",
            @"total_length" : @400,
            @"full_episode" : @"true",
            @"publisher" : @"Turner Broadcasting Network",
            @"channel" : @"Cartoon Network",
            @"position" : @50

        } context:@{}
            integrations:@{}];

        [integration track:payload];
        [verify(streamingAnalytics) notifyPlayWithPosition:50];
        [[verifyCount(streamingAnalytics, times(2)) playbackSession] setAssetWithLabels:@{
            @"ns_st_ci" : @"3543",
            @"ns_st_ep" : @"Big Trouble in Little Sanchez",
            @"ns_st_sn" : @"2",
            @"ns_st_en" : @"7",
            @"ns_st_ge" : @"cartoon",
            @"ns_st_pr" : @"Rick and Morty",
            @"ns_st_cl" : @"400000",
            @"ns_st_ce" : @"true",
            @"ns_st_pu" : @"Turner Broadcasting Network",
            @"ns_st_pn" : @"*null",
            @"ns_st_st" : @"Cartoon Network",
            @"c3" : @"*null",
            @"c4" : @"*null",
            @"c6" : @"*null",
            @"ns_st_tdt" : @"*null",
            @"ns_st_ddt" : @"*null",
            @"ns_st_ct" : @"vc00"
        }];
    });

    it(@"videoContentPlaying fallsback to method without position", ^{
        setupWithVideoPlaybackStarted(integration, streamingAnalytics);
        SEGTrackPayload *payload = [[SEGTrackPayload alloc] initWithEvent:@"Video Content Playing" properties:@{
            @"asset_id" : @"3543",
            @"pod_id" : @"65462",
            @"title" : @"Big Trouble in Little Sanchez",
            @"season" : @"2",
            @"episode" : @"7",
            @"genre" : @"cartoon",
            @"program" : @"Rick and Morty",
            @"total_length" : @400,
            @"full_episode" : @"true",
            @"publisher" : @"Turner Broadcasting Network",
            @"channel" : @"Cartoon Network"

        } context:@{}
            integrations:@{}];

        [integration track:payload];
        [verify(streamingAnalytics) notifyPlay];
        [[verifyCount(streamingAnalytics, times(2)) playbackSession] setAssetWithLabels:@{
            @"ns_st_ci" : @"3543",
            @"ns_st_ep" : @"Big Trouble in Little Sanchez",
            @"ns_st_sn" : @"2",
            @"ns_st_en" : @"7",
            @"ns_st_ge" : @"cartoon",
            @"ns_st_pr" : @"Rick and Morty",
            @"ns_st_cl" : @"400000",
            @"ns_st_pn" : @"*null",
            @"ns_st_ce" : @"true",
            @"ns_st_pu" : @"Turner Broadcasting Network",
            @"ns_st_st" : @"Cartoon Network",
            @"c3" : @"*null",
            @"c4" : @"*null",
            @"c6" : @"*null",
            @"ns_st_tdt" : @"*null",
            @"ns_st_ddt" : @"*null",
            @"ns_st_ct" : @"vc00"
        }];
    });

    it(@"videoContentCompleted with playPosition", ^{
        setupWithVideoPlaybackStarted(integration, streamingAnalytics);
        SEGTrackPayload *payload = [[SEGTrackPayload alloc] initWithEvent:@"Video Content Completed" properties:@{
            @"asset_id" : @"3543",
            @"pod_id" : @"65462",
            @"title" : @"Big Trouble in Little Sanchez",
            @"season" : @"2",
            @"episode" : @"7",
            @"genre" : @"cartoon",
            @"program" : @"Rick and Morty",
            @"total_length" : @400,
            @"full_episode" : @"true",
            @"publisher" : @"Turner Broadcasting Network",
            @"channel" : @"Cartoon Network",
            @"position" : @100
        } context:@{}
            integrations:@{}];

        [integration track:payload];
        [verify(streamingAnalytics) notifyEndWithPosition:100];
        [[verify(streamingAnalytics) playbackSession] setAssetWithLabels:@{
            @"ns_st_ci" : @"3543",
            @"ns_st_ep" : @"Big Trouble in Little Sanchez",
            @"ns_st_sn" : @"2",
            @"ns_st_en" : @"7",
            @"ns_st_ge" : @"cartoon",
            @"ns_st_pr" : @"Rick and Morty",
            @"ns_st_cl" : @"400000",
            @"ns_st_ce" : @"true",
            @"ns_st_pu" : @"Turner Broadcasting Network",
            @"ns_st_st" : @"Cartoon Network",
            @"ns_st_pn" : @"*null",
            @"ns_st_tdt" : @"*null",
            @"ns_st_ddt" : @"*null",
            @"c3" : @"*null",
            @"c4" : @"*null",
            @"c6" : @"*null",
            @"ns_st_ct" : @"vc00"
        }];
    });

    it(@"videoContentCompleted fallsback to method without position", ^{
        setupWithVideoPlaybackStarted(integration, streamingAnalytics);
        SEGTrackPayload *payload = [[SEGTrackPayload alloc] initWithEvent:@"Video Content Completed" properties:@{
            @"asset_id" : @"3543",
            @"pod_id" : @"65462",
            @"title" : @"Big Trouble in Little Sanchez",
            @"season" : @"2",
            @"episode" : @"7",
            @"genre" : @"cartoon",
            @"program" : @"Rick and Morty",
            @"total_length" : @400,
            @"full_episode" : @"true",
            @"publisher" : @"Turner Broadcasting Network",
            @"channel" : @"Cartoon Network"
        } context:@{}
            integrations:@{}];

        [integration track:payload];
        [verify(streamingAnalytics) notifyEnd];
        [[verify(streamingAnalytics) playbackSession] setAssetWithLabels:@{
            @"ns_st_ci" : @"3543",
            @"ns_st_ep" : @"Big Trouble in Little Sanchez",
            @"ns_st_sn" : @"2",
            @"ns_st_en" : @"7",
            @"ns_st_ge" : @"cartoon",
            @"ns_st_pr" : @"Rick and Morty",
            @"ns_st_cl" : @"400000",
            @"ns_st_ce" : @"true",
            @"ns_st_pu" : @"Turner Broadcasting Network",
            @"ns_st_st" : @"Cartoon Network",
            @"ns_st_pn" : @"*null",
            @"ns_st_tdt" : @"*null",
            @"ns_st_ddt" : @"*null",
            @"c3" : @"*null",
            @"c4" : @"*null",
            @"c6" : @"*null",
            @"ns_st_ct" : @"vc00"
        }];
    });


    //#pragma Ad Events

    it(@"videoAdStarted with playPosition", ^{
        setupWithVideoPlaybackStarted(integration, streamingAnalytics);
        SEGTrackPayload *payload = [[SEGTrackPayload alloc] initWithEvent:@"Video Ad Started" properties:@{
            @"asset_id" : @"1231312",
            @"pod_id" : @"43434234534",
            @"type" : @"mid-roll",
            @"total_length" : @110,
            @"position" : @43,
            @"publisher" : @"Adult Swim",
            @"title" : @"Rick and Morty Ad"
        } context:@{}
            integrations:@{}];

        [integration track:payload];
        [verify(streamingAnalytics) notifyPlayWithPosition:43];
        [[verifyCount(streamingAnalytics, times(3)) playbackSession] setAssetWithLabels:@{
            @"ns_st_ami" : @"1231312",
            @"ns_st_ad" : @"mid-roll",
            @"ns_st_cl" : @"110000",
            @"ns_st_amt" : @"Rick and Morty Ad",
            @"ns_st_pu" : @"Adult Swim",
            @"c3" : @"*null",
            @"c4" : @"*null",
            @"c6" : @"*null",
            @"ns_st_ct" : @"va00",
            @"ns_st_ci" : @"*null"
        }];
    });

    it(@"videoAdStarted fallsback to method without position", ^{
        setupWithVideoPlaybackStarted(integration, streamingAnalytics);
        SEGTrackPayload *payload = [[SEGTrackPayload alloc] initWithEvent:@"Video Ad Started" properties:@{
            @"asset_id" : @"1231312",
            @"pod_id" : @"43434234534",
            @"type" : @"mid-roll",
            @"total_length" : @110,
            @"title" : @"Rick and Morty Ad"
        } context:@{}
            integrations:@{}];

        [integration track:payload];
        [verify(streamingAnalytics) notifyPlay];
        [[verifyCount(streamingAnalytics, times(3)) playbackSession] setAssetWithLabels:@{
            @"ns_st_ami" : @"1231312",
            @"ns_st_ad" : @"mid-roll",
            @"ns_st_cl" : @"110000",
            @"ns_st_amt" : @"Rick and Morty Ad",
            @"ns_st_pu" : @"*null",
            @"c3" : @"*null",
            @"c4" : @"*null",
            @"c6" : @"*null",
            @"ns_st_ct" : @"va00",
            @"ns_st_ci" : @"*null"

        }];
    });

    it(@"videoAdStarted fallsback to @'1' without correct type value", ^{
        setupWithVideoPlaybackStarted(integration, streamingAnalytics);
        SEGTrackPayload *payload = [[SEGTrackPayload alloc] initWithEvent:@"Video Ad Started" properties:@{
            @"asset_id" : @"1231312",
            @"pod_id" : @"43434234534",
            @"type" : @"not an ad type",
            @"total_length" : @110,
            @"title" : @"Rick and Morty Ad"
        } context:@{}
            integrations:@{}];

        [integration track:payload];
        [verify(streamingAnalytics) notifyPlay];
        [[verifyCount(streamingAnalytics, times(3)) playbackSession] setAssetWithLabels:@{
            @"ns_st_ami" : @"1231312",
            @"ns_st_ad" : @"1",
            @"ns_st_cl" : @"110000",
            @"ns_st_amt" : @"Rick and Morty Ad",
            @"ns_st_pu" : @"*null",
            @"c3" : @"*null",
            @"c4" : @"*null",
            @"c6" : @"*null",
            @"ns_st_ct" : @"va00",
            @"ns_st_ci" : @"*null"

        }];
    });

    it(@"videoAdPlaying with playPosition", ^{
        setupWithVideoPlaybackStarted(integration, streamingAnalytics);
        SEGTrackPayload *payload = [[SEGTrackPayload alloc] initWithEvent:@"Video Ad Playing" properties:@{
            @"asset_id" : @"1231312",
            @"pod_id" : @"43434234534",
            @"type" : @"mid-roll",
            @"total_length" : @110,
            @"position" : @50,
            @"title" : @"Rick and Morty Ad",
        } context:@{}
            integrations:@{}];

        [integration track:payload];
        [verify(streamingAnalytics) notifyPlayWithPosition:50];
        [[verify(streamingAnalytics) playbackSession] setAssetWithLabels:@{
            @"ns_st_ami" : @"1231312",
            @"ns_st_ad" : @"mid-roll",
            @"ns_st_cl" : @"110000",
            @"ns_st_amt" : @"Rick and Morty Ad",
            @"ns_st_pu" : @"*null",
            @"c3" : @"*null",
            @"c4" : @"*null",
            @"c6" : @"*null",
            @"ns_st_ct" : @"va00",
            @"ns_st_ci" : @"3543"

        }];
    });

    it(@"videoAdPlaying fallsback to method without position", ^{
        setupWithVideoPlaybackStarted(integration, streamingAnalytics);
        SEGTrackPayload *payload = [[SEGTrackPayload alloc] initWithEvent:@"Video Ad Playing" properties:@{
            @"asset_id" : @"1231312",
            @"pod_id" : @"43434234534",
            @"type" : @"mid-roll",
            @"total_length" : @110,
            @"title" : @"Rick and Morty Ad"
        } context:@{}
            integrations:@{}];

        [integration track:payload];
        [verify(streamingAnalytics) notifyPlay];
        [[verify(streamingAnalytics) playbackSession] setAssetWithLabels:@{
            @"ns_st_ami" : @"1231312",
            @"ns_st_ad" : @"mid-roll",
            @"ns_st_cl" : @"110000",
            @"ns_st_amt" : @"Rick and Morty Ad",
            @"ns_st_pu" : @"*null",
            @"c3" : @"*null",
            @"c4" : @"*null",
            @"c6" : @"*null",
            @"ns_st_ct" : @"va00",
            @"ns_st_ci" : @"3543"

        }];
    });

    it(@"videoAdCompleted with playPosition", ^{
        setupWithVideoPlaybackStarted(integration, streamingAnalytics);
        SEGTrackPayload *payload = [[SEGTrackPayload alloc] initWithEvent:@"Video Ad Completed" properties:@{
            @"asset_id" : @"1231312",
            @"pod_id" : @"43434234534",
            @"type" : @"mid-roll",
            @"total_length" : @110,
            @"position" : @110,
            @"title" : @"Rick and Morty Ad"

        } context:@{}
            integrations:@{}];

        [integration track:payload];
        [verify(streamingAnalytics) notifyEndWithPosition:110];
        [[verify(streamingAnalytics) playbackSession] setAssetWithLabels:@{
            @"ns_st_ami" : @"1231312",
            @"ns_st_ad" : @"mid-roll",
            @"ns_st_cl" : @"110000",
            @"ns_st_amt" : @"Rick and Morty Ad",
            @"ns_st_pu" : @"*null",
            @"c3" : @"*null",
            @"c4" : @"*null",
            @"c6" : @"*null",
            @"ns_st_ct" : @"va00"
        }];
    });

    it(@"videoAdCompleted maps adClassificationType value pass in integrations object", ^{
        setupWithVideoPlaybackStarted(integration, streamingAnalytics);
        SEGTrackPayload *payload = [[SEGTrackPayload alloc] initWithEvent:@"Video Ad Completed" properties:@{
            @"asset_id" : @"1231312",
            @"pod_id" : @"43434234534",
            @"type" : @"mid-roll",
            @"total_length" : @110,
            @"position" : @110,
            @"title" : @"Rick and Morty Ad"

        } context:@{}
                                                             integrations:@{ @"comScore" : @{
                                                                 @"adClassificationType" : @"va12"
                                                             } }];

        [integration track:payload];
        [verify(streamingAnalytics) notifyEndWithPosition:110];
        [[verify(streamingAnalytics) playbackSession] setAssetWithLabels:@{
            @"ns_st_ami" : @"1231312",
            @"ns_st_ad" : @"mid-roll",
            @"ns_st_cl" : @"110000",
            @"ns_st_amt" : @"Rick and Morty Ad",
            @"ns_st_pu" : @"*null",
            @"c3" : @"*null",
            @"c4" : @"*null",
            @"c6" : @"*null",
            @"ns_st_ct" : @"va12"
        }];
    });

    it(@"videoAdCompleted fallsback to method without position", ^{
        setupWithVideoPlaybackStarted(integration, streamingAnalytics);
        SEGTrackPayload *payload = [[SEGTrackPayload alloc] initWithEvent:@"Video Ad Completed" properties:@{
            @"asset_id" : @"1231312",
            @"pod_id" : @"43434234534",
            @"type" : @"mid-roll",
            @"total_length" : @110,
            @"title" : @"Rick and Morty Ad"

        } context:@{}
            integrations:@{}];

        [integration track:payload];
        [verify(streamingAnalytics) notifyEnd];
        [[verify(streamingAnalytics) playbackSession] setAssetWithLabels:@{
            @"ns_st_ami" : @"1231312",
            @"ns_st_ad" : @"mid-roll",
            @"ns_st_cl" : @"110000",
            @"ns_st_amt" : @"Rick and Morty Ad",
            @"ns_st_pu" : @"*null",
            @"c3" : @"*null",
            @"c4" : @"*null",
            @"c6" : @"*null",
            @"ns_st_ct" : @"va00"
        }];
    });
});

SpecEnd
