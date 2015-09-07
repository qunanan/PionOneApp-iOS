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

#define IN_STEP_1   self.step1Label.hidden == NO && self.step2Label.hidden == YES
#define IN_STEP_2   self.step2Label.hidden == NO && self.step3Label.hidden == YES
#define IN_STEP_3   self.step3Label.hidden == NO && self.step4Label.hidden == YES
#define IN_STEP_4   self.step4Label.hidden == NO


@interface APConfigGuideVC ()
@property (weak, nonatomic) IBOutlet UILabel *step1Label;
@property (weak, nonatomic) IBOutlet UILabel *step2Label;
@property (weak, nonatomic) IBOutlet UILabel *step3Label;
@property (weak, nonatomic) IBOutlet UILabel *step4Label;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *indicator;
@property (weak, nonatomic) IBOutlet KHFlatButton *button;

@end

@implementation APConfigGuideVC
- (void)viewDidLoad {
    [super viewDidLoad];
    self.step1Label.hidden = YES;
    self.step2Label.hidden = YES;
    self.step3Label.hidden = YES;
    self.step4Label.hidden = YES;
    
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self startConfiguration];
}

- (IBAction)buttonPushed:(KHFlatButton *)button {
    if ([button.titleLabel.text isEqualToString:@"Cancel"]) {
        [button setTitle:@"Start" forState:UIControlStateNormal];
        [self cancelConfiguration];
    } else if ([button.titleLabel.text isEqualToString:@"Start"]) {
        [button setTitle:@"Cancel" forState:UIControlStateNormal];
        [self startConfiguration];
    } else {
        [self.navigationController popToRootViewControllerAnimated:YES];
    }
}

- (void)cancelConfiguration {
    PionOneManager *manager = [PionOneManager sharedInstance];
    manager.APConfigurationDone = NO;
    manager.cachedPassword = nil;
    [manager cancel];
    self.step1Label.hidden = YES;
    self.step2Label.hidden = YES;
    self.step3Label.hidden = YES;
    self.step4Label.hidden = YES;
    [self.indicator stopAnimating];
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)startConfiguration {
    [self.indicator startAnimating];
    PionOneManager *manager = [PionOneManager sharedInstance];
    if (manager.cachedPassword == nil) {
        [self performSegueWithIdentifier:@"ShowEnterPassowrdVC" sender:nil];
        return;
    } else {
        self.step1Label.hidden = NO;
    }
    
    if (manager.APConfigurationDone) {
        self.step4Label.hidden = NO;
        [self configurationgDone];
    }
    
    if (IN_STEP_1) {
        [[PionOneManager sharedInstance] setupNodeNodeWithCompletionHandler:^(BOOL succes, NSString *msg) {
            if (succes) {
                self.step2Label.hidden = NO;
                [manager findTheConfiguringNodeFromSeverWithCompletionHandler:^(BOOL succes, NSString *msg) {
                    if (succes) {
                        self.step3Label.hidden = NO;
                        [self performSegueWithIdentifier:@"ShowEnterNameVC" sender:nil];
                    } else {
                        [self showAlertMsg:msg];
                        [self cancelConfiguration];
                    }
                }];
            } else {
                [self showAlertMsg:msg];
                [self cancelConfiguration];
            }
        }];
    }
}

- (void)configurationgDone {
    PionOneManager *manager = [PionOneManager sharedInstance];
    manager.APConfigurationDone = NO;
    manager.cachedPassword = nil;
    [self.indicator stopAnimating];
    [self.button setTitle:@"Done" forState:UIControlStateNormal];
}


- (void)showAlertMsg:(NSString *)msg {
    [[[UIAlertView alloc] initWithTitle:@"Failed"
                                message:msg delegate:self
                      cancelButtonTitle:@"OK"
                      otherButtonTitles:nil] show];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
}
@end
