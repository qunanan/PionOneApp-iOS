//
//  ListImageCell.m
//  RETableViewManagerExample
//
//  Created by Roman Efimov on 4/2/13.
//  Copyright (c) 2013 Roman Efimov. All rights reserved.
//

#import "ListImageCell.h"

@interface ListImageCell ()

@property (strong, readwrite, nonatomic) UIImageView *pictureView;

@end

@implementation ListImageCell

+ (CGFloat)heightWithItem:(NSObject *)item tableViewManager:(RETableViewManager *)tableViewManager
{
    return 250;
}

- (void)cellDidLoad
{
    [super cellDidLoad];
    self.pictureView = [[UIImageView alloc] initWithFrame:CGRectMake((self.frame.size.width-250)/2, 0, 250, 250)];
    self.pictureView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    [self addSubview:self.pictureView];
}

- (void)cellWillAppear
{
    [super cellWillAppear];
    [self.pictureView setImage:self.item.qrImage];
}

- (void)cellDidDisappear
{
    
}

@end
