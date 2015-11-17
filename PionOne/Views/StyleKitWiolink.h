//
//  StyleKitWiolink.h
//  Wiolink
//
//  Created by Qxn on 15/11/17.
//  Copyright (c) 2015 Seeed. All rights reserved.
//
//  Generated by PaintCode (www.paintcodeapp.com)
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>


@interface StyleKitWiolink : NSObject

// Colors
+ (UIColor*)wioLinkRed;
+ (UIColor*)wioLinkBlue;
+ (UIColor*)wioLinkBrown;

// Drawing Methods
+ (void)drawGuide3;
+ (void)drawApconfig;
+ (void)drawGuide1;
+ (void)drawGuide2;
+ (void)drawWlBtnN;
+ (void)drawWlBtnH;
+ (void)drawSignUpHighLight;
+ (void)drawSignUpNormal;
+ (void)drawSignInNormal;
+ (void)drawSignInHighLight;
+ (void)drawIconGrove;
+ (void)drawIconAccount;
+ (void)drawIconInfo;
+ (void)drawIconShare;
+ (void)drawIconLogout;
+ (void)drawWioLink;
+ (void)drawGroveButtonWithPressed: (BOOL)pressed configured: (BOOL)configured;

@end