//
//  ListImageItem.h
//  RETableViewManagerExample
//
//  Created by Roman Efimov on 4/2/13.
//  Copyright (c) 2013 Roman Efimov. All rights reserved.
//

#import "RETableViewItem.h"

@interface ListImageItem : RETableViewItem

@property (copy, readwrite, nonatomic) NSString *imageName;
@property (nonatomic, strong) UIImage *qrImage;

+ (ListImageItem *)itemWithImageNamed:(NSString *)imageName;
+ (ListImageItem *)itemWithImage:(UIImage *)image;
@end
