//
//  NSString+escapedUnicode.m
//  PionOne
//
//  Created by Qxn on 15/10/19.
//  Copyright © 2015年 SeeedStudio. All rights reserved.
//

#import "NSString+escapedUnicode.h"

@implementation NSString (escapedUnicode)

- (NSString *)escapedUnicode {
    NSMutableString *uniString = [ [ NSMutableString alloc ] init ];
    UniChar *uniBuffer = (UniChar *) malloc ( sizeof(UniChar) * [ self length ] );
    CFRange stringRange = CFRangeMake ( 0, [ self length ] );
    
    CFStringGetCharacters ( (CFStringRef)self, stringRange, uniBuffer );
    
    for ( int i = 0; i < [ self length ]; i++ ) {
        if ( uniBuffer[i] > 0x7e )
            [ uniString appendFormat: @"\\u%04x", uniBuffer[i] ];
        else
            [ uniString appendFormat: @"%c", uniBuffer[i] ];
    }
    
    free ( uniBuffer );
    
    NSString *retString = [ NSString stringWithString: uniString ];
    
    return retString;
}

- (NSString *)nonLossyASCIIString {
    const char *cString = [self cStringUsingEncoding:NSUTF8StringEncoding];
    NSString *string = [NSString stringWithCString:cString encoding:NSNonLossyASCIIStringEncoding];
    return string;
}
@end
