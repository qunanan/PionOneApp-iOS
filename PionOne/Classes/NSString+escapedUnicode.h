//
//  NSString+escapedUnicode.h
//  PionOne
//
//  Created by Qxn on 15/10/19.
//  Copyright © 2015年 SeeedStudio. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (escapedUnicode)
- (NSString *)escapedUnicode;
- (NSString *)nonLossyASCIIString;
@end
