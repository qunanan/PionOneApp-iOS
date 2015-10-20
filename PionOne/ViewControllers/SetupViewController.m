//
//  SetupViewController.m
//  PionOne
//
//  Created by Qxn on 15/10/16.
//  Copyright © 2015年 SeeedStudio. All rights reserved.
//

#import "SetupViewController.h"
#import "TextFieldEffects-Swift.h"
#import "PionOneManager.h"

@interface SetupViewController () <UITextFieldDelegate>
@property (weak, nonatomic) IBOutlet HoshiTextField *otaServerIP;
@property (weak, nonatomic) IBOutlet HoshiTextField *dataServerIP;

@end

@implementation SetupViewController

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    self.otaServerIP.delegate = self;
    self.dataServerIP.delegate = self;
    [self.otaServerIP becomeFirstResponder];
    
    self.otaServerIP.text = [[NSUserDefaults standardUserDefaults] objectForKey:kPionOneOTAServerIPAddress];
    [self.dataServerIP becomeFirstResponder];
    self.dataServerIP.text = [[NSUserDefaults standardUserDefaults] objectForKey:kPionOneDataServerIPAddress];
    [self.otaServerIP becomeFirstResponder];

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/
- (IBAction)done:(UIBarButtonItem *)sender {
    [[PionOneManager sharedInstance] setRegion:PionOneRegionNameCustom
                                   OTAServerIP:self.otaServerIP.text
                                andDataSeverIP:self.dataServerIP.text];
        [self.navigationController popViewControllerAnimated:YES];
}

@end
