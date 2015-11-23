//
//  StyleKitWiolink.h
//  Wiolink
//
//  Created by Qxn on 15/11/23.
//  Copyright (c) 2015 Seeed. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>


@interface wioLinkViews : NSObject

// Colors
+ (UIColor*)wioLinkRed;
+ (UIColor*)wioLinkBlue;
+ (UIColor*)wioLinkBrown;

// Drawing Methods
+ (void)drawGroveButtonWithPressed: (BOOL)pressed configured: (BOOL)configured;

@end
