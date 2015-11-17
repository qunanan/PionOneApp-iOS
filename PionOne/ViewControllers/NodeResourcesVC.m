//
//  NodeResourcesVC.m
//  PionOne
//
//  Created by Qxn on 15/9/13.
//  Copyright © 2015年 SeeedStudio. All rights reserved.
//

#import "NodeResourcesVC.h"
#import <GoogleMaterialIconFont/GoogleMaterialIconFont-Swift.h>
//#import <FBSDKShareKit/FBSDKShareKit.h>
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
    self.webIndicator = [[UIActivityIndicatorView alloc] initWithFrame:barIconRect];
    self.webIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyleWhite;
    self.webIndicator.hidesWhenStopped = YES;
    
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
    [self shareText:self.node.name andImage:nil andUrl:[NSURL URLWithString:self.node.apiURL]];
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
