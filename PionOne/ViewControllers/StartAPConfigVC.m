//
//  StartAPConfigVC.m
//  PionOne
//
//  Created by Qxn on 15/9/5.
//  Copyright (c) 2015年 SeeedStudio. All rights reserved.
//

#import "StartAPConfigVC.h"
#import "PionOneManager.h"

@interface StartAPConfigVC ()
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *indicator;

@end

@implementation StartAPConfigVC
- (IBAction)gotReady {
    BOOL isConnected = [[PionOneManager sharedInstance] isConnectedToPionOne];
    if (isConnected) {
        [self performSegueWithIdentifier:@"ShowAPConfigGuideVC" sender:nil];
        [[PionOneManager sharedInstance] setAPConfigurationDone:NO];
    } else {
        [[[UIAlertView alloc] initWithTitle:nil
                                   message:@"Please connect to a PionOne_XXXX access point!"
                                  delegate:self
                         cancelButtonTitle:@"OK"
                          otherButtonTitles:nil] show];
    }
}

@end
