//
//  NodeResourcesVC.m
//  PionOne
//
//  Created by Qxn on 15/9/13.
//  Copyright © 2015年 SeeedStudio. All rights reserved.
//

#import "NodeResourcesVC.h"
#import <GoogleMaterialIconFont/GoogleMaterialIconFont-Swift.h>
#import <FBSDKShareKit/FBSDKShareKit.h>
#import "NodeDetailTVC.h"
#import "MBProgressHUD.h"

@interface NodeResourcesVC () <UIWebViewDelegate>
@property (strong, nonatomic) UIWebView *webView;
@property (nonatomic, strong) MBProgressHUD *HUD;
@property (nonatomic, strong) UIRefreshControl *refreshControl;
@end
@implementation NodeResourcesVC


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
    UIButton *shareButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [shareButton setFrame:barIconRect];
    [shareButton setTitle:[NSString materialIcon:MaterialIconFontShare] forState:UIControlStateNormal];
    [shareButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [shareButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateHighlighted];
    shareButton.titleLabel.font = [UIFont materialIconOfSize:28];
    [shareButton addTarget:self action:@selector(shareAPIs)forControlEvents:UIControlEventTouchUpInside];

    UIButton *detailButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [detailButton setFrame:barIconRect];
    [detailButton setTitle:[NSString materialIcon:MaterialIconFontDetails] forState:UIControlStateNormal];
    [detailButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [detailButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateHighlighted];
    detailButton.titleLabel.font = [UIFont materialIconOfSize:28];
    [detailButton addTarget:self action:@selector(showNodeDetails)forControlEvents:UIControlEventTouchUpInside];

    UIBarButtonItem *detailItem = [[UIBarButtonItem alloc] initWithCustomView:detailButton];
    UIBarButtonItem *shareItem = [[UIBarButtonItem alloc] initWithCustomView:shareButton];
    UIBarButtonItem *space = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:self action:nil];
    space.width = 20;
    [self.navigationItem setRightBarButtonItems:@[detailItem, space, shareItem]];

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

    NSURL *url = [NSURL URLWithString:self.node.apiURL];
    NSURLRequest *request = [NSURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData timeoutInterval:10.0];
    [self.webView loadRequest:request];
    [self.HUD show:YES];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    [self.HUD hide:YES];
    [self.refreshControl endRefreshing];
}
- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    [self.HUD hide:YES];
    [self.refreshControl endRefreshing];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.webView setNeedsLayout];
}

- (void)refresh {
    NSURL *url = [NSURL URLWithString:self.node.apiURL];
    NSURLRequest *request = [NSURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData timeoutInterval:10.0];
    [self.webView loadRequest:request];
}

- (void)shareAPIs {
    UIAlertController *shareDialog = [UIAlertController alertControllerWithTitle:@"Share the APIs" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    UIAlertAction *facebook = [UIAlertAction actionWithTitle:@"Facebook" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        FBSDKShareLinkContent *content = [[FBSDKShareLinkContent alloc] init];
        content.contentURL = [NSURL URLWithString:self.node.apiURL];
        [FBSDKShareDialog showFromViewController:self
                                     withContent:content
                                        delegate:nil];
    }];
    UIAlertAction *messenger = [UIAlertAction actionWithTitle:@"Messenger" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        FBSDKShareLinkContent *content = [[FBSDKShareLinkContent alloc] init];
        content.contentURL = [NSURL URLWithString:self.node.apiURL];
        [FBSDKMessageDialog showWithContent:content delegate:nil];
    }];
    UIAlertAction *copyUrl = [UIAlertAction actionWithTitle:@"Copy Page URL" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [UIPasteboard generalPasteboard].string = self.node.apiURL;
    }];

    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
    [shareDialog addAction:copyUrl];
    [shareDialog addAction:facebook];
    [shareDialog addAction:messenger];
    [shareDialog addAction:cancel];
    [self presentViewController:shareDialog animated:YES completion:nil];
}

- (void)showNodeDetails {
    [self performSegueWithIdentifier:@"ShowNodeDetail" sender:nil];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    id dVC = [segue destinationViewController];
    if ([dVC isKindOfClass:[NodeDetailTVC class]]) {
        [(NodeResourcesVC *)dVC setNode:self.node];
    }
}

@end
