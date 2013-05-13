//
//  TwoLineTitleView.h
//  Rent.com
//
//  Created by Andre Leite on 4/1/13.
//  Copyright (c) 2013 Primedia. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TwoLineTitleView : UIView

@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *subTitleLabel;

- (id) initWithFrame:(CGRect)aRect title:(NSString *)title subTitle:(NSString *)subTitle;

@end
