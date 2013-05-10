//
//  GFViewController.m
//  CarFinder
//
//  Created by Garrett Franks on 5/9/13.
//  Copyright (c) 2013 Garrett Franks. All rights reserved.
//

#import "GFViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "LocationManager.h"

#define Add_Pin_Alert_Tag 101
#define Get_Dir_Alert_Tag 102

@interface GFViewController() {
    CarFinderAnnotationView *carFinderAnnotationView;
    UIImageView *splashView;
    UILabel *viewControllerTitle;
    UIButton *clearMapButton, *getDirButton, *userLocationButton;
    UISegmentedControl *mapTypeControl;
    UIView *mapControlsContainer;
}

@end

@implementation GFViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [[LocationManager sharedInstance] startListeningForLocation];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(locationReceived:) name:@"locationAcquired" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(locationError:) name:@"locationError" object:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self loadTitle];
    [self loadNavItems];
    [self loadIntroView];
    [self loadSubviews];
}

- (void)loadTitle {
    viewControllerTitle = [[UILabel alloc] initWithFrame:CGRectZero];
    viewControllerTitle.backgroundColor = [UIColor clearColor];
    viewControllerTitle.font = [UIFont boldSystemFontOfSize:20.0];
    viewControllerTitle.shadowColor = [UIColor whiteColor];
    viewControllerTitle.shadowOffset = CGSizeMake(0, 1);
    viewControllerTitle.textAlignment = NSTextAlignmentCenter;
    viewControllerTitle.textColor = [UIColor colorWithRed:(115/255.f) green:(115/255.f) blue:(115/255.f) alpha:1.0f];
    self.navigationItem.titleView = viewControllerTitle;
    viewControllerTitle.text = @"Car Finder";
    [viewControllerTitle sizeToFit];
    self.navigationController.navigationBar.tintColor = [UIColor colorWithRed:(225/255.f) green:(225/255.f) blue:(225/255.f) alpha:1.0f];
}

- (void)loadNavItems {
    UIButton *closeButton = [[UIButton alloc] initWithFrame:CGRectMake(5, 5, 52, 35)];
    [closeButton setTitleEdgeInsets:UIEdgeInsetsMake(0, 10, 0, 0)];
    [closeButton setContentHorizontalAlignment:UIControlContentHorizontalAlignmentLeft];
    [closeButton setTitleColor:[UIColor colorWithRed:(115/255.f) green:(115/255.f) blue:(115/255.f) alpha:1.0f] forState:UIControlStateNormal];
    [closeButton setTitleShadowColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [closeButton.titleLabel setShadowColor:[UIColor whiteColor]];
    [closeButton.titleLabel setShadowOffset:CGSizeMake(0, 1)];
    [closeButton setBackgroundImage:[[UIImage imageNamed:@"button-navbar-light-up"] resizableImageWithCapInsets:UIEdgeInsetsMake(9, 9, 9, 9)] forState:UIControlStateNormal];
    [closeButton setBackgroundImage:[[UIImage imageNamed:@"button-navbar-light-down"] resizableImageWithCapInsets:UIEdgeInsetsMake(9, 9, 9, 9)] forState:UIControlStateSelected];
    [closeButton setBackgroundImage:[[UIImage imageNamed:@"button-navbar-light-down"] resizableImageWithCapInsets:UIEdgeInsetsMake(9, 9, 9, 9)] forState:UIControlStateHighlighted];
    [closeButton addTarget:self action:@selector(dismissCarFinder) forControlEvents:UIControlEventTouchUpInside];
    [closeButton setTitle:@"Close" forState:UIControlStateNormal];
    closeButton.titleLabel.font = [UIFont boldSystemFontOfSize:12.0];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:closeButton];
}

- (void)loadIntroView {
    [self.navigationController setNavigationBarHidden:YES animated:NO];
    
    splashView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"splash_image"]];
    [self performSelector:@selector(dismissIntroView) withObject:nil afterDelay:4.0];
    
    [self.view addSubview:splashView];    
}

- (void)loadSubviews {
    [self.view setBackgroundColor:[UIColor colorWithRed:(225/255.f) green:(225/255.f) blue:(225/255.f) alpha:1.0f]];
    
    CGRect screenRect = [UIScreen mainScreen].bounds;
    
    mapControlsContainer = [[UIView alloc] initWithFrame:CGRectMake(0, 0, screenRect.size.width, screenRect.size.height-125)];
    mapTypeControl = [[UISegmentedControl alloc] initWithItems:[NSArray arrayWithObjects:@"Standard", @"Hybrid", @"Satellite", nil]];
    mapTypeControl.frame = CGRectMake((screenRect.size.width/2)-140, mapControlsContainer.frame.size.height - 50, 280, 44);
    [mapControlsContainer addSubview:mapTypeControl];
    [self.view insertSubview:mapControlsContainer belowSubview:splashView];
    
    _mapView = [[MKMapView alloc] initWithFrame:CGRectMake(0, 0, screenRect.size.width, screenRect.size.height-125)];
    [_mapView setShowsUserLocation:YES];
    _mapView.delegate = self;
    _mapView.layer.masksToBounds = NO;
    _mapView.layer.shadowOffset = CGSizeMake(0, 1);
    _mapView.layer.shadowRadius = 3;
    _mapView.layer.shadowOpacity = 0.6;
    _mapView.layer.shadowPath = [UIBezierPath bezierPathWithRect:CGRectMake(0, 0, _mapView.frame.size.width, _mapView.frame.size.height)].CGPath;
    UILongPressGestureRecognizer *lpgr = [[UILongPressGestureRecognizer alloc] initWithTarget:self
                                                                                       action:@selector(addPointToMap:)];
    lpgr.minimumPressDuration = 2.0;
    [_mapView addGestureRecognizer:lpgr];
    [self.view insertSubview:_mapView belowSubview:splashView];
    
    userLocationButton = [[UIButton alloc] initWithFrame:CGRectMake(10, _mapView.frame.size.height-57, 46, 46)];
    [userLocationButton setBackgroundImage:[UIImage imageNamed:@"button-my-location-centered"] forState:UIControlStateNormal];
    [userLocationButton addTarget:self action:@selector(centerAtCurrentLocation) forControlEvents:UIControlEventTouchUpInside];
    [self.view insertSubview:userLocationButton belowSubview:splashView];
    
    clearMapButton = [[UIButton alloc] initWithFrame:CGRectMake(5, _mapView.frame.size.height + 5, (screenRect.size.width/2)-8, 45)];
    [clearMapButton setTitleEdgeInsets:UIEdgeInsetsMake(0, 10, 0, 0)];
    [clearMapButton setContentHorizontalAlignment:UIControlContentHorizontalAlignmentCenter];
    [clearMapButton setTitleColor:[UIColor colorWithRed:(115/255.f) green:(115/255.f) blue:(115/255.f) alpha:1.0f] forState:UIControlStateNormal];
    [clearMapButton setTitleShadowColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [clearMapButton.titleLabel setFont:[UIFont boldSystemFontOfSize:15.0]];
    [clearMapButton.titleLabel setShadowColor:[UIColor whiteColor]];
    [clearMapButton.titleLabel setShadowOffset:CGSizeMake(0, 1)];
    [clearMapButton setBackgroundImage:[[UIImage imageNamed:@"button-navbar-light-up"] resizableImageWithCapInsets:UIEdgeInsetsMake(9, 9, 9, 9)] forState:UIControlStateNormal];
    [clearMapButton setBackgroundImage:[[UIImage imageNamed:@"button-navbar-light-down"] resizableImageWithCapInsets:UIEdgeInsetsMake(9, 9, 9, 9)] forState:UIControlStateSelected];
    [clearMapButton setBackgroundImage:[[UIImage imageNamed:@"button-navbar-light-down"] resizableImageWithCapInsets:UIEdgeInsetsMake(9, 9, 9, 9)] forState:UIControlStateHighlighted];
    [clearMapButton addTarget:self action:@selector(clearMapPoints) forControlEvents:UIControlEventTouchUpInside];
    [clearMapButton setTitle:@"Clear Markers" forState:UIControlStateNormal];
    [self.view insertSubview:clearMapButton belowSubview:splashView];
    
    getDirButton = [[UIButton alloc] initWithFrame:CGRectMake(clearMapButton.frame.size.width+10, _mapView.frame.size.height + 5, (screenRect.size.width/2)-7, 45)];
    [getDirButton setTitleEdgeInsets:UIEdgeInsetsMake(0, 10, 0, 0)];
    [getDirButton setContentHorizontalAlignment:UIControlContentHorizontalAlignmentCenter];
    [getDirButton setTitleColor:[UIColor colorWithRed:(115/255.f) green:(115/255.f) blue:(115/255.f) alpha:1.0f] forState:UIControlStateNormal];
    [getDirButton setTitleShadowColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [getDirButton.titleLabel setFont:[UIFont boldSystemFontOfSize:15.0]];
    [getDirButton.titleLabel setShadowColor:[UIColor whiteColor]];
    [getDirButton.titleLabel setShadowOffset:CGSizeMake(0, 1)];
    [getDirButton setBackgroundImage:[[UIImage imageNamed:@"button-navbar-light-up"] resizableImageWithCapInsets:UIEdgeInsetsMake(9, 9, 9, 9)] forState:UIControlStateNormal];
    [getDirButton setBackgroundImage:[[UIImage imageNamed:@"button-navbar-light-down"] resizableImageWithCapInsets:UIEdgeInsetsMake(9, 9, 9, 9)] forState:UIControlStateSelected];
    [getDirButton setBackgroundImage:[[UIImage imageNamed:@"button-navbar-light-down"] resizableImageWithCapInsets:UIEdgeInsetsMake(9, 9, 9, 9)] forState:UIControlStateHighlighted];
    [getDirButton addTarget:self action:@selector(askForDirections) forControlEvents:UIControlEventTouchUpInside];
    [getDirButton setTitle:@"Directions" forState:UIControlStateNormal];
    [self.view insertSubview:getDirButton belowSubview:splashView];
}

#pragma mark - Dismissal methods

- (void)dismissIntroView {
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    [UIView animateWithDuration:0.5 animations:^{
        [splashView setAlpha:0.0];
    } completion:^(BOOL finished) {
        [splashView removeFromSuperview];
        splashView = nil;
    }];
}

- (void)dismissCarFinder {
    abort();
}

#pragma mark - Add&Remove mapview annotations

- (void)addPointToMap:(UIGestureRecognizer *)gestureRecognizer {
    if (gestureRecognizer.state != UIGestureRecognizerStateBegan)
        return;
    
    CGPoint touchPoint = [gestureRecognizer locationInView:_mapView];
    CLLocationCoordinate2D touchMapCoordinate =
    [self.mapView convertPoint:touchPoint toCoordinateFromView:_mapView];
    
    carFinderAnnotationView = [[CarFinderAnnotationView alloc] initWithCoordinate:touchMapCoordinate];
    
    UIAlertView *annotationAlert = [[UIAlertView alloc] initWithTitle:@"Track Car Location"
                                                              message:@"Would you like to add a car location pin here?"
                                                             delegate:self
                                                    cancelButtonTitle:@"NO"
                                                    otherButtonTitles:@"YES", nil];
    annotationAlert.tag = Add_Pin_Alert_Tag;
    [annotationAlert show];
}

- (void)addPointAtUserLocation {
    carFinderAnnotationView = [[CarFinderAnnotationView alloc] initWithCoordinate:_mapView.userLocation.coordinate];
    
    UIAlertView *annotationAlert = [[UIAlertView alloc] initWithTitle:@"Track Car Location"
                                                              message:@"Would you like to add a car location pin here?"
                                                             delegate:self
                                                    cancelButtonTitle:@"NO"
                                                    otherButtonTitles:@"YES", nil];
    annotationAlert.tag = Add_Pin_Alert_Tag;
    [annotationAlert show];
}

- (void)clearMapPoints {
    carFinderAnnotationView = nil;
    [_mapView removeAnnotations:_mapView.annotations];
}

- (void)askForDirections {
    if (carFinderAnnotationView != nil) {
        UIAlertView *showDirAlert = [[UIAlertView alloc] initWithTitle:@"Directions"
                                                               message:@"Would you like directions to your car's location?"
                                                              delegate:self
                                                     cancelButtonTitle:@"NO"
                                                     otherButtonTitles:@"YES", nil];
        showDirAlert.tag = Get_Dir_Alert_Tag;
        [showDirAlert show];
    } else {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"No Car Locaion"
                                                        message:@"You have not placed your car's location on the map yet."
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
    }
}

#pragma mark - Location methods

- (void)locationError:(NSNotification*)notification {
    if ([[LocationManager sharedInstance] getLocationServicesStatus] == LocationServicesStatusDenied) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Location Error"
                                                        message:@"Please go to your settings and enable location services for this app."
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
    }
}

- (void)locationReceived:(NSNotification*)notification {
    if ([[notification object] isKindOfClass:[CLLocation class]]) {
        MKCoordinateSpan span = MKCoordinateSpanMake(0.04, 0.04);
        MKCoordinateRegion region = {[[notification object] coordinate], span};
        [_mapView setRegion:region animated:YES];
    }
}

- (void)centerAtCurrentLocation {
    MKCoordinateSpan span = MKCoordinateSpanMake(0.04, 0.04);
    MKCoordinateRegion region = {_mapView.userLocation.coordinate, span};
    [_mapView setRegion:region animated:YES];
}

#pragma mark - UIAlertViewDelegate methods

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (alertView.tag == Add_Pin_Alert_Tag) {
        if (buttonIndex == 1) {
            [_mapView removeAnnotations:_mapView.annotations];
            [_mapView addAnnotation:carFinderAnnotationView];
        } else {
            carFinderAnnotationView = nil;
        }
    } else if (alertView.tag == Get_Dir_Alert_Tag) {
        if (buttonIndex == 1) {
            MKPlacemark* placeMark = [[MKPlacemark alloc] initWithCoordinate:carFinderAnnotationView.coordinate addressDictionary:nil];
            MKMapItem* destination = [[MKMapItem alloc] initWithPlacemark:placeMark];
            destination.name = @"Your Car's Location";
            [destination openInMapsWithLaunchOptions:@{MKLaunchOptionsDirectionsModeKey:MKLaunchOptionsDirectionsModeWalking}];
        }
    }
}

#pragma mark - MKMapViewDelegate methods

- (void)mapView:(MKMapView *)aMapView didUpdateUserLocation:(MKUserLocation *)aUserLocation {
    if ([userLocationButton isSelected]) {
        [self centerAtCurrentLocation];
    }
}

- (MKAnnotationView *)mapView:(MKMapView *)mapview viewForAnnotation:(id <MKAnnotation>)annotation {
    if ([annotation isKindOfClass:[MKUserLocation class]]) {
        return nil;
    }
    
    static NSString* AnnotationIdentifier = @"AnnotationIdentifier";
    MKAnnotationView *annotationView = [mapview dequeueReusableAnnotationViewWithIdentifier:AnnotationIdentifier];
    if(annotationView)
        return annotationView;
    else
    {
        MKAnnotationView *annotationView = [[MKAnnotationView alloc] initWithAnnotation:annotation
                                                                         reuseIdentifier:AnnotationIdentifier];
        annotationView.canShowCallout = NO;
        annotationView.image = [UIImage imageNamed:@"car_pin_image"];
        annotationView.draggable = NO;
        return annotationView;
    }
    return nil;
}

- (void)mapView:(MKMapView *)mapView didAddAnnotationViews:(NSArray *)annotationViews {
    for (MKAnnotationView *annView in annotationViews) {
        if (annView.annotation == mapView.userLocation) {
            annView.canShowCallout = YES;
            UIButton *addCarLocationButton = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
            [addCarLocationButton addTarget:self action:@selector(addPointAtUserLocation) forControlEvents:UIControlEventTouchUpInside];
            annView.rightCalloutAccessoryView = addCarLocationButton;
            break;
        } else {
            CGRect endFrame = annView.frame;
            annView.frame = CGRectOffset(endFrame, 0, -500);
            [UIView animateWithDuration:0.5
                             animations:^{ annView.frame = endFrame; }];
        }
    }
}

- (void)mapView:(MKMapView *)mapView didSelectAnnotationView:(MKAnnotationView *)view {
    if ([view.annotation isKindOfClass:[MKUserLocation class]]) {
        return;
    }
    
    [self askForDirections];
    [mapView deselectAnnotation:view.annotation animated:NO];
}

#pragma mark - Cleanup methods

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"locationAcquired" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"locationError" object:nil];
    [_mapView removeFromSuperview];
    _mapView = nil;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

@end
