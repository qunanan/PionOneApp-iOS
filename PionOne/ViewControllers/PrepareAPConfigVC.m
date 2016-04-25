//
//  StartAPConfigVC.m
//  PionOne
//
//  Created by Qxn on 15/9/5.
//  Copyright (c) 2015年 SeeedStudio. All rights reserved.
//

#import "PrepareAPConfigVC.h"
#import "PionOneManager.h"
#import "KHFlatButton.h"
#import "MBProgressHUD.h"
#import "TextFieldEffects-Swift.h"
#import "WiFiListTVC.h"

@interface PrepareAPConfigVC () <UITextFieldDelegate, UIAlertViewDelegate>
@property (strong, nonatomic) MBProgressHUD *progressHUD;
@property (strong, nonatomic) UIAlertController *userInputDialog;
@property (assign, nonatomic) BOOL isPreparedPionOne;
@property (weak, nonatomic) IBOutlet UIImageView *guideImage;

//@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *indicator;
@property (weak, nonatomic) IBOutlet KHFlatButton *button;
@end

@implementation PrepareAPConfigVC
- (MBProgressHUD *)progressHUD {
    if (_progressHUD == nil) {
        _progressHUD = [[MBProgressHUD alloc] initWithView:self.navigationController.view];
        [self.navigationController.view addSubview:_progressHUD];
        _progressHUD.dimBackground = YES;
        _progressHUD.minSize = CGSizeMake(150.f, 100.f);
        _progressHUD.animationType = MBProgressHUDAnimationZoom;
    }
    return _progressHUD;
}

- (UIAlertController *)userInputDialog {
    __typeof (&*self) __weak weakSelf = self;
    if (_userInputDialog == nil) {
        NSString *ssid = [[PionOneManager sharedInstance] cachedSSID];
        _userInputDialog = [UIAlertController alertControllerWithTitle:@"Join Network" message:[NSString stringWithFormat:@"SSID:%@",ssid] preferredStyle:UIAlertControllerStyleAlert];
        [_userInputDialog addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleDefault handler:nil]];
        UIAlertAction *joinAction = [UIAlertAction actionWithTitle:@"Join" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [self startConfiguration];
        }];
        joinAction.enabled = NO;
        [_userInputDialog addAction:joinAction];
        [_userInputDialog addTextFieldWithConfigurationHandler:^(UITextField *textField) {
            textField.placeholder = @"Enter SSID Password";
            textField.secureTextEntry = NO;
            [textField addTarget:weakSelf action:@selector(textFieldDidChange) forControlEvents:UIControlEventEditingChanged];
        }];
        [_userInputDialog addTextFieldWithConfigurationHandler:^(UITextField *textField) {
            textField.placeholder = @"Enter A Name For Your Wio Device";
            textField.secureTextEntry = NO;
            [textField setReturnKeyType:UIReturnKeyJoin];
            textField.delegate = weakSelf;
            [textField addTarget:weakSelf action:@selector(textFieldDidChange) forControlEvents:UIControlEventEditingChanged];
        }];
    }
    return _userInputDialog;
}


- (void)viewDidLoad {
    [super viewDidLoad];
    if (self.wioName) {
        if ([self.wioName isEqualToString:kName_WioLink]) {
            self.guideImage.image = [UIImage imageNamed:@"apconfigLink"];
        } else if ([self.wioName isEqualToString:kName_WioNode]) {
            self.guideImage.image = [UIImage imageNamed:@"apconfigNode"];
        }
    }

}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.navigationController.interactivePopGestureRecognizer.enabled = NO;
    
    if (![[PionOneManager sharedInstance] isConnectedToPionOne]) {
        [self.button setTitle:@"Goto wifi list" forState:UIControlStateNormal];
        [self registerAPconfigLocalNotification];
    } else {
        [self.button setTitle:@"Ready" forState:UIControlStateNormal];
    }
    NSArray *viewControllers = self.navigationController.viewControllers;
    if (viewControllers.count > 1 && [viewControllers objectAtIndex:viewControllers.count-2] == self) {
        // View is disappearing because a new view controller was pushed onto the stack
        NSLog(@"New view controller was pushed");
    } else if ([viewControllers indexOfObject:self] == NSNotFound) {
        // View is disappearing because it was popped from the stack
        NSLog(@"View controller was popped");
        [[PionOneManager sharedInstance] deleteZombieNodeWithCompletionHandler:nil];
    }
}


- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[PionOneManager sharedInstance] cancel]; //cancel all processing, include Checking Node AP connection
    self.navigationController.interactivePopGestureRecognizer.enabled = YES;
}

- (IBAction)gotReady {
    BOOL isConnected = [[PionOneManager sharedInstance] isConnectedToPionOne];
    if (isConnected) {
        [[PionOneManager sharedInstance] setAPConfigurationDone:NO];
        [self prepareSetup];
    } else {
        [[[UIAlertView alloc] initWithTitle:@"Connect Wio Device"
                                   message:@"Please go to Settings and connect the Wio_XXXXXX Network."
                                  delegate:self
                         cancelButtonTitle:@"Cancel"
                          otherButtonTitles:@"OK", nil] show];
    }
}

- (void)startCheckingNodeAPConnection {
    [[PionOneManager sharedInstance] checkIfConnectedToPionOneWithCompletionHandler:^(BOOL success, NSString *msg) {
        if (success) {
            UILocalNotification *notification = [[UILocalNotification alloc] init];
            if (notification) {
                notification.soundName = UILocalNotificationDefaultSoundName;
                notification.alertBody = @"Connected a Wio Device!";
                [[UIApplication sharedApplication] presentLocalNotificationNow:notification];
                [NSThread sleepForTimeInterval:1.0];
                [self gotReady];
            }
        }
        else {
            NSLog(@"Stopped checking SSID.");
        }
    }];
}

- (void)showDialog {
    [[_userInputDialog.actions objectAtIndex:1] setEnabled:NO];
    NSString *ssid = [[PionOneManager sharedInstance] cachedSSID];
    self.userInputDialog.message = [NSString stringWithFormat:@"SSID:%@",ssid];
    [self presentViewController:self.userInputDialog animated:YES completion:nil];
}

- (void)prepareSetup {
    [self.progressHUD show:YES];
    [[PionOneManager sharedInstance] getNodeVersionWithCompletionHandler:^(BOOL success, NSString *msg) {
        [self.progressHUD hide:YES];
        if (msg.floatValue > 1.0) {
            NSLog(@"go to select wifi list vc.");
            [self performSegueWithIdentifier:@"showWiFiList" sender:nil];
        } else {
            [self showDialog];
        }
    }];
}

- (void)startConfiguration {

    if (_userInputDialog.textFields.count >= 2) {
        UITextField *passwordTextField = [_userInputDialog.textFields objectAtIndex:0];
        UITextField *nameTextField = [_userInputDialog.textFields objectAtIndex:1];
        [[PionOneManager sharedInstance] setCachedPassword:passwordTextField.text];
        [[PionOneManager sharedInstance] setCachedNodeName:nameTextField.text];
    }

    PionOneManager *manager = [PionOneManager sharedInstance];
    if (manager.cachedNodeName && manager.cachedPassword) {
        [manager startAPConfigWithProgressHandler:^(BOOL success, NSInteger step, NSString *msg) {
            if (success) {
                switch (step) {
                    case 1:
                        //connecting wifi
                        self.progressHUD.detailsLabelText = @"Transmitting the configuration...";
                        [self.progressHUD show:YES];
                        
                        break;
                    case 2:
                        //connecting server
                        self.progressHUD.detailsLabelText = @"The Wio is connecting Server...";
                        self.progressHUD.mode = MBProgressHUDModeDeterminate;
                        [self countDownProgress];
                        break;
                    case 3:
                        //rename device
                        self.progressHUD.mode = MBProgressHUDModeIndeterminate;
                        self.progressHUD.detailsLabelText = @"Setting up the Wio's name...";
                        break;
                    case 4:
                        //done
                        self.progressHUD.detailsLabelText = @"Done";
                        [self configurationgDone];
                        break;
                    default:
                        break;
                }
            } else {
                [self.progressHUD hide:YES];
                self.progressHUD.mode = MBProgressHUDModeIndeterminate;
                [self showErrorHandlingProcess];
//                [self cancelConfiguration];
            }
        }];
    }
}

- (void)showErrorHandlingProcess {
    UIAlertController *errorHandlingAlert = [UIAlertController alertControllerWithTitle:@"Setup failed" message:@"Please check the BLUE LED on the board and select the right status below." preferredStyle:UIAlertControllerStyleActionSheet];
    [errorHandlingAlert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        [self cancelConfiguration];
    }]];
    
    //blink twice quickly then off 1s - requesting IP address from router
    [errorHandlingAlert addAction:[UIAlertAction actionWithTitle:@"blink twice quickly then off 1s" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self showAlertMsg:@"It might be you input a wrong password of your wifi network, please retry the process from the very beginning."];
    }]];
    //blink once quickly then off 1s - connecting to the server
    [errorHandlingAlert addAction:[UIAlertAction actionWithTitle:@"blink once quickly then off 1s" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self showAlertMsg:@"There might be something wrong with the network, the Wio can not connect to the sever. You can reset the Wio by pushing the RESET button and pull to refresh the list."];
        PionOneManager *manager = [PionOneManager sharedInstance];
        self.progressHUD.mode = MBProgressHUDModeIndeterminate;
        [self.progressHUD show:YES];
        [manager setNodeName:manager.cachedNodeName withNodeSN:manager.tmpNodeSN completionHandler:^(BOOL success, NSString *msg) {
            [self.progressHUD hide:YES];
            PionOneManager *manager = [PionOneManager sharedInstance];
            manager.APConfigurationDone = YES;
            manager.cachedPassword = nil;
            [self.navigationController popViewControllerAnimated:YES];
        }];
    }]];

    //on 1s then off 1s - The node is online
    [errorHandlingAlert addAction:[UIAlertAction actionWithTitle:@"on 1s then off 1s" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self showAlertMsg:@"The Wio already connected to the sever. You can pull to refresh the list."];
        PionOneManager *manager = [PionOneManager sharedInstance];
        self.progressHUD.mode = MBProgressHUDModeIndeterminate;
        [self.progressHUD show:YES];
        [manager setNodeName:manager.cachedNodeName withNodeSN:manager.tmpNodeSN completionHandler:^(BOOL success, NSString *msg) {
            [self.progressHUD hide:YES];
            PionOneManager *manager = [PionOneManager sharedInstance];
            manager.APConfigurationDone = YES;
            manager.cachedPassword = nil;
            [self.navigationController popViewControllerAnimated:YES];
        }];
    }]];
    

    [self presentViewController:errorHandlingAlert animated:YES completion:nil];

}

- (void)countDownProgress {
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        // Do something useful in the background and update the HUD periodically.
        // This just increases the progress indicator in a loop.
        float progress = 0.0f;
        while (progress < 1.0f) {
            progress += 0.01f;
            dispatch_async(dispatch_get_main_queue(), ^{
                // Instead we could have also passed a reference to the HUD
                // to the HUD to myProgressTask as a method parameter.
                self.progressHUD.progress = progress;
            });
            usleep(400000);
        }
    });
}

- (void)cancelConfiguration {
    PionOneManager *manager = [PionOneManager sharedInstance];
    manager.APConfigurationDone = NO;
    [manager cancel];
    [self.progressHUD hide:YES];
    
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)configurationgDone {
    [self.progressHUD hide:YES];
    PionOneManager *manager = [PionOneManager sharedInstance];
    manager.APConfigurationDone = YES;
    manager.cachedPassword = nil;
    [[[UIAlertView alloc] initWithTitle:@"Success!" message:nil delegate:self cancelButtonTitle:@"Done" otherButtonTitles: nil] show];
}

#pragma mark - AlertView Delegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 0 && [[alertView buttonTitleAtIndex:0] isEqualToString:@"Done"]) {
        [self.navigationController popViewControllerAnimated:YES];
    }
    if (buttonIndex == 1 && [[alertView buttonTitleAtIndex:1] isEqualToString:@"OK"]) {
        NSURL*url=[NSURL URLWithString:@"prefs:root=WIFI"];
        if (![[PionOneManager sharedInstance] isConnectedToPionOne]) {
            [self startCheckingNodeAPConnection];
        }
        [[UIApplication sharedApplication] openURL:url];
    }
}

- (void)showAlertMsg:(NSString *)msg {
    UIAlertView *alart = [[UIAlertView alloc] initWithTitle:@"Info"
                                message:msg delegate:self
                      cancelButtonTitle:@"OK"
                      otherButtonTitles:nil];
    alart.opaque = NO;
    [alart show];
}
- (void)registerAPconfigLocalNotification{
    
    UIUserNotificationType types = UIUserNotificationTypeAlert | UIUserNotificationTypeSound;
    UIUserNotificationSettings *connectToNodeSettings = [UIUserNotificationSettings settingsForTypes:types categories:nil];
    
    [[UIApplication sharedApplication] registerUserNotificationSettings:connectToNodeSettings];
    
}


#pragma mark -  TextFielDelegate methods
// when user tap Enter or Return
-(BOOL)textFieldShouldReturn:(UITextField *)textField
{
    UITextField *passwordTextField = [_userInputDialog.textFields objectAtIndex:0];
    UITextField *nameTextField = [_userInputDialog.textFields objectAtIndex:1];
    if (nameTextField.text.length == 0) {
        return NO;
    }
    [self.userInputDialog dismissViewControllerAnimated:YES completion:nil];
    [self startConfiguration];
    return YES;
}
- (void)textFieldDidChange {
    UITextField *passwordTextField = [_userInputDialog.textFields objectAtIndex:0];
    UITextField *nameTextField = [_userInputDialog.textFields objectAtIndex:1];
    if (nameTextField.text.length == 0) {
        [_userInputDialog.actions objectAtIndex:1].enabled = NO;
    } else {
        [_userInputDialog.actions objectAtIndex:1].enabled = YES;
    }
}

#pragma mark - Navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    id dVC = segue.destinationViewController;
    if ([dVC isKindOfClass:[WiFiListTVC class]]) {
        [(WiFiListTVC *)dVC setPresentingVC:self];
    }
}
@end
