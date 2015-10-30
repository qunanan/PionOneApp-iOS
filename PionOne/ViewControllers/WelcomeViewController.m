//
//  WelcomeViewController.m
//  WiFi IoT Node
//
//  Created by Qxn on 15/7/1.
//  Copyright © 2015年 SeeedStudio. All rights reserved.
//

#import "WelcomeViewController.h"
#import "AppDelegate.h"
#import "AFNetworking.h"
#import "NSString+Email.h"
#import "PionOneManager.h"
#import "SignUpVC.h"

@interface WelcomeViewController () <UIScrollViewDelegate, UIGestureRecognizerDelegate>
@property (weak, nonatomic) IBOutlet UIImageView *backgroundImage;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UIPageControl *pageControl;
@property (weak, nonatomic) IBOutlet UIButton *signUpButton;
@property (weak, nonatomic) IBOutlet UIButton *signInButton;

@property (strong, nonatomic) PionOneManager *manager;
@end



@implementation WelcomeViewController

- (PionOneManager *)manager {
    if (_manager == nil) {
        _manager = [PionOneManager sharedInstance];
    }
    return _manager;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.scrollView.frame = self.view.frame;

    [self createViewOne];
    [self createViewTwo];
    [self createViewThree];
    
    self.scrollView.contentSize = CGSizeMake(self.view.frame.size.width*3, self.scrollView.frame.size.height);
    
    //This is the starting point of the ScrollView
    CGPoint scrollPoint = CGPointMake(0, 0);
    [self.scrollView setContentOffset:scrollPoint animated:YES];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)createViewOne{
    
    UIView *view = [[UIView alloc] initWithFrame:self.scrollView.frame];
    CGRect screenFrame = [UIScreen mainScreen].applicationFrame;
    CGRect imageFrame = CGRectMake((screenFrame.size.width - 272)/2, (screenFrame.size.height - 331) /2 - 20, 272, 331);
    UIImageView *imageview = [[UIImageView alloc] initWithFrame:imageFrame];
    imageview.contentMode = UIViewContentModeScaleAspectFill;
    imageview.image = [UIImage imageNamed:@"Intro1"];
    [view addSubview:imageview];
    
    
    self.scrollView.delegate = self;
    [self.scrollView addSubview:view];
    
}

- (void)scrollViewDidScroll:(nonnull UIScrollView *)scrollView {
    CGFloat pageWidth = CGRectGetWidth(self.view.bounds);
    CGFloat pageFraction = self.scrollView.contentOffset.x / pageWidth;
    self.pageControl.currentPage = roundf(pageFraction);

}

-(void)createViewTwo{
    
    CGFloat originWidth = self.scrollView.frame.size.width;
    CGFloat originHeight = self.scrollView.frame.size.height;
    
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(originWidth, 0, originWidth, originHeight)];
    
    CGRect screenFrame = [UIScreen mainScreen].applicationFrame;
    CGRect imageFrame = CGRectMake((screenFrame.size.width - 270)/2, (screenFrame.size.height - 308) /2 - 20, 270, 308);
    UIImageView *imageview = [[UIImageView alloc] initWithFrame:imageFrame];
    imageview.contentMode = UIViewContentModeScaleAspectFit;
    imageview.image = [UIImage imageNamed:@"Intro2"];
    [view addSubview:imageview];
    
    
    [self.scrollView addSubview:view];
    
}

-(void)createViewThree{
    
    CGFloat originWidth = self.scrollView.frame.size.width;
    CGFloat originHeight = self.scrollView.frame.size.height;
    
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(originWidth*2, 0, originWidth, originHeight)];
    
    CGRect screenFrame = [UIScreen mainScreen].applicationFrame;
    CGRect imageFrame = CGRectMake((screenFrame.size.width - 272)/2, (screenFrame.size.height - 343) /2 - 20, 272, 343);
    UIImageView *imageview = [[UIImageView alloc] initWithFrame:imageFrame];
    imageview.contentMode = UIViewContentModeScaleAspectFit;
    imageview.image = [UIImage imageNamed:@"Intro3"];
    [view addSubview:imageview];
    
    
    [self.scrollView addSubview:view];
    
}

- (IBAction)signUpButtonPushed:(id)sender {
    UIStoryboard*  mainStoryboard = [UIStoryboard storyboardWithName:@"Main"
                                                  bundle:nil];
    SignUpVC *dVC = [mainStoryboard instantiateViewControllerWithIdentifier:@"SignUpNVC"];
    [self presentViewController:dVC animated:YES completion:nil];
    dVC = nil;
}


#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    //self.navigationController.navigationBar.hidden = NO;
}

- (void)login {
//    [self performSegueWithIdentifier:@"LoginSegue" sender:nil];
    self.signInButton.enabled = NO;
    self.signUpButton.enabled = NO;
//    [[PionOneManager sharedInstance] getNodeListWithCompletionHandler:^(BOOL succse, NSString *msg) {
//        if (succse) {
//        } else {
//            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:nil
//                                                                message:msg
//                                                               delegate:nil
//                                                      cancelButtonTitle:@"Ok"
//                                                      otherButtonTitles:nil];
//            [alertView show];
//            self.signInButton.enabled = YES;
//            self.signUpButton.enabled = YES;
//        }
//
//    }];
    UIWindow *window = [[[UIApplication sharedApplication] windows] firstObject];
    [UIView transitionWithView:window
                      duration:0.5
                       options:UIViewAnimationOptionTransitionFlipFromLeft
                    animations:^{ window.rootViewController = [window.rootViewController.storyboard instantiateViewControllerWithIdentifier:@"MainVC"]; }
                    completion:nil];
}


@end

