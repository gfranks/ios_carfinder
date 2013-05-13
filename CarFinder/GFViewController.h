//
//  GFViewController.h
//  CarFinder
//
//  Created by Garrett Franks on 5/9/13.
//  Copyright (c) 2013 Garrett Franks. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import "CarFinderAnnotationView.h"
#import "XBPageDragView.h"
#import <MTDirectionsKit/MTDirectionsKit.h>
#import "TwoLineTitleView.h"

@interface GFViewController : UIViewController <UIAlertViewDelegate, MTDDirectionsDelegate, MKMapViewDelegate, XBPageDragViewDelegate>

@property (nonatomic, strong) MTDMapView *mapView;
@property (nonatomic, strong) UIButton *carDirectionsButton;
@property (nonatomic, strong) TwoLineTitleView *twoLineTitleView;

@end
