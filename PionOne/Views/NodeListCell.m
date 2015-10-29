//
//  NodeListCell.m
//  PionOne
//
//  Created by Qxn on 15/10/3.
//  Copyright © 2015年 SeeedStudio. All rights reserved.
//

#import "NodeListCell.h"
#import "Grove.h"
#import "Driver.h"
#import <SDWebImage/UIImageView+WebCache.h>

@implementation NodeListCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
    self.contentView.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
    for (UIImageView *icon in self.groveIcons) {
        icon.layer.masksToBounds = YES;
        icon.layer.cornerRadius = 17.5;
        icon.layer.borderColor = [[UIColor lightGrayColor] CGColor];
    }
}

- (void)prepareForReuse {
    [super prepareForReuse];
    for (UIImageView *icon in self.groveIcons) {
        icon.image = nil;
        icon.layer.borderWidth = 0;
    }
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)setGroves:(NSArray *)groves {
    if (_groves != groves && groves != nil) {
        _groves = groves;
        for (Grove *grove in groves) {
            if ([groves indexOfObject:grove] >= 5) {
                break;
            }
            if ([UIScreen mainScreen].applicationFrame.size.width <= 320 && [groves indexOfObject:grove] >= 4) {
                break;
            }
            NSURL *url = [NSURL URLWithString:grove.driver.imageURL];
            UIImageView *icon = [self.groveIcons objectAtIndex:[groves indexOfObject:grove]];
            [icon sd_setImageWithURL:url placeholderImage:[UIImage imageNamed:@"ic_extension_36pt"]];
            icon.layer.borderWidth = 0.5;
        }
    }
}

@end
