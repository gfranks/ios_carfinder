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

@interface GFViewController : UIViewController <UIAlertViewDelegate, MKMapViewDelegate>

@property (nonatomic, strong) IBOutlet UIView *mapContainerView;
@property (nonatomic, strong) MKMapView *mapView;
@property (nonatomic, strong) UIButton *carDirectionsButton;

@end
