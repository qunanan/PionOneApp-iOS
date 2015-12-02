//
//  AboutViewController.m
//  PionOne
//
//  Created by Qxn on 15/10/29.
//  Copyright © 2015年 SeeedStudio. All rights reserved.
//

#import "AboutViewController.h"
#import "MBProgressHUD.h"
#import "UIScrollView+EmptyDataSet.h"
#import <GoogleMaterialIconFont/GoogleMaterialIconFont-Swift.h>

@interface AboutViewController () <UIWebViewDelegate, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate>
@property (strong, nonatomic) IBOutlet UIWebView *webView;
@property (nonatomic, strong) MBProgressHUD *HUD;
@property (nonatomic, strong) UIRefreshControl *refreshControl;
@property (nonatomic, strong) UIActivityIndicatorView *webIndicator;
@property (nonatomic, assign) BOOL didFailLoading;

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
    self.webView.scrollView.emptyDataSetDelegate = self;
    self.webView.scrollView.emptyDataSetSource = self;
    UIButton *homeBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [homeBtn setFrame:barIconRect];
    [homeBtn setTitle:[NSString materialIcon:MaterialIconFontHome] forState:UIControlStateNormal];
    [homeBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [homeBtn setTitleColor:[UIColor lightGrayColor] forState:UIControlStateHighlighted];
    homeBtn.titleLabel.font = [UIFont materialIconOfSize:28];
    [homeBtn addTarget:self action:@selector(gotoHomePage) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *indicatorItem = [[UIBarButtonItem alloc] initWithCustomView:self.webIndicator];
    UIBarButtonItem *homeItem = [[UIBarButtonItem alloc] initWithCustomView:homeBtn];
    UIBarButtonItem *space = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:self action:nil];
    space.width = 20;
    [self.navigationItem setRightBarButtonItems:@[homeItem, space, space, space, indicatorItem]];

    //init webView
//    CGRect webFrame = CGRectMake(0, self.navigationController.navigationBar.frame.size.height + [UIApplication sharedApplication].statusBarFrame.size.height, self.navigationController.navigationBar.frame.size.width, [UIScreen mainScreen].applicationFrame.size.height - self.navigationController.navigationBar.frame.size.height);
//    self.webView = [[UIWebView alloc] initWithFrame:webFrame];
//    [self.view addSubview:self.webView];
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
    
}

- (void)webViewDidStartLoad:(UIWebView *)webView {
    [self.webIndicator startAnimating];
    [self.refreshControl endRefreshing];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    [self.webIndicator stopAnimating];
    [self.refreshControl endRefreshing];
    self.didFailLoading = NO;
    [self.webView.scrollView reloadEmptyDataSet];
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
                [self.refreshControl endRefreshing];
            default:
                errorMsg = [error localizedDescription];
                NSLog(@"%@",errorMsg);
                break;
        }
    } else {
        errorMsg = [error localizedDescription];
        NSLog(@"%@",errorMsg);
    }
    self.didFailLoading = YES;
    [self.webIndicator stopAnimating];
    [self.webView.scrollView reloadEmptyDataSet];
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    self.didFailLoading = NO;
    
    return YES;
}

#pragma -mark EmptyDataSet Datasource
- (UIImage *)imageForEmptyDataSet:(UIScrollView *)scrollView
{
    if (self.webView.isLoading || !self.didFailLoading) {
        return nil;
    }
    
    float scale = 3* 380.0/[UIScreen mainScreen].applicationFrame.size.width;
    
    UIImage *scaledImage = [UIImage imageWithCGImage:[[UIImage imageNamed:@"sorryPage"] CGImage] scale:scale orientation:UIImageOrientationUp];
    return scaledImage;
}

- (NSAttributedString *)descriptionForEmptyDataSet:(UIScrollView *)scrollView
{
    if (self.webView.isLoading || !self.didFailLoading) {
        return nil;
    }
    NSString *text = @"We had a problem loading this for you.\nPlease check your network and try again.";
    
    NSMutableParagraphStyle *paragraph = [NSMutableParagraphStyle new];
    paragraph.lineBreakMode = NSLineBreakByWordWrapping;
    paragraph.alignment = NSTextAlignmentCenter;
    
    NSDictionary *attributes = @{NSFontAttributeName: [UIFont systemFontOfSize:14.0f],
                                 NSForegroundColorAttributeName: [UIColor lightGrayColor],
                                 NSParagraphStyleAttributeName: paragraph};
    
    return [[NSAttributedString alloc] initWithString:text attributes:attributes];
}

- (UIColor *)backgroundColorForEmptyDataSet:(UIScrollView *)scrollView
{
    if (self.webView.isLoading || !self.didFailLoading) {
        return [UIColor clearColor];
    }
    return [UIColor whiteColor];
}

#pragma -mark EmptyDataSet Delegate
- (BOOL)emptyDataSetShouldDisplay:(UIScrollView *)scrollView
{
    return YES;
}
- (BOOL)emptyDataSetShouldAllowScroll:(UIScrollView *)scrollView
{
    return YES;
}


- (void)refresh {
    [self.webView reload];
}

- (void)gotoHomePage {
    [self.webView stopLoading];
    NSURL *url = [NSURL URLWithString:@"http://iot.seeed.cc"];
    NSURLRequest *request = [NSURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData timeoutInterval:10.0];
    [self.webView loadRequest:request];
}
@end
