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
    __block SCORStreamingAnalytics *mockStreamingAnalytics;
    __block SEGComScoreIntegration *integration;
    __block SCORStreamingConfiguration *mockConfiguration;
//    __block SCORStreamingPlaybackSession *mockPlaybackSession;
//    __block SCORStreamingAsset *mockAsset;

    beforeEach(^{
        scorAnalyticsClassMock = mockClass([SCORAnalytics class]);
        mockStreamingAnalytics = mock([SCORStreamingAnalytics class]);
        SEGMockStreamingAnalyticsFactory *mockStreamAnalyticsFactory = [[SEGMockStreamingAnalyticsFactory alloc] init];
        mockStreamAnalyticsFactory.streamingAnalytics = mockStreamingAnalytics;

        [given(mockStreamingAnalytics.configuration) willReturn:mockConfiguration];

        integration = [[SEGComScoreIntegration alloc] initWithSettings:@{
            @"c2" : @"23243060",
        } andComScore:scorAnalyticsClassMock andStreamingAnalyticsFactory:mockStreamAnalyticsFactory];

    });

    it(@"identify with Traits", ^{
        SCORConfiguration *configuration = mock([SCORConfiguration class]);
        [given([scorAnalyticsClassMock configuration]) willReturn:configuration];

        SEGIdentifyPayload *payload = [[SEGIdentifyPayload alloc] initWithUserId:@"44"
            anonymousId:nil
            traits:@{ @"name" : @"Milhouse Van Houten",
                      @"gender" : @"male",
                      @"emotion" : @"nerdy",
                      @"isMarried" : @YES,
                      @"kids" : @[@"Dennis", @"Donald", @"Bunny"],
                      @"number": @25
            }
            context:@{}
            integrations:@{}];

        [integration identify:payload];

        [verify(configuration) setPersistentLabelWithName:@"name" value:@"Milhouse Van Houten"];
        [verify(configuration) setPersistentLabelWithName:@"gender" value:@"male"];
        [verify(configuration) setPersistentLabelWithName:@"emotion" value:@"nerdy"];
        [verify(configuration) setPersistentLabelWithName:@"isMarried" value:@"1"];
        [verify(configuration) setPersistentLabelWithName:@"kids" value:@"Dennis,Donald,Bunny"];
        [verify(configuration) setPersistentLabelWithName:@"number" value:@"25"];
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

describe(@"After Video Playback Started", ^{
        beforeEach(^{
            integration.streamAnalytics = mockStreamingAnalytics;
        });


        it(@"videoPlaybackStarted", ^{
            SEGTrackPayload *payload = [[SEGTrackPayload alloc] initWithEvent:@"Video Playback Started" properties:@{
                @"content_asset_id" : @"1234",
                @"ad_type" : @"pre-roll",
                @"video_player" : @"youtube",

            } context:@{}
                integrations:@{}];
            
            
            HCArgumentCaptor *captor = [[HCArgumentCaptor alloc] init];
            SCORStreamingContentMetadata *contentMetaData = [SCORStreamingContentMetadata contentMetadataWithBuilderBlock:^(SCORStreamingContentMetadataBuilder *builder) {
                  [builder setCustomLabels:@{  @"ns_st_ci" : @"1234",
                                               @"ns_st_mp": @"youtube"
                  }];
             }];

            [integration track:payload];
            [verify(mockStreamingAnalytics) createPlaybackSession];
            
            [mockStreamingAnalytics setMetadata:contentMetaData];
            [verifyCount(mockStreamingAnalytics, times(2)) setMetadata:captor];
            id argumentId = captor.value;
            assertThat(argumentId, notNilValue());
            assertThat(argumentId, is(contentMetaData));
            expect(integration.configurationLabels).to.equal(@{  @"ns_st_ci" : @"1234",
                                                                 @"ns_st_mp": @"youtube"
                  });
        });
    

        it(@"videoPlaybackPaused", ^{

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
                                                                     @"com-score" : @{
                                                                         @"c3" : @"test"
                                                                     }
                                                                 }];
            
            HCArgumentCaptor *captor = [[HCArgumentCaptor alloc] init];
            SCORStreamingContentMetadata *contentMetaData = [SCORStreamingContentMetadata contentMetadataWithBuilderBlock:^(SCORStreamingContentMetadataBuilder *builder) {
                [builder setCustomLabels:@{ @"ns_st_ci": @"7890",
                                             @"ns_st_mp" : @"vimeo",
                                             @"ns_st_vo" : @"100",
                                             @"ns_st_ws" : @"full",
                                             @"ns_st_br" : @"50000",
                                             @"c3" : @"test",
                                             @"c4" : @"*null",
                                             @"c6" : @"*null"
                 }];
            }];

            [integration track:payload];
            [verify(mockStreamingAnalytics) notifyPause];
            
            [mockStreamingAnalytics setMetadata:contentMetaData];
            [verifyCount(mockStreamingAnalytics, times(2)) setMetadata:captor];
            id argumentId = captor.value;
            assertThat(argumentId, notNilValue());
            assertThat(argumentId, is(contentMetaData));
        });

        it(@"videoPlaybackInterrupted", ^{

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
                                                                     @"com-score" : @{
                                                                         @"c3" : @"test"
                                                                     }
                                                                 }];
            
            HCArgumentCaptor *captor = [[HCArgumentCaptor alloc] init];
            SCORStreamingContentMetadata *contentMetaData = [SCORStreamingContentMetadata contentMetadataWithBuilderBlock:^(SCORStreamingContentMetadataBuilder *builder) {
                [builder setCustomLabels:@{@"ns_st_ci": @"7890",
                                           @"ns_st_mp" : @"vimeo",
                                           @"ns_st_vo" : @"100",
                                           @"ns_st_ws" : @"full",
                                           @"ns_st_br" : @"50000",
                                           @"c3" : @"test",
                                           @"c4" : @"*null",
                                           @"c6" : @"*null"

                            
                            }];
            }];

            [integration track:payload];
            [verify(mockStreamingAnalytics) notifyPause];
            
            [mockStreamingAnalytics setMetadata:contentMetaData];
            [verifyCount(mockStreamingAnalytics, times(2)) setMetadata:captor];
            id argumentId = captor.value;
            assertThat(argumentId, notNilValue());
            assertThat(argumentId, is(contentMetaData));
        });

        it(@"videoPlaybackBufferStarted with playPosition", ^{

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
                                                                     @"com-score" : @{
                                                                         @"c4" : @"test"
                                                                     }
                                                                 }];
            
            HCArgumentCaptor *captor = [[HCArgumentCaptor alloc] init];
            SCORStreamingContentMetadata *contentMetaData = [SCORStreamingContentMetadata contentMetadataWithBuilderBlock:^(SCORStreamingContentMetadataBuilder *builder) {
                [builder setCustomLabels:@{ @"ns_st_ci": @"2340",
                                            @"ns_st_mp" : @"youtube",
                                             @"ns_st_vo" : @"100",
                                             @"ns_st_ws" : @"norm",
                                             @"c3" : @"*null",
                                             @"c4" : @"test",
                                             @"c6" : @"*null",
                                             @"ns_st_br" : @"50000" }];
            }];


            [integration track:payload];
            [verify(mockStreamingAnalytics) notifyBufferStart];
            [verify(mockStreamingAnalytics) startFromPosition:190];
            
            [mockStreamingAnalytics setMetadata:contentMetaData];
            [verifyCount(mockStreamingAnalytics, times(2)) setMetadata:captor];
            id argumentId = captor.value;
            assertThat(argumentId, notNilValue());
            assertThat(argumentId, is(contentMetaData));

        });
    
        it(@"videoPlaybackBufferStarted fallback to method without position", ^{

            SEGTrackPayload *payload = [[SEGTrackPayload alloc] initWithEvent:@"Video Playback Buffer Started" properties:@{
                @"content_asset_id" : @"2340",
                @"ad_type" : @"post-roll",
                @"video_player" : @"youtube",
                @"sound" : @100,
                @"full_screen" : @NO,
                @"bitrate" : @50

            } context:@{}
                                                                 integrations:@{
                                                                     @"com-score" : @{
                                                                         @"c4" : @"test"
                                                                     }
                                                                 }];
            
            HCArgumentCaptor *captor = [[HCArgumentCaptor alloc] init];
            SCORStreamingContentMetadata *contentMetaData = [SCORStreamingContentMetadata contentMetadataWithBuilderBlock:^(SCORStreamingContentMetadataBuilder *builder) {
                [builder setCustomLabels:@{ @"ns_st_ci": @"2340",
                                            @"ns_st_mp" : @"youtube",
                                            @"ns_st_vo" : @"100",
                                            @"ns_st_ws" : @"norm",
                                            @"c3" : @"*null",
                                            @"c4" : @"test",
                                            @"c6" : @"*null",
                                            @"ns_st_br" : @"50000" }];
            }];


            [integration track:payload];
            [verify(mockStreamingAnalytics) notifyBufferStart];
            
            [mockStreamingAnalytics setMetadata:contentMetaData];
            [verifyCount(mockStreamingAnalytics, times(2)) setMetadata:captor];
            id argumentId = captor.value;
            assertThat(argumentId, notNilValue());
            assertThat(argumentId, is(contentMetaData));

        });
    
    
        

        it(@"videoPlaybackBufferCompleted with playPosition", ^{

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
            
            HCArgumentCaptor *captor = [[HCArgumentCaptor alloc] init];
            SCORStreamingContentMetadata *contentMetaData = [SCORStreamingContentMetadata contentMetadataWithBuilderBlock:^(SCORStreamingContentMetadataBuilder *builder) {
                [builder setCustomLabels:@{ @"ns_st_ci": @"1230",
                                            @"ns_st_mp" : @"youtube",
                                            @"ns_st_vo" : @"100",
                                            @"c3" : @"*null",
                                            @"c4" : @"*null",
                                            @"c6" : @"*null",
                                            @"ns_st_ws" : @"norm",
                                            @"ns_st_br" : @"50000" }];
            }];

            [integration track:payload];
            [verify(mockStreamingAnalytics) notifyBufferStop];
            [verify(mockStreamingAnalytics) startFromPosition:90];
            
            [mockStreamingAnalytics setMetadata:contentMetaData];
            [verifyCount(mockStreamingAnalytics, times(2)) setMetadata:captor];
            id argumentId = captor.value;
            assertThat(argumentId, notNilValue());
            assertThat(argumentId, is(contentMetaData));
        });
    
        it(@"videoPlaybackBufferCompleted fallsback to method without position", ^{

            SEGTrackPayload *payload = [[SEGTrackPayload alloc] initWithEvent:@"Video Playback Buffer Completed" properties:@{
                @"content_asset_id" : @"1230",
                @"ad_type" : @"mid-roll",
                @"video_player" : @"youtube",
                @"sound" : @100,
                @"full_screen" : @NO,
                @"bitrate" : @50

            } context:@{}
                integrations:@{}];
            
            HCArgumentCaptor *captor = [[HCArgumentCaptor alloc] init];
            SCORStreamingContentMetadata *contentMetaData = [SCORStreamingContentMetadata contentMetadataWithBuilderBlock:^(SCORStreamingContentMetadataBuilder *builder) {
                [builder setCustomLabels:@{ @"ns_st_ci": @"1230",
                                            @"ns_st_mp" : @"youtube",
                                            @"ns_st_vo" : @"100",
                                            @"c3" : @"*null",
                                            @"c4" : @"*null",
                                            @"c6" : @"*null",
                                            @"ns_st_ws" : @"norm",
                                            @"ns_st_br" : @"50000" }];
            }];

            [integration track:payload];
            [verify(mockStreamingAnalytics) notifyBufferStop];

            [mockStreamingAnalytics setMetadata:contentMetaData];
            [verifyCount(mockStreamingAnalytics, times(2)) setMetadata:captor];
            id argumentId = captor.value;
            assertThat(argumentId, notNilValue());
            assertThat(argumentId, is(contentMetaData));
        });

        it(@"videoPlaybackSeekStarted with seekPosition", ^{

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
            
            HCArgumentCaptor *captor = [[HCArgumentCaptor alloc] init];
            SCORStreamingContentMetadata *contentMetaData = [SCORStreamingContentMetadata contentMetadataWithBuilderBlock:^(SCORStreamingContentMetadataBuilder *builder) {
               [builder setCustomLabels:@{ @"ns_st_ci": @"6352",
                                           @"ns_st_mp" : @"vimeo",
                                           @"ns_st_vo" : @"100",
                                           @"c3" : @"*null",
                                           @"c4" : @"*null",
                                           @"c6" : @"*null",
                                           @"ns_st_ws" : @"full",
                                           @"ns_st_br" : @"50000" }];
           }];

            [integration track:payload];
            [verify(mockStreamingAnalytics) notifySeekStart];
            [verify(mockStreamingAnalytics) startFromPosition:20];
            
            [mockStreamingAnalytics setMetadata:contentMetaData];
            [verifyCount(mockStreamingAnalytics, times(2)) setMetadata:captor];
            id argumentId = captor.value;
            assertThat(argumentId, notNilValue());
            assertThat(argumentId, is(contentMetaData));
        });
    
        it(@"videoPlaybackSeekStarted fallsback to method without seek_position", ^{

            SEGTrackPayload *payload = [[SEGTrackPayload alloc] initWithEvent:@"Video Playback Seek Started" properties:@{
                @"content_asset_id" : @"6352",
                @"ad_type" : @"pre-roll",
                @"video_player" : @"vimeo",
                @"sound" : @100,
                @"full_screen" : @YES,
                @"bitrate" : @50

            } context:@{}
                integrations:@{}];
            
            HCArgumentCaptor *captor = [[HCArgumentCaptor alloc] init];
            SCORStreamingContentMetadata *contentMetaData = [SCORStreamingContentMetadata contentMetadataWithBuilderBlock:^(SCORStreamingContentMetadataBuilder *builder) {
               [builder setCustomLabels:@{ @"ns_st_ci": @"6352",
                                           @"ns_st_mp" : @"vimeo",
                                           @"ns_st_vo" : @"100",
                                           @"c3" : @"*null",
                                           @"c4" : @"*null",
                                           @"c6" : @"*null",
                                           @"ns_st_ws" : @"full",
                                           @"ns_st_br" : @"50000" }];
           }];

            [integration track:payload];
            [verify(mockStreamingAnalytics) notifySeekStart];
            
            [mockStreamingAnalytics setMetadata:contentMetaData];
            [verifyCount(mockStreamingAnalytics, times(2)) setMetadata:captor];
            id argumentId = captor.value;
            assertThat(argumentId, notNilValue());
            assertThat(argumentId, is(contentMetaData));
        });


        it(@"videoPlaybackSeekCompleted with seekPosition", ^{

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
            
            HCArgumentCaptor *captor = [[HCArgumentCaptor alloc] init];
            SCORStreamingContentMetadata *contentMetaData = [SCORStreamingContentMetadata contentMetadataWithBuilderBlock:^(SCORStreamingContentMetadataBuilder *builder) {
                [builder setCustomLabels:@{ @"ns_st_ci": @"6352",
                                            @"ns_st_mp" : @"vimeo",
                                            @"ns_st_vo" : @"100",
                                            @"c3" : @"*null",
                                            @"c4" : @"*null",
                                            @"c6" : @"*null",
                                            @"ns_st_ws" : @"full",
                                            @"ns_st_br" : @"50000"}];
            }];

            [integration track:payload];
            [verify(mockStreamingAnalytics) notifyPlay];
            [verify(mockStreamingAnalytics) startFromPosition:20];
            
            [mockStreamingAnalytics setMetadata:contentMetaData];
            [verifyCount(mockStreamingAnalytics, times(2)) setMetadata:captor];
            id argumentId = captor.value;
            assertThat(argumentId, notNilValue());
            assertThat(argumentId, is(contentMetaData));
        });
    
        it(@"videoPlaybackSeekCompleted fallsback to method without seek_position", ^{

            SEGTrackPayload *payload = [[SEGTrackPayload alloc] initWithEvent:@"Video Playback Seek Completed" properties:@{
                @"content_asset_id" : @"6352",
                @"ad_type" : @"pre-roll",
                @"video_player" : @"vimeo",
                @"sound" : @100,
                @"full_screen" : @YES,
                @"bitrate" : @50

            } context:@{}
                integrations:@{}];
            
            HCArgumentCaptor *captor = [[HCArgumentCaptor alloc] init];
            SCORStreamingContentMetadata *contentMetaData = [SCORStreamingContentMetadata contentMetadataWithBuilderBlock:^(SCORStreamingContentMetadataBuilder *builder) {
                [builder setCustomLabels:@{ @"ns_st_ci": @"6352",
                                            @"ns_st_mp" : @"vimeo",
                                            @"ns_st_vo" : @"100",
                                            @"c3" : @"*null",
                                            @"c4" : @"*null",
                                            @"c6" : @"*null",
                                            @"ns_st_ws" : @"full",
                                            @"ns_st_br" : @"50000"}];
            }];

            [integration track:payload];
            [verify(mockStreamingAnalytics) notifyPlay];
            
            [mockStreamingAnalytics setMetadata:contentMetaData];
            [verifyCount(mockStreamingAnalytics, times(2)) setMetadata:captor];
            id argumentId = captor.value;
            assertThat(argumentId, notNilValue());
            assertThat(argumentId, is(contentMetaData));
        });

        it(@"videoPlaybackResumed with playPosition", ^{

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
            
            
            HCArgumentCaptor *captor = [[HCArgumentCaptor alloc] init];
            SCORStreamingContentMetadata *contentMetaData = [SCORStreamingContentMetadata contentMetadataWithBuilderBlock:^(SCORStreamingContentMetadataBuilder *builder) {
                [builder setCustomLabels:@{ @"ns_st_ci": @"2141",
                                            @"ns_st_mp" : @"vimeo",
                                            @"ns_st_vo" : @"100",
                                            @"c3" : @"*null",
                                            @"c4" : @"*null",
                                            @"c6" : @"*null",
                                            @"ns_st_ws" : @"full",
                                            @"ns_st_br" : @"50000"}];
            }];

            [integration track:payload];
            [verify(mockStreamingAnalytics) startFromPosition:34];
            [verify(mockStreamingAnalytics) notifyPlay];
            
            [mockStreamingAnalytics setMetadata:contentMetaData];
            [verifyCount(mockStreamingAnalytics, times(2)) setMetadata:captor];
            id argumentId = captor.value;
            assertThat(argumentId, notNilValue());
            assertThat(argumentId, is(contentMetaData));
        });

        it(@"videoPlaybackResumed fallsback to method without position", ^{

            SEGTrackPayload *payload = [[SEGTrackPayload alloc] initWithEvent:@"Video Playback Resumed" properties:@{
                @"content_asset_id" : @"2141",
                @"ad_type" : @"mid-roll",
                @"video_player" : @"youtube",
                @"sound" : @100,
                @"full_screen" : @YES,
                @"bitrate" : @50

            } context:@{}
                                                                 integrations:@{}];
            
            HCArgumentCaptor *captor = [[HCArgumentCaptor alloc] init];
            SCORStreamingContentMetadata *contentMetaData = [SCORStreamingContentMetadata contentMetadataWithBuilderBlock:^(SCORStreamingContentMetadataBuilder *builder) {
                [builder setCustomLabels:@{ @"ns_st_ci": @"2141",
                                            @"ns_st_mp" : @"vimeo",
                                            @"ns_st_vo" : @"100",
                                            @"c3" : @"*null",
                                            @"c4" : @"*null",
                                            @"c6" : @"*null",
                                            @"ns_st_ws" : @"full",
                                            @"ns_st_br" : @"50000"}];
            }];

            [integration track:payload];
            [verify(mockStreamingAnalytics) notifyPlay];
            
            [mockStreamingAnalytics setMetadata:contentMetaData];
            [verifyCount(mockStreamingAnalytics, times(2)) setMetadata:captor];
            id argumentId = captor.value;
            assertThat(argumentId, notNilValue());
            assertThat(argumentId, is(contentMetaData));
        });

        //#pragma Content Events

        it(@"videoContentStarted with playPosition", ^{

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
                                                                     @"com-score" : @{
                                                                         @"tvAirdate" : @"2017-05-22"
                                                                     }
                                                                 }];
            
            
            
            HCArgumentCaptor *captor = [[HCArgumentCaptor alloc] init];
            SCORStreamingContentMetadata *contentMetaData = [SCORStreamingContentMetadata contentMetadataWithBuilderBlock:^(SCORStreamingContentMetadataBuilder *builder) {
                [builder setCustomLabels:@{ @"ns_st_ci" : @"3543",
                                            @"ns_st_ep" : @"Big Trouble in Little Sanchez",
                                            @"ns_st_sn" : @"2",
                                            @"ns_st_en" : @"7",
                                            @"ns_st_ge" : @"cartoon",
                                            @"ns_st_pr" : @"Rick and Morty",
                                            @"ns_st_cl" : @"400000",
                                            @"ns_st_ce" : @"true",
                                            @"ns_st_pu" : @"Turner Broadcasting Network",
                                            @"ns_st_st" : @"Cartoon Network",
                                            @"c3" : @"*null",
                                            @"c4" : @"*null",
                                            @"c6" : @"*null",
                                            @"ns_st_tdt" : @"2017-05-22",
                                            @"ns_st_ddt" : @"*null",
                                            @"ns_st_ct" : @"vc00",
                                            @"ns_st_pn" : @"65462"}];
            }];

            [integration track:payload];
            [verify(mockStreamingAnalytics) startFromPosition:22];
            [verify(mockStreamingAnalytics) notifyPlay];
            
            [mockStreamingAnalytics setMetadata:contentMetaData];
            [verifyCount(mockStreamingAnalytics, times(2)) setMetadata:captor];
            id argumentId = captor.value;
            assertThat(argumentId, notNilValue());
            assertThat(argumentId, is(contentMetaData));

        });

        it(@"videoContentStarted with default values", ^{


            SEGTrackPayload *payload = [[SEGTrackPayload alloc] initWithEvent:@"Video Content Started" properties:@{} context:@{} integrations:@{}];
            NSDictionary *customLabels = @{  @"ns_st_ci" : @"0",
                                             @"ns_st_ep" : @"*null",
                                             @"ns_st_sn" : @"*null",
                                             @"ns_st_en" : @"*null",
                                             @"ns_st_ge" : @"*null",
                                             @"ns_st_pr" : @"*null",
                                             @"ns_st_cl" : @"*0",
                                             @"ns_st_ce" : @"*null",
                                             @"ns_st_pu" : @"*null",
                                             @"ns_st_st" : @"*null",
                                             @"ns_st_pn" : @"*null",
                                             @"c3" : @"*null",
                                             @"c4" : @"*null",
                                             @"c6" : @"*null",
                                             @"ns_st_tdt" : @"*null",
                                             @"ns_st_ddt" : @"*null",
                                             @"ns_st_ct" : @"vc00" };

            HCArgumentCaptor *captor = [[HCArgumentCaptor alloc] init];
                       SCORStreamingContentMetadata *contentMetaData = [SCORStreamingContentMetadata contentMetadataWithBuilderBlock:^(SCORStreamingContentMetadataBuilder *builder) {
                           [builder setCustomLabels:customLabels];
                       }];
            
            [integration track:payload];
            [verify(mockStreamingAnalytics) notifyPlay];
            
            [mockStreamingAnalytics setMetadata:contentMetaData];
            [verifyCount(mockStreamingAnalytics, times(2)) setMetadata:captor];
            id argumentId = captor.value;
            assertThat(argumentId, notNilValue());
            assertThat(argumentId, is(contentMetaData));
            // TODO: Implement test to compare `integration.configurationLabels` and `customLabels`
            // Confirmed manaully that the two dictionaries contain the same k:v pairs

        });

        it(@"videoContentStarted fallsback to method without position", ^{


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
                @"channel" : @"Cartoon Network"
            } context:@{}
                                                                 integrations:@{
                                                                     @"com-score" : @{
                                                                         @"tvAirdate" : @"2017-05-22"
                                                                     }
                                                                 }];
            
            HCArgumentCaptor *captor = [[HCArgumentCaptor alloc] init];
            SCORStreamingContentMetadata *contentMetaData = [SCORStreamingContentMetadata contentMetadataWithBuilderBlock:^(SCORStreamingContentMetadataBuilder *builder) {
                [builder setCustomLabels:@{ @"ns_st_ci" : @"3543",
                                            @"ns_st_ep" : @"Big Trouble in Little Sanchez",
                                            @"ns_st_sn" : @"2",
                                            @"ns_st_en" : @"7",
                                            @"ns_st_ge" : @"cartoon",
                                            @"ns_st_pr" : @"Rick and Morty",
                                            @"ns_st_cl" : @"400000",
                                            @"ns_st_ce" : @"true",
                                            @"ns_st_pu" : @"Turner Broadcasting Network",
                                            @"ns_st_pn" : @"65462",
                                            @"ns_st_st" : @"Cartoon Network",
                                            @"c3" : @"*null",
                                            @"c4" : @"*null",
                                            @"c6" : @"*null",
                                            @"ns_st_tdt" : @"2017-05-22",
                                            @"ns_st_ddt" : @"*null",
                                            @"ns_st_ct" : @"vc00"}];
            }];

            [integration track:payload];
            [verify(mockStreamingAnalytics) notifyPlay];
            
            [mockStreamingAnalytics setMetadata:contentMetaData];
            [verifyCount(mockStreamingAnalytics, times(2)) setMetadata:captor];
            id argumentId = captor.value;
            assertThat(argumentId, notNilValue());
            assertThat(argumentId, is(contentMetaData));

        });
    
        it(@"videoContentPlaying with adType", ^{


               SEGTrackPayload *payload = [[SEGTrackPayload alloc] initWithEvent:@"Video Content Playing" properties:@{
                   @"asset_id" : @"3543",
                   @"pod_id" : @"65462",
                   @"title" : @"Big Trouble in Little Sanchez",
                   @"season" : @"2",
                   @"episode" : @"7",
                   @"type": @"pre-roll",
                   @"genre" : @"cartoon",
                   @"program" : @"Rick and Morty",
                   @"total_length" : @400,
                   @"full_episode" : @"true",
                   @"publisher" : @"Turner Broadcasting Network",
                   @"channel" : @"Cartoon Network"
               } context:@{}
                                                                    integrations:@{
                                                                        @"com-score" : @{
                                                                            @"tvAirdate" : @"2017-05-22"
                                                                        }
                                                                    }];
            HCArgumentCaptor *captor = [[HCArgumentCaptor alloc] init];
            SCORStreamingContentMetadata *contentMetaData = [SCORStreamingContentMetadata contentMetadataWithBuilderBlock:^(SCORStreamingContentMetadataBuilder *builder) {
                [builder setCustomLabels:@{ @"ns_st_ci" : @"3543",
                                            @"ns_st_ep" : @"Big Trouble in Little Sanchez",
                                            @"ns_st_sn" : @"2",
                                            @"ns_st_en" : @"7",
                                            @"ns_st_ge" : @"cartoon",
                                            @"ns_st_pr" : @"Rick and Morty",
                                            @"ns_st_cl" : @"400000",
                                            @"ns_st_ce" : @"true",
                                            @"ns_st_pu" : @"Turner Broadcasting Network",
                                            @"ns_st_pn" : @"65462",
                                            @"ns_st_st" : @"Cartoon Network",
                                            @"c3" : @"*null",
                                            @"c4" : @"*null",
                                            @"c6" : @"*null",
                                            @"ns_st_tdt" : @"2017-05-22",
                                            @"ns_st_ddt" : @"*null",
                                            @"ns_st_ct" : @"vc00"}];
            }];

            SCORStreamingAdvertisementMetadata * advertisingMetaData = [SCORStreamingAdvertisementMetadata advertisementMetadataWithBuilderBlock:^(SCORStreamingAdvertisementMetadataBuilder *builder) {
                [builder setMediaType: SCORStreamingAdvertisementTypeOnDemandPreRoll];
                [builder setRelatedContentMetadata: contentMetaData];
            }];

            [integration track:payload];
            [verify(mockStreamingAnalytics) notifyPlay];
            
            [mockStreamingAnalytics setMetadata:advertisingMetaData];
            [verifyCount(mockStreamingAnalytics, times(1)) setMetadata:captor];
            id argumentId = captor.value;
            assertThat(argumentId, notNilValue());
            assertThat(argumentId, is(advertisingMetaData));

           });

        it(@"videoContentPlaying with playPosition and without Ad Type", ^{


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
            
            HCArgumentCaptor *captor = [[HCArgumentCaptor alloc] init];
            SCORStreamingContentMetadata *contentMetaData = [SCORStreamingContentMetadata contentMetadataWithBuilderBlock:^(SCORStreamingContentMetadataBuilder *builder) {
                [builder setCustomLabels:@{ @"ns_st_ci" : @"3543",
                                            @"ns_st_ep" : @"Big Trouble in Little Sanchez",
                                            @"ns_st_sn" : @"2",
                                            @"ns_st_en" : @"7",
                                            @"ns_st_ge" : @"cartoon",
                                            @"ns_st_pr" : @"Rick and Morty",
                                            @"ns_st_cl" : @"400000",
                                            @"ns_st_ce" : @"true",
                                            @"ns_st_pu" : @"Turner Broadcasting Network",
                                            @"ns_st_pn" : @"65462",
                                            @"ns_st_st" : @"Cartoon Network",
                                            @"c3" : @"*null",
                                            @"c4" : @"*null",
                                            @"c6" : @"*null",
                                            @"ns_st_tdt" : @"2017-05-22",
                                            @"ns_st_ddt" : @"*null",
                                            @"ns_st_ct" : @"vc00"}];
            }];

            [integration track:payload];
            [verify(mockStreamingAnalytics) notifyPlay];
            
            [mockStreamingAnalytics setMetadata:contentMetaData];
            [verifyCount(mockStreamingAnalytics, times(1)) setMetadata:captor];
            id argumentId = captor.value;
            assertThat(argumentId, notNilValue());
            assertThat(argumentId, is(contentMetaData));

        });

        it(@"videoContentPlaying fallsback to method without position and without Ad Type", ^{

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
            
            HCArgumentCaptor *captor = [[HCArgumentCaptor alloc] init];
            SCORStreamingContentMetadata *contentMetaData = [SCORStreamingContentMetadata contentMetadataWithBuilderBlock:^(SCORStreamingContentMetadataBuilder *builder) {
                [builder setCustomLabels:@{ @"ns_st_ci" : @"3543",
                                            @"ns_st_ep" : @"Big Trouble in Little Sanchez",
                                            @"ns_st_sn" : @"2",
                                            @"ns_st_en" : @"7",
                                            @"ns_st_ge" : @"cartoon",
                                            @"ns_st_pr" : @"Rick and Morty",
                                            @"ns_st_cl" : @"400000",
                                            @"ns_st_ce" : @"true",
                                            @"ns_st_pu" : @"Turner Broadcasting Network",
                                            @"ns_st_pn" : @"65462",
                                            @"ns_st_st" : @"Cartoon Network",
                                            @"c3" : @"*null",
                                            @"c4" : @"*null",
                                            @"c6" : @"*null",
                                            @"ns_st_tdt" : @"2017-05-22",
                                            @"ns_st_ddt" : @"*null",
                                            @"ns_st_ct" : @"vc00"}];
            }];

            [integration track:payload];
            [verify(mockStreamingAnalytics) notifyPlay];
            
            [mockStreamingAnalytics setMetadata:contentMetaData];
            [verifyCount(mockStreamingAnalytics, times(1)) setMetadata:captor];
            id argumentId = captor.value;
            assertThat(argumentId, notNilValue());
            assertThat(argumentId, is(contentMetaData));
        });
    
        it(@"videoContentStarted with missing total length", ^{

            SEGTrackPayload *payload = [[SEGTrackPayload alloc] initWithEvent:@"Video Content Started" properties:@{
                @"asset_id" : @"3543",
                @"pod_id" : @"65462",
                @"title" : @"Big Trouble in Little Sanchez",
                @"season" : @"2",
                @"episode" : @"7",
                @"genre" : @"cartoon",
                @"program" : @"Rick and Morty",
                @"full_episode" : @"true",
                @"publisher" : @"Turner Broadcasting Network",
                @"position" : @22,
                @"channel" : @"Cartoon Network"
            } context:@{}
                                                                 integrations:@{
                                                                     @"com-score" : @{
                                                                         @"tvAirdate" : @"2017-05-22"
                                                                     }
                                                                 }];
            
            
            
            HCArgumentCaptor *captor = [[HCArgumentCaptor alloc] init];
            SCORStreamingContentMetadata *contentMetaData = [SCORStreamingContentMetadata contentMetadataWithBuilderBlock:^(SCORStreamingContentMetadataBuilder *builder) {
                [builder setCustomLabels:@{ @"ns_st_ci" : @"3543",
                                            @"ns_st_ep" : @"Big Trouble in Little Sanchez",
                                            @"ns_st_sn" : @"2",
                                            @"ns_st_en" : @"7",
                                            @"ns_st_ge" : @"cartoon",
                                            @"ns_st_pr" : @"Rick and Morty",
                                            @"ns_st_cl" : @"0",
                                            @"ns_st_ce" : @"true",
                                            @"ns_st_pu" : @"Turner Broadcasting Network",
                                            @"ns_st_st" : @"Cartoon Network",
                                            @"c3" : @"*null",
                                            @"c4" : @"*null",
                                            @"c6" : @"*null",
                                            @"ns_st_tdt" : @"2017-05-22",
                                            @"ns_st_ddt" : @"*null",
                                            @"ns_st_ct" : @"vc00",
                                            @"ns_st_pn" : @"65462"}];
            }];

            [integration track:payload];
            [verify(mockStreamingAnalytics) startFromPosition:22];
            [verify(mockStreamingAnalytics) notifyPlay];
            
            [mockStreamingAnalytics setMetadata:contentMetaData];
            [verifyCount(mockStreamingAnalytics, times(2)) setMetadata:captor];
            id argumentId = captor.value;
            assertThat(argumentId, notNilValue());
            assertThat(argumentId, is(contentMetaData));

        });

        it(@"videoContentCompleted", ^{

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
            [verify(mockStreamingAnalytics) notifyEnd];
            expect(integration.configurationLabels).to.equal(@{});
        });

        //#pragma Ad Events

        it(@"videoAdStarted with playPosition and ns_st_ci value", ^{

            SEGTrackPayload *payload = [[SEGTrackPayload alloc] initWithEvent:@"Video Ad Started" properties:@{
                @"content_asset_id": @"3543",
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
            
            HCArgumentCaptor *captor = [[HCArgumentCaptor alloc] init];
            SCORStreamingContentMetadata *contentMetaData = [SCORStreamingContentMetadata contentMetadataWithBuilderBlock:^(SCORStreamingContentMetadataBuilder *builder) {
                         [builder setCustomLabels:@{ @"ns_st_ci" : @"3543",
                                                     @"ns_st_cl" : @"110000",
                                                     @"ns_st_pu" : @"Adult Swim",
                                                     @"c3" : @"*null",
                                                     @"c4" : @"*null",
                                                     @"c6" : @"*null",
                                                     @"ns_st_ddt" : @"*null",
                                                     @"ns_st_ct" : @"vc00"}];
                     }];
            
            SCORStreamingAdvertisementMetadata * advertisingMetaData = [SCORStreamingAdvertisementMetadata advertisementMetadataWithBuilderBlock:^(SCORStreamingAdvertisementMetadataBuilder *builder) {
                [builder setMediaType: SCORStreamingAdvertisementTypeBrandedOnDemandMidRoll];
                [builder setCustomLabels: @{
                    @"ns_st_ci": @"3543",
                    @"ns_st_ami": @"1231312",
                    @"ns_st_ad": @"0",
                    @"ns_st_cl": @"110000",
                    @"ns_st_amt": @"Rick and Morty Ad",
                    @"ns_st_pu": @"Adult Swim",
                    @"ns_st_ct": @"va00"
                }];
                [builder setRelatedContentMetadata: contentMetaData];
            }];

            [verify(mockStreamingAnalytics) startFromPosition:43];
            [verify(mockStreamingAnalytics) notifyPlay];
            
            [mockStreamingAnalytics setMetadata:advertisingMetaData];
            [verifyCount(mockStreamingAnalytics, times(2)) setMetadata:captor];
            id argumentId = captor.value;
            assertThat(argumentId, notNilValue());
            assertThat(argumentId, is(advertisingMetaData));

        });
    
        it(@"videoAdStarted fallsback to @'1' without correct type value", ^{
            SEGTrackPayload *payload = [[SEGTrackPayload alloc] initWithEvent:@"Video Ad Started" properties:@{
                @"asset_id" : @"1231312",
                @"pod_id" : @"43434234534",
                @"type" : @"not an ad type",
                @"total_length" : @110,
                @"title" : @"Rick and Morty Ad"
            } context:@{}
                integrations:@{}];

            [integration track:payload];
            
            HCArgumentCaptor *captor = [[HCArgumentCaptor alloc] init];
            SCORStreamingContentMetadata *contentMetaData = [SCORStreamingContentMetadata contentMetadataWithBuilderBlock:^(SCORStreamingContentMetadataBuilder *builder) {
                         [builder setCustomLabels:@{ @"ns_st_ci" : @"0",
                                                     @"ns_st_cl" : @"110000",
                                                     @"ns_st_pu" : @"*null",
                                                     @"c3" : @"*null",
                                                     @"c4" : @"*null",
                                                     @"c6" : @"*null",
                                                     @"ns_st_ct" : @"va00"}];
                     }];
            
            SCORStreamingAdvertisementMetadata * advertisingMetaData = [SCORStreamingAdvertisementMetadata advertisementMetadataWithBuilderBlock:^(SCORStreamingAdvertisementMetadataBuilder *builder) {
                [builder setMediaType: SCORStreamingAdvertisementTypeBrandedOnDemandMidRoll];
                [builder setCustomLabels: @{
                    @"ns_st_ci": @"3543",
                    @"ns_st_ami": @"1231312",
                    @"ns_st_ad": @"1",
                    @"ns_st_cl": @"110000",
                    @"ns_st_amt": @"Rick and Morty Ad",
                    @"ns_st_pu": @"*null",
                    @"ns_st_ct": @"va00"
                }];
                [builder setRelatedContentMetadata: contentMetaData];
            }];

            [verify(mockStreamingAnalytics) notifyPlay];
            
            [mockStreamingAnalytics setMetadata:advertisingMetaData];
            [verifyCount(mockStreamingAnalytics, times(2)) setMetadata:captor];
            id argumentId = captor.value;
            assertThat(argumentId, notNilValue());
            assertThat(argumentId, is(advertisingMetaData));
        });

        it(@"videoAdStarted maps adClassificationType value passed in integrations object", ^{


            SEGTrackPayload *payload = [[SEGTrackPayload alloc] initWithEvent:@"Video Ad Started" properties:@{
                @"asset_id" : @"1231312",
                @"pod_id" : @"43434234534",
                @"type" : @"mid-roll",
                @"total_length" : @110,
                @"position" : @110,
                @"title" : @"Rick and Morty Ad"

            } context:@{}
                                                                 integrations:@{ @"com-score" : @{
                                                                     @"adClassificationType" : @"va12"
                                                                 } }];

            [integration track:payload];
            
            
            HCArgumentCaptor *captor = [[HCArgumentCaptor alloc] init];
            SCORStreamingContentMetadata *contentMetaData = [SCORStreamingContentMetadata contentMetadataWithBuilderBlock:^(SCORStreamingContentMetadataBuilder *builder) {
                         [builder setCustomLabels:@{ @"ns_st_ci" : @"0",
                                                     @"ns_st_cl" : @"110000",
                                                     @"ns_st_pu" : @"*null",
                                                     @"c3" : @"*null",
                                                     @"c4" : @"*null",
                                                     @"c6" : @"*null",
                                                    }];
                     }];
            
            SCORStreamingAdvertisementMetadata * advertisingMetaData = [SCORStreamingAdvertisementMetadata advertisementMetadataWithBuilderBlock:^(SCORStreamingAdvertisementMetadataBuilder *builder) {
                [builder setMediaType: SCORStreamingAdvertisementTypeBrandedOnDemandMidRoll];
                [builder setCustomLabels: @{
                    @"ns_st_ci": @"3543",
                    @"ns_st_ami": @"1231312",
                    @"ns_st_ad": @"1",
                    @"ns_st_cl": @"110000",
                    @"ns_st_amt": @"Rick and Morty Ad",
                    @"ns_st_pu": @"*null",
                    @"ns_st_ct": @"va12"
                }];
                [builder setRelatedContentMetadata: contentMetaData];
            }];

            [verify(mockStreamingAnalytics) notifyPlay];
            [verify(mockStreamingAnalytics) startFromPosition:110];
            
            
            [mockStreamingAnalytics setMetadata:advertisingMetaData];
            [verifyCount(mockStreamingAnalytics, times(2)) setMetadata:captor];
            id argumentId = captor.value;
            assertThat(argumentId, notNilValue());
            assertThat(argumentId, is(advertisingMetaData));
        });
    
        it(@"videoAdStarted with missing total length", ^{

            SEGTrackPayload *payload = [[SEGTrackPayload alloc] initWithEvent:@"Video Ad Started" properties:@{
                @"content_asset_id": @"3543",
                @"asset_id" : @"1231312",
                @"pod_id" : @"43434234534",
                @"type" : @"mid-roll",
                @"position" : @43,
                @"publisher" : @"Adult Swim",
                @"title" : @"Rick and Morty Ad"
            } context:@{}
                integrations:@{}];

            [integration track:payload];
            
            HCArgumentCaptor *captor = [[HCArgumentCaptor alloc] init];
            SCORStreamingContentMetadata *contentMetaData = [SCORStreamingContentMetadata contentMetadataWithBuilderBlock:^(SCORStreamingContentMetadataBuilder *builder) {
                         [builder setCustomLabels:@{ @"ns_st_ci" : @"3543",
                                                     @"ns_st_cl" : @"0",
                                                     @"ns_st_pu" : @"Adult Swim",
                                                     @"c3" : @"*null",
                                                     @"c4" : @"*null",
                                                     @"c6" : @"*null",
                                                     @"ns_st_ddt" : @"*null",
                                                     @"ns_st_ct" : @"vc00"}];
                     }];
            
            SCORStreamingAdvertisementMetadata * advertisingMetaData = [SCORStreamingAdvertisementMetadata advertisementMetadataWithBuilderBlock:^(SCORStreamingAdvertisementMetadataBuilder *builder) {
                [builder setMediaType: SCORStreamingAdvertisementTypeBrandedOnDemandMidRoll];
                [builder setCustomLabels: @{
                    @"ns_st_ci": @"3543",
                    @"ns_st_ami": @"1231312",
                    @"ns_st_ad": @"0",
                    @"ns_st_cl": @"0",
                    @"ns_st_amt": @"Rick and Morty Ad",
                    @"ns_st_pu": @"Adult Swim",
                    @"ns_st_ct": @"va00"
                }];
                [builder setRelatedContentMetadata: contentMetaData];
            }];

            [verify(mockStreamingAnalytics) startFromPosition:43];
            [verify(mockStreamingAnalytics) notifyPlay];
            
            [mockStreamingAnalytics setMetadata:advertisingMetaData];
            [verifyCount(mockStreamingAnalytics, times(2)) setMetadata:captor];
            id argumentId = captor.value;
            assertThat(argumentId, notNilValue());
            assertThat(argumentId, is(advertisingMetaData));

        });
    

        it(@"videoAdPlaying with playPosition", ^{

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

            [verify(mockStreamingAnalytics) startFromPosition:50];
            [verify(mockStreamingAnalytics) notifyPlay];

        });

        it(@"videoAdPlaying fallsback to method without position", ^{

            SEGTrackPayload *payload = [[SEGTrackPayload alloc] initWithEvent:@"Video Ad Playing" properties:@{
                @"asset_id" : @"1231312",
                @"pod_id" : @"43434234534",
                @"type" : @"mid-roll",
                @"total_length" : @110,
                @"title" : @"Rick and Morty Ad"
            } context:@{}
                integrations:@{}];

            [integration track:payload];
            [verify(mockStreamingAnalytics) notifyPlay];
        });

        it(@"videoAdCompleted", ^{

            SEGTrackPayload *payload = [[SEGTrackPayload alloc] initWithEvent:@"Video Ad Completed" properties:@{
                @"asset_id" : @"1231312",
                @"pod_id" : @"43434234534",
                @"type" : @"mid-roll",
                @"total_length" : @110,
                @"title" : @"Rick and Morty Ad"

            } context:@{}
                integrations:@{}];

            [integration track:payload];
            [verify(mockStreamingAnalytics) notifyEnd];
        });
    });
});

SpecEnd
         

