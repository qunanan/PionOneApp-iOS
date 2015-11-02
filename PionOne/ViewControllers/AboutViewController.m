//
//  AboutViewController.m
//  PionOne
//
//  Created by Qxn on 15/10/29.
//  Copyright © 2015年 SeeedStudio. All rights reserved.
//

#import "AboutViewController.h"
#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <FBSDKLoginKit/FBSDKLoginKit.h>
#import <FBSDKShareKit/FBSDKShareKit.h>
#import "MBProgressHUD.h"
#import <GoogleMaterialIconFont/GoogleMaterialIconFont-Swift.h>

@interface AboutViewController () <UIWebViewDelegate>
@property (strong, nonatomic) UIWebView *webView;
@property (nonatomic, strong) MBProgressHUD *HUD;
@property (nonatomic, strong) UIRefreshControl *refreshControl;
@property (nonatomic, strong) UILabel *messageLabel;
@property (nonatomic, strong) UIActivityIndicatorView *webIndicator;

@end

@implementation AboutViewController
- (MBProgressHUD *)HUD {
    if (_HUD == nil) {
        _HUD = [[MBProgressHUD alloc] initWithView:self.navigationController.view];
        [self.navigationController.view addSubview:_HUD];
    }
    return _HUD;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    //Init right bar botton
    CGRect barIconRect = CGRectMake(0, 0, 28, 28);
    self.webIndicator = [[UIActivityIndicatorView alloc] initWithFrame:barIconRect];
    self.webIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyleWhite;
    self.webIndicator.hidesWhenStopped = YES;

    UIBarButtonItem *indicatorItem = [[UIBarButtonItem alloc] initWithCustomView:self.webIndicator];
    UIBarButtonItem *space = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:self action:nil];
    space.width = 100;
    [self.navigationItem setRightBarButtonItems:@[space, indicatorItem]];

    //init webView
    self.webView = [[UIWebView alloc] initWithFrame:self.view.frame];
    [self.view addSubview:self.webView];
    self.webView.delegate = self;
    self.webView.scalesPageToFit = NO;

    //init refreshcotrol
    self.refreshControl = [[UIRefreshControl alloc] init];
    UIFont * font = [UIFont systemFontOfSize:14.0];
    NSDictionary *attributes = @{NSFontAttributeName:font, NSForegroundColorAttributeName : [UIColor blackColor]};
    self.refreshControl.attributedTitle = [[NSAttributedString alloc] initWithString:@"Pull to refresh" attributes:attributes];
    [self.refreshControl addTarget:self action:@selector(refresh) forControlEvents:UIControlEventValueChanged];
    [self.webView.scrollView addSubview:self.refreshControl];
    
    NSURL *url = [NSURL URLWithString:@"http://iot.seeed.cc"];
    NSURLRequest *request = [NSURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData timeoutInterval:10.0];
    [self.webView loadRequest:request];
    [self.webIndicator startAnimating];
    
    //init label
    self.messageLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.webView.frame.size.width, 80)];
//    self.messageLabel.center = self.webView.center;
    self.messageLabel.hidden = YES;
    self.messageLabel.backgroundColor = [UIColor whiteColor];
    self.messageLabel.text = @"We had a problem loading this for you.\nPlease check your network and try again.";
    self.messageLabel.alpha = 0.9;
    self.messageLabel.textAlignment = NSTextAlignmentCenter;
    self.messageLabel.lineBreakMode = NSLineBreakByCharWrapping;
    self.messageLabel.numberOfLines = 0;
    [self.webView.scrollView addSubview:self.messageLabel];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    [self.webIndicator stopAnimating];
    [self.refreshControl endRefreshing];
    self.messageLabel.hidden = YES;
}
- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    NSString *errorMsg;
    
    if ([[error domain] isEqualToString:NSURLErrorDomain]) {
        switch ([error code]) {
            case NSURLErrorCannotFindHost:
                errorMsg = NSLocalizedString(@"Cannot find specified host. Retype URL.", nil);
            case NSURLErrorCannotConnectToHost:
                errorMsg = NSLocalizedString(@"Cannot connect to specified host. Server may be down.", nil);
            case NSURLErrorNotConnectedToInternet:
                errorMsg = NSLocalizedString(@"Cannot connect to the internet. Service may not be available.", nil);
                [self.webIndicator stopAnimating];
                [self.refreshControl endRefreshing];
                self.messageLabel.hidden = NO;
            default:
                errorMsg = [error localizedDescription];
                break;
        }
    } else {
        errorMsg = [error localizedDescription];
    }
}

- (void)refresh {
    NSURL *url = [NSURL URLWithString:@"http://iot.seeed.cc"];
    NSURLRequest *request = [NSURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData timeoutInterval:10.0];
    [self.webView loadRequest:request];
    [self.refreshControl endRefreshing];
    self.messageLabel.hidden = YES;
    [self.webIndicator startAnimating];
}
@end
