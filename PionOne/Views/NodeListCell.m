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
#import <GoogleMaterialIconFont/GoogleMaterialIconFont-Swift.h>
#import "StyleKitWiolink.h"

@implementation NodeListCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
    self.contentView.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
    for (UIImageView *icon in self.groveIcons) {
        icon.layer.masksToBounds = YES;
        icon.layer.cornerRadius = 17.5;
        icon.layer.borderColor = [[StyleKitWiolink wioLinkRed] CGColor];
    }
}

- (void)prepareForReuse {
    [super prepareForReuse];
    for (UIImageView *icon in self.groveIcons) {
        icon.image = nil;
        icon.layer.borderWidth = 0;
    }
    self.moreIndicatorLabel.text = nil;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)setGroves:(NSArray *)groves {
    _groves = groves;

    NSInteger screenWidth = [UIScreen mainScreen].applicationFrame.size.width;
    NSInteger maxIcons;
    switch (screenWidth) {
        case 320:
            maxIcons = 4;
            break;
        case 375:
            maxIcons = 5;
            break;
        case 414:
            maxIcons = 6;
            break;
        default:
            maxIcons = 4;
            break;
    }
    if (_groves != nil) {
        for (Grove *grove in groves) {
            if ([groves indexOfObject:grove] >= maxIcons) {
                self.moreIndicatorLabel.text = [NSString materialIcon:MaterialIconFontMoreHoriz];
                self.moreIndicatorLabel.font = [UIFont materialIconOfSize:18];
                break;
            } else {
                self.moreIndicatorLabel.text = nil;
            }
            NSURL *url = [NSURL URLWithString:grove.driver.imageURL];
            UIImageView *icon = [self.groveIcons objectAtIndex:[groves indexOfObject:grove]];
            [icon sd_setImageWithURL:url placeholderImage:[UIImage imageNamed:@"placeHolder"]];
            icon.layer.borderWidth = 0.5;
        }
    }
}

@end
