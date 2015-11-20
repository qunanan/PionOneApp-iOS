//
//  NodeListCell.h
//  PionOne
//
//  Created by Qxn on 15/10/3.
//  Copyright © 2015年 SeeedStudio. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MGSwipeTableCell/MGSwipeTableCell.h>

@interface NodeListCell : MGSwipeTableCell
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UIView *onlineIndicator;
@property (weak, nonatomic) IBOutlet UILabel *onlineLabel;
@property (strong, nonatomic) NSArray *groves;
@property (strong, nonatomic) IBOutletCollection(UIImageView) NSArray *groveIcons;
@property (weak, nonatomic) IBOutlet UILabel *moreIndicatorLabel;

@end
