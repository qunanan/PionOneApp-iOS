//
//  APConfigGuideVC.m
//  PionOne
//
//  Created by Qxn on 15/9/5.
//  Copyright (c) 2015年 SeeedStudio. All rights reserved.
//

#import "APConfigGuideVC.h"
#import "KHFlatButton.h"
#import "PionOneManager.h"
#import "WiFiPasswordVC.h"
#import "MBProgressHUD.h"


@interface APConfigGuideVC () <UIAlertViewDelegate>
@property (strong, nonatomic) MBProgressHUD *progressHUD;

@property (weak, nonatomic) IBOutlet UILabel *step1Label;
@property (weak, nonatomic) IBOutlet UILabel *step2Label;
@property (weak, nonatomic) IBOutlet UILabel *step3Label;
@property (weak, nonatomic) IBOutlet UILabel *step4Label;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *indicator;
@property (weak, nonatomic) IBOutlet KHFlatButton *button;

@end

@implementation APConfigGuideVC
- (MBProgressHUD *)progressHUD {
    if (_progressHUD == nil) {
        _progressHUD = [[MBProgressHUD alloc] initWithView:self.navigationController.view];
        [self.navigationController.view addSubview:_progressHUD];
        _progressHUD.dimBackground = YES;
    }
    return _progressHUD;
}


- (void)viewDidLoad {
    [super viewDidLoad];
    self.step1Label.hidden = YES;
    self.step2Label.hidden = YES;
    self.step3Label.hidden = YES;
    self.step4Label.hidden = YES;
    [self setDefinesPresentationContext:YES];
    [self performSegueWithIdentifier:@"ShowEnterPassowrdVC" sender:nil];
    [self.indicator startAnimating];
}

- (IBAction)buttonPushed:(KHFlatButton *)button {
    if ([button.titleLabel.text isEqualToString:@"Cancel"]) {
        [self cancelConfiguration];
    } else if ([button.titleLabel.text isEqualToString:@"Done"]) {
        [self.navigationController popToRootViewControllerAnimated:YES];
    }
}

- (void)startConfiguration {
    PionOneManager *manager = [PionOneManager sharedInstance];
    if (manager.cachedNodeName && manager.cachedPassword) {
        [manager startAPConfigWithProgressHandler:^(BOOL success, NSInteger step, NSString *msg) {
            if (success) {
                switch (step) {
                    case 1:
                        //connecting wifi
                        self.step1Label.hidden = NO;
                        self.progressHUD.labelText = @"Connecting WiFi..";
                        [self.progressHUD show:YES];
                        self.progressHUD.animationType = MBProgressHUDModeDeterminate;
                    
                        break;
                    case 2:
                        //connecting server
                        self.progressHUD.labelText = @"Connecting Server..";
                        self.step2Label.hidden = NO;
                        break;
                    case 3:
                        //rename device
                        self.progressHUD.labelText = @"Rename Device..";
                        self.step3Label.hidden = NO;
                        break;
                    case 4:
                        //done
                        self.progressHUD.labelText = @"Done";
                        self.step4Label.hidden = NO;
                        [self configurationgDone];
                        break;
                    default:
                        break;
                }
            } else {
                [self showAlertMsg:msg];
                [self cancelConfiguration];
            }
        }];
    }
}

- (void)cancelConfiguration {
    PionOneManager *manager = [PionOneManager sharedInstance];
    manager.APConfigurationDone = NO;
    [manager cancel];
    self.step1Label.hidden = YES;
    self.step2Label.hidden = YES;
    self.step3Label.hidden = YES;
    self.step4Label.hidden = YES;
    [self.progressHUD hide:YES];

    [self.indicator stopAnimating];
    [self.navigationController popViewControllerAnimated:YES];
}


- (void)configurationgDone {
    [self.progressHUD hide:YES];
    PionOneManager *manager = [PionOneManager sharedInstance];
    manager.APConfigurationDone = NO;
    manager.cachedPassword = nil;
    [self.indicator stopAnimating];
    [self.button setTitle:@"Done" forState:UIControlStateNormal];
    [[[UIAlertView alloc] initWithTitle:@"Success!" message:nil delegate:self cancelButtonTitle:@"Done" otherButtonTitles: nil] show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 0) {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

- (void)showAlertMsg:(NSString *)msg {
    [[[UIAlertView alloc] initWithTitle:@"Failed"
                                message:msg delegate:self
                      cancelButtonTitle:@"OK"
                      otherButtonTitles:nil] show];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    id dVC = [segue destinationViewController];
    if ([dVC isKindOfClass:[WiFiPasswordVC class]]) {
        [(WiFiPasswordVC *)dVC setPresentingVC:self];
    }
}

@end
