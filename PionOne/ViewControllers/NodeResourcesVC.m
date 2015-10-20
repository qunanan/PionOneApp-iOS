//
//  NodeResourcesVC.m
//  PionOne
//
//  Created by Qxn on 15/9/13.
//  Copyright © 2015年 SeeedStudio. All rights reserved.
//

#import "NodeResourcesVC.h"

@interface NodeResourcesVC () <UIWebViewDelegate>
@property (weak, nonatomic) IBOutlet UIWebView *webView;

@end
@implementation NodeResourcesVC

- (void)viewDidLoad {
    [super viewDidLoad];
    self.webView.delegate = self;
    self.webView.scalesPageToFit = NO;
    NSURL *url = [NSURL URLWithString:self.urlStr];
    NSURLRequest *request = [NSURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData timeoutInterval:30.0];
    [self.webView loadRequest:request];
}
@end
