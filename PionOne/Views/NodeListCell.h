//
//  NodeListCell.h
//  PionOne
//
//  Created by Qxn on 15/10/3.
//  Copyright © 2015年 SeeedStudio. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MGSwipeTableCell.h"

@interface NodeListCell : MGSwipeTableCell
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UIView *onlineIndicator;
@property (strong, nonatomic) NSArray *groves;
@property (strong, nonatomic) IBOutletCollection(UIImageView) NSArray *groveIcons;

@end
