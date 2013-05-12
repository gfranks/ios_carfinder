//
//  XBPageDragView.m
//  XBPageCurl
//
//  Created by xiss burg on 6/7/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "XBPageDragView.h"

@interface XBPageDragView ()

@property (nonatomic, assign) BOOL pageIsCurled;
@property (nonatomic, strong) XBPageCurlView *pageCurlView;
@property (nonatomic, strong) XBSnappingPoint *curledSnappingPoint;
@property (nonatomic, strong) UIButton *uncurlButton;
@property (nonatomic, assign) int touchesCount;

@end

@implementation XBPageDragView

@synthesize cornerSnappingPoint = _cornerSnappingPoint;

- (void)dealloc
{
    [self.pageCurlView stopAnimating];
}

#pragma mark - Properties

- (void)setViewToCurl:(UIView *)viewToCurl
{
    if (viewToCurl == _viewToCurl) {
        return;
    }
    
    _viewToCurl = viewToCurl;
    
    [self.pageCurlView removeFromSuperview];
    self.pageCurlView = nil;
    
    if (_viewToCurl == nil) {
        return;
    }
    
    [self refreshPageCurlView];
}

- (XBSnappingPoint *)cornerSnappingPoint
{
    if (_cornerSnappingPoint == nil) {
        _cornerSnappingPoint = [[XBSnappingPoint alloc] init];
        _cornerSnappingPoint.position = CGPointMake(self.viewToCurl.frame.size.width, self.viewToCurl.frame.size.height);
        _cornerSnappingPoint.angle = 3*M_PI_4;
        _cornerSnappingPoint.radius = 30;
    }
    return _cornerSnappingPoint;
}

#pragma mark - Methods

- (void)uncurlPageAnimated:(BOOL)animated completion:(void (^)(void))completion
{
    NSTimeInterval duration = animated? 0.3: 0;
    [self.pageCurlView setCylinderPosition:self.cornerSnappingPoint.position animatedWithDuration:duration];
    [self.pageCurlView setCylinderAngle:self.cornerSnappingPoint.angle animatedWithDuration:duration];
    
    __weak XBPageDragView *weakSelf = self;
    [self.pageCurlView setCylinderRadius:self.cornerSnappingPoint.radius animatedWithDuration:duration completion:^{
        weakSelf.hidden = NO;
        weakSelf.pageIsCurled= NO;
        if (weakSelf.delegate && [weakSelf.delegate respondsToSelector:@selector(pageDidCurl:)]) {
            [weakSelf.delegate pageDidCurl:NO];
        }
        weakSelf.viewToCurl.hidden = NO;
        [weakSelf.pageCurlView removeFromSuperview];
        [weakSelf.uncurlButton removeFromSuperview];
        [weakSelf.pageCurlView stopAnimating];
        if (completion) {
            completion();
        }
    }];
}

- (void)refreshPageCurlView
{
    [self.pageCurlView removeFromSuperview];
    [self.uncurlButton removeFromSuperview];
    self.pageCurlView = [[XBPageCurlView alloc] initWithFrame:self.viewToCurl.frame];
    self.pageCurlView.delegate = self;
    self.pageCurlView.pageOpaque = YES;
    self.pageCurlView.opaque = NO;
    self.pageCurlView.snappingEnabled = YES;
    
    [self.pageCurlView.snappingPoints addObject:self.cornerSnappingPoint];
    
    XBSnappingPoint *point = [[XBSnappingPoint alloc] init];
    point.position = CGPointMake(self.viewToCurl.frame.size.width*0.5, self.viewToCurl.frame.size.height*0.4);
    point.angle = 7*M_PI/8;
    point.radius = 80;
    [self.pageCurlView.snappingPoints addObject:point];
    self.curledSnappingPoint = point;
    
    [self.pageCurlView drawViewOnFrontOfPage:self.viewToCurl];
}

-(void)uncurlTapped:(id)sender {
    [self uncurlPageAnimated:YES completion:nil];
}

-(void)createUncurlButton {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.backgroundColor = [UIColor clearColor];
    [button addTarget:self action:@selector(uncurlTapped:) forControlEvents:UIControlEventAllTouchEvents];
    button.frame = CGRectMake(0,0,self.superview.frame.size.width, self.curledSnappingPoint.position.y*1.5);
    [self.superview addSubview:button];
    self.uncurlButton = button;
}

#pragma mark - Touches

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self.uncurlButton removeFromSuperview];
    UITouch *touch = [touches anyObject];
    CGPoint touchLocation = [touch locationInView:self.viewToCurl.superview];
    _touchesCount = 0;
    
    if (CGRectContainsPoint(self.frame, touchLocation)) {
        self.hidden = YES;
        _pageIsCurled = YES;
        if (_delegate && [_delegate respondsToSelector:@selector(pageDidCurl:)]) {
            [_delegate pageDidCurl:YES];
        }
        [self.pageCurlView drawViewOnFrontOfPage:self.viewToCurl];
        self.pageCurlView.cylinderPosition = self.cornerSnappingPoint.position;
        self.pageCurlView.cylinderAngle = self.cornerSnappingPoint.angle;
        self.pageCurlView.cylinderRadius = self.cornerSnappingPoint.radius;
        [self.pageCurlView touchBeganAtPoint:touchLocation];
        [self.viewToCurl.superview addSubview:self.pageCurlView];
        self.viewToCurl.hidden = YES;
        [self.pageCurlView startAnimating];
    }
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (self.pageIsCurled) {
        UITouch *touch = [touches anyObject];
        CGPoint touchLocation = [touch locationInView:self.viewToCurl.superview];
        [self.pageCurlView touchMovedToPoint:touchLocation];
        _touchesCount++;
    }
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (self.pageIsCurled) {
        UITouch *touch = [touches anyObject];
        CGPoint touchLocation = [touch locationInView:self.viewToCurl.superview];
        if (_touchesCount) {
            [self.pageCurlView touchEndedAtPoint:touchLocation];
        } else {
            [self.pageCurlView touchMovedToPoint:CGPointMake(210, 130)];
            [self.pageCurlView performSelector:@selector(touchEndedAtPoint:) withObject:[NSValue valueWithCGPoint:CGPointMake(210, 130)] afterDelay:0.2];
        }
    }
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (self.pageIsCurled) {
        UITouch *touch = [touches anyObject];
        CGPoint touchLocation = [touch locationInView:self.viewToCurl.superview];
        [self.pageCurlView touchEndedAtPoint:touchLocation];
    }
}

#pragma mark - XBPageCurlViewDelegate

- (void)pageCurlView:(XBPageCurlView *)pageCurlView didSnapToPoint:(XBSnappingPoint *)snappintPoint
{
    if (snappintPoint == self.cornerSnappingPoint) {
        self.hidden = NO;
        _pageIsCurled = NO;
        if (_delegate && [_delegate respondsToSelector:@selector(pageDidCurl:)]) {
            [_delegate pageDidCurl:NO];
        }
        self.viewToCurl.hidden = NO;
        [self.pageCurlView removeFromSuperview];
        [self.pageCurlView stopAnimating];
        [self.uncurlButton removeFromSuperview];
    } else if (snappintPoint == self.curledSnappingPoint) {
        [self.uncurlButton removeFromSuperview];
        [self createUncurlButton];
    }
}

@end
