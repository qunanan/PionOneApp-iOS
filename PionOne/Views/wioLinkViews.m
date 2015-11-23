//
//  wioLinkViews.m
//  Wiolink
//
//  Created by Qxn on 15/11/23.
//  Copyright (c) 2015 Seeed. All rights reserved.
//
//

#import "wioLinkViews.h"


@implementation wioLinkViews

#pragma mark Cache

static UIColor* _wioLinkRed = nil;
static UIColor* _wioLinkBlue = nil;
static UIColor* _wioLinkBrown = nil;

#pragma mark Initialization

+ (void)initialize
{
    // Colors Initialization
    _wioLinkRed = [UIColor colorWithRed: 0.745 green: 0.078 blue: 0.118 alpha: 1];
    _wioLinkBlue = [UIColor colorWithRed: 0.145 green: 0.275 blue: 0.49 alpha: 1];
    _wioLinkBrown = [UIColor colorWithRed: 0.353 green: 0.353 blue: 0.353 alpha: 1];

}

#pragma mark Colors

+ (UIColor*)wioLinkRed { return _wioLinkRed; }
+ (UIColor*)wioLinkBlue { return _wioLinkBlue; }
+ (UIColor*)wioLinkBrown { return _wioLinkBrown; }

#pragma mark Drawing Methods

+ (void)drawGroveButtonWithPressed: (BOOL)pressed configured: (BOOL)configured
{

    //// Rectangle 40 Drawing
    UIBezierPath* rectangle40Path = [UIBezierPath bezierPathWithRect: CGRectMake(1, 1, 64, 32)];
    [wioLinkViews.wioLinkRed setStroke];
    rectangle40Path.lineWidth = 2;
    [rectangle40Path stroke];


    if (configured)
    {
        //// Rectangle 2 Drawing
        UIBezierPath* rectangle2Path = [UIBezierPath bezierPathWithRect: CGRectMake(2, 2, 62, 30)];
        [wioLinkViews.wioLinkBlue setFill];
        [rectangle2Path fill];
        [wioLinkViews.wioLinkBlue setStroke];
        rectangle2Path.lineWidth = 1.38;
        [rectangle2Path stroke];
    }


    if (pressed)
    {
        //// Rectangle Drawing
        UIBezierPath* rectanglePath = [UIBezierPath bezierPathWithRect: CGRectMake(1, 1, 64, 32)];
        [wioLinkViews.wioLinkRed setFill];
        [rectanglePath fill];
        [wioLinkViews.wioLinkRed setStroke];
        rectanglePath.lineWidth = 1.38;
        [rectanglePath stroke];
    }
}

@end
