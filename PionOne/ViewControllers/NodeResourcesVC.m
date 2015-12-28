//
//  NodeResourcesVC.m
//  PionOne
//
//  Created by Qxn on 15/9/13.
//  Copyright © 2015年 SeeedStudio. All rights reserved.
//

#import "NodeResourcesVC.h"
#import "MBProgressHUD.h"
#import "AFNetworking.h"
#import "UIScrollView+EmptyDataSet.h"

@interface NodeResourcesVC () <UIWebViewDelegate, UIScrollViewDelegate, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate>
@property (strong, nonatomic) IBOutlet UIWebView *webView;
@property (nonatomic, strong) UIRefreshControl *refreshControl;
@property (nonatomic, strong) UIActivityIndicatorView *webIndicator;
@property (nonatomic, assign) BOOL didFailLoading;

@end
@implementation NodeResourcesVC

- (void)viewDidLoad {
    [super viewDidLoad];
    //Init right bar botton
    CGRect barIconRect = CGRectMake(0, 0, 28, 28);
    self.webIndicator = [[UIActivityIndicatorView alloc] initWithFrame:barIconRect];
    self.webIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyleWhite;
    self.webIndicator.hidesWhenStopped = YES;
    self.webView.scrollView.emptyDataSetDelegate = self;
    self.webView.scrollView.emptyDataSetSource = self;
    
    UIBarButtonItem *indicatorItem = [[UIBarButtonItem alloc] initWithCustomView:self.webIndicator];
    CGImageRef ref = [[UIImage imageNamed:@"iconShare"] CGImage];
    UIImage *image = [UIImage imageWithCGImage:ref scale:5.0 orientation:UIImageOrientationDown];
    UIBarButtonItem *shareItem = [[UIBarButtonItem alloc] initWithImage:image style:UIBarButtonItemStylePlain target:self action:@selector(shareAPIs)];
    UIBarButtonItem *space = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:self action:nil];
    space.width = 40;
    [self.navigationItem setRightBarButtonItems:@[shareItem, space, space, indicatorItem]];

    //init webView
//    self.webView = [[UIWebView alloc] initWithFrame:self.view.frame];
//    [self.view addSubview:self.webView];
    self.webView.delegate = self;
    self.webView.scrollView.delegate = self;
    self.webView.scalesPageToFit = NO;
    
    //init refreshcotrol
    self.refreshControl = [[UIRefreshControl alloc] init];
    UIFont * font = [UIFont systemFontOfSize:14.0];
    NSDictionary *attributes = @{NSFontAttributeName:font, NSForegroundColorAttributeName : [UIColor blackColor]};
    self.refreshControl.attributedTitle = [[NSAttributedString alloc] initWithString:@"Pull to refresh" attributes:attributes];
    [self.webView.scrollView addSubview:self.refreshControl];

    NSURL *url = [NSURL URLWithString:self.node.apiURL];
    NSURLRequest *request = [NSURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData timeoutInterval:10.0];
    [self.webView loadRequest:request];
    [self.webIndicator startAnimating];
    
}


- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.webView setNeedsLayout];
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    if( self.refreshControl.isRefreshing )
        [self refresh];
}

- (void)refresh {
    if (!self.webView.isLoading) {
        [self.webView reload];
    } else {
        [self.refreshControl endRefreshing];
    }
}

- (void)shareAPIs {
    UIImage *shareImage = [UIImage imageNamed:@"shareImage"];
    [self shareText:self.node.name andImage:shareImage andUrl:[NSURL URLWithString:self.node.apiURL]];
}
- (void)shareText:(NSString *)text andImage:(UIImage *)image andUrl:(NSURL *)url
{
    NSMutableArray *sharingItems = [NSMutableArray new];
    
    if (text) {
        [sharingItems addObject:text];
    }
    if (image) {
        [sharingItems addObject:image];
    }
    if (url) {
        [sharingItems addObject:url];
    }
    
    UIActivityViewController *activityController = [[UIActivityViewController alloc] initWithActivityItems:sharingItems applicationActivities:nil];
    [self presentViewController:activityController animated:YES completion:nil];
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
    [self.refreshControl endRefreshing];
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
    self.webView.scrollView.scrollEnabled = NO;
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


- (void)showNodeDetails {
    [self performSegueWithIdentifier:@"ShowNodeDetail" sender:nil];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
//    id dVC = [segue destinationViewController];
}

@end
