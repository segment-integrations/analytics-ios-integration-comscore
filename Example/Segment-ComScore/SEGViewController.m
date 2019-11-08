//
//  SEGViewController.m
//  Segment-ComScore
//
//  Created by wcjohnson11 on 05/16/2016.
//  Copyright (c) 2016 wcjohnson11. All rights reserved.
//

#import "SEGViewController.h"
#import <Analytics/SEGAnalytics.h>


@interface SEGViewController ()

@end


@implementation SEGViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    [[SEGAnalytics sharedAnalytics] identify:@"234"];
    [[SEGAnalytics sharedAnalytics] track:@"comScore Example Launched v2019"];

    [[SEGAnalytics sharedAnalytics] track:@"Video Playback Started"
                               properties:nil
                                  options:@{
                                            @"integrations": @{
                                                    @"com-score": @{
                                                            @"c4":@"testing-v2019"
                                                            }
                                                    }
                                            }];

    [[SEGAnalytics sharedAnalytics] track:@"Video Content Started"
                               properties:nil
                                  options:@{
                                            @"integrations": @{
                                                    @"com-score": @{
                                                            @"c4":@"testing-v2019"
                                                            }
                                                    }
                                            }];
    
    [[SEGAnalytics sharedAnalytics] flush];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
