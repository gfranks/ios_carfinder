//
//  AlertHUDView.h
//  Rent.com
//
//  Created by Garrett Franks on 4/18/13.
//  Copyright (c) 2013 Garrett Franks. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AlertHUDView : UIView

@property (nonatomic, weak) IBOutlet UILabel *hudLabel;
@property (nonatomic, weak) IBOutlet UIActivityIndicatorView *hudIndicator;
@property (nonatomic, weak) IBOutlet UIView *hudMessageContainer;
@property (nonatomic, strong) UIViewController *containerController;

+ (id)showHUDWithMessage:(NSString*)message
        inViewController:(UIViewController*)controller;
- (void)updateAndShowHUDWithMessage:(NSString*)message
                   inViewController:(UIViewController*)controller;
- (void)dismiss;

@end
