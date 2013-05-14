//
//  AlertHUDView.m
//  Rent.com
//
//  Created by Garrett Franks on 4/18/13.
//  Copyright (c) 2013 Garrett Franks. All rights reserved.
//

#import "AlertHUDView.h"
#import <QuartzCore/QuartzCore.h>

#define kOperationFinished @"isFinished"
#define kHUDTag 1991

@interface AlertHUDView () {
    BOOL hudShowing;
    NSArray *leftControllerNavItems, *rightControllerNavItems;
    UIBarButtonItem *backControllerNavItem, *leftControllerNavItem, *rightControllerNavItem;
}

@end

@implementation AlertHUDView

+ (id)showHUDWithMessage:(NSString*)message
        inViewController:(UIViewController*)controller {
    AlertHUDView *hud = [[[NSBundle mainBundle] loadNibNamed:@"AlertHUDView"
                                                       owner:self
                                                     options:nil] lastObject];
    
    if (hud) {
        [hud.hudLabel setText:message];
        hud.containerController = controller;
        hud.frame = controller.view.frame;
        hud.alpha = 0.0;
        [hud setupViews];
        [hud show];
    }
    
    return hud;
}

- (void)updateAndShowHUDWithMessage:(NSString*)message
                   inViewController:(UIViewController*)controller {
    [_hudLabel setText:message];
    _containerController = controller;
    self.frame = controller.view.frame;
    self.alpha = 0.0;
    [self setupViews];
    
    if (!hudShowing) {
        [self show];
    }
}

- (void)setupViews {
    int origin_y = self.frame.size.height/2 - _hudMessageContainer.frame.size.height;
    _hudMessageContainer.frame = CGRectMake(_hudMessageContainer.frame.origin.x, origin_y, _hudMessageContainer.frame.size.width, _hudMessageContainer.frame.size.height);
    _hudMessageContainer.layer.cornerRadius = 10.0f;
}

- (void)show {
    hudShowing = YES;
    [_containerController.navigationItem setHidesBackButton:YES animated:YES];
    leftControllerNavItems = _containerController.navigationItem.leftBarButtonItems;
    leftControllerNavItem = _containerController.navigationItem.leftBarButtonItem;
    rightControllerNavItems = _containerController.navigationItem.rightBarButtonItems;
    rightControllerNavItem = _containerController.navigationItem.rightBarButtonItem;
    backControllerNavItem = _containerController.navigationItem.backBarButtonItem;
    _containerController.navigationItem.leftBarButtonItems = nil;
    _containerController.navigationItem.leftBarButtonItem = nil;
    _containerController.navigationItem.rightBarButtonItems = nil;
    _containerController.navigationItem.rightBarButtonItem = nil;
    _containerController.navigationItem.backBarButtonItem = nil;
    [_containerController.view addSubview:self];
    [_hudIndicator startAnimating];
    [UIView animateWithDuration:0.3 animations:^{
        self.alpha = 1.0;
    }];
}

- (void)dismiss {
    [_containerController.navigationItem setHidesBackButton:NO animated:YES];
    [UIView animateWithDuration:0.3 animations:^{
        self.alpha = 0.0;
    } completion:^(BOOL finished) {
        [_hudIndicator stopAnimating];
        [self removeFromSuperview];
        _containerController.navigationItem.leftBarButtonItems = leftControllerNavItems;
        _containerController.navigationItem.leftBarButtonItem = leftControllerNavItem;
        _containerController.navigationItem.rightBarButtonItems = rightControllerNavItems;
        _containerController.navigationItem.rightBarButtonItem = rightControllerNavItem;
        _containerController.navigationItem.backBarButtonItem = backControllerNavItem;
        hudShowing = NO;
    }];
}

@end
