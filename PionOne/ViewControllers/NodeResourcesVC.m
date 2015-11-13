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
#import "AFNetworking.h"

@interface NodeResourcesVC () <UIWebViewDelegate>
@property (strong, nonatomic) IBOutlet UIWebView *webView;
@property (nonatomic, strong) UIRefreshControl *refreshControl;
@property (nonatomic, strong) UILabel *messageLabel;
@property (nonatomic, strong) UIActivityIndicatorView *webIndicator;

@end
@implementation NodeResourcesVC

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

    self.webIndicator = [[UIActivityIndicatorView alloc] initWithFrame:barIconRect];
    self.webIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyleWhite;
    self.webIndicator.hidesWhenStopped = YES;
    
    UIBarButtonItem *indicatorItem = [[UIBarButtonItem alloc] initWithCustomView:self.webIndicator];
    UIBarButtonItem *detailItem = [[UIBarButtonItem alloc] initWithCustomView:detailButton];
    UIBarButtonItem *shareItem = [[UIBarButtonItem alloc] initWithCustomView:shareButton];
    UIBarButtonItem *space = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:self action:nil];
    space.width = 20;
    [self.navigationItem setRightBarButtonItems:@[detailItem, space, shareItem, space, space, indicatorItem]];

    //init webView
//    self.webView = [[UIWebView alloc] initWithFrame:self.view.frame];
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

    NSURL *url = [NSURL URLWithString:self.node.apiURL];
    NSURLRequest *request = [NSURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData timeoutInterval:10.0];
    [self.webView loadRequest:request];
    [self.webIndicator startAnimating];
    
    //init label
    self.messageLabel = [[UILabel alloc] initWithFrame:self.view.frame];
    //self.messageLabel.center = self.view.center;
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
                self.webView.scrollView.contentSize = self.messageLabel.frame.size;
            default:
                errorMsg = [error localizedDescription];
                if ([errorMsg containsString:@"The request timed out"]) {
                    [self.webIndicator stopAnimating];
                    [self.refreshControl endRefreshing];
                    self.messageLabel.hidden = NO;
                    [self.webView reload];
                    self.webView.scrollView.contentSize = self.messageLabel.frame.size;
                }
                NSLog(@"%@",errorMsg);
                break;
        }
    } else {
        errorMsg = [error localizedDescription];
        NSLog(@"%@",errorMsg);
    }
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
