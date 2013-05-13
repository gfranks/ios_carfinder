//
//  TwoLineTitleView.m
//  Rent.com
//
//  Created by Andre Leite on 4/1/13.
//  Copyright (c) 2013 Primedia. All rights reserved.
//

#import "TwoLineTitleView.h"

@implementation TwoLineTitleView

- (id) initWithFrame:(CGRect)aRect title:(NSString *)title subTitle:(NSString *)subTitle {
    self = [super initWithFrame:aRect];
    if (self) {
        self.titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 8, self.frame.size.width, 14)];
        _titleLabel.backgroundColor = [UIColor clearColor];
        _titleLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        _titleLabel.adjustsFontSizeToFitWidth = YES;
        _titleLabel.textAlignment = NSTextAlignmentCenter;
        _titleLabel.text = title;
        _titleLabel.font = [UIFont boldSystemFontOfSize:16];
        _titleLabel.textColor =  [UIColor colorWithRed:(115/255.f) green:(115/255.f) blue:(115/255.f) alpha:1.0f];
        _titleLabel.shadowColor = [UIColor whiteColor];
        _titleLabel.shadowOffset = CGSizeMake(0, 1);
        [self addSubview:_titleLabel];
        
        self.subTitleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 23, self.frame.size.width, 14)];
        _subTitleLabel.backgroundColor = [UIColor clearColor];
        _subTitleLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        _subTitleLabel.adjustsFontSizeToFitWidth = YES;
        _subTitleLabel.textAlignment = NSTextAlignmentCenter;
        _subTitleLabel.font = [UIFont boldSystemFontOfSize:12];
        _subTitleLabel.text = subTitle;
        _subTitleLabel.textColor =  [UIColor colorWithRed:(115/255.f) green:(115/255.f) blue:(115/255.f) alpha:1.0f];
        _subTitleLabel.shadowColor = [UIColor whiteColor];
        _subTitleLabel.shadowOffset = CGSizeMake(0, 1);
        [self addSubview:_subTitleLabel];
    }
    return self;
}

@end
