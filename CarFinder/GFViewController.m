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
#import "AlertHUDView.h"

#define Add_Pin_Alert_Tag 101
#define Get_Dir_Alert_Tag 102
#define End_Nav_Alert_Tag 103

@interface GFViewController() {
    CarFinderAnnotationView *carFinderAnnotationView;
    UIImageView *splashView;
    UIButton *clearMapButton, *getDirButton, *userLocationButton;
    XBPageDragView *pageDragView;
    
    UISegmentedControl *mapTypeControl, *directionsTypeControl;
    UILabel *mapTypeLabel;
    int directionsType;
    
    BOOL showingDirections;
    
    NSNumberFormatter *formatter;
    AlertHUDView *hudView;
}

@end

@implementation GFViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [[LocationManager sharedInstance] startListeningForLocation];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(locationReceived:) name:@"locationAcquired" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(locationError:) name:@"locationError" object:nil];
    formatter = [[NSNumberFormatter alloc] init];    
    [formatter setNumberStyle:NSNumberFormatterDecimalStyle];
    [formatter setMaximumFractionDigits:2];
    [formatter setRoundingMode: NSNumberFormatterRoundUp];
    directionsType = [[NSUserDefaults standardUserDefaults] integerForKey:@"directionsType"];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self loadTitle];
    [self loadIntroView];
    [self loadSubviews];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [pageDragView refreshPageCurlView];
}

- (void)loadTitle {
    _twoLineTitleView = [[TwoLineTitleView alloc] initWithFrame:CGRectMake(5, 0, 310, 44) title:@"Car Finder" subTitle:@"Not tracking car's location"];
    self.navigationItem.titleView = _twoLineTitleView;
    self.navigationController.navigationBar.tintColor = [UIColor colorWithRed:(225/255.f) green:(225/255.f) blue:(225/255.f) alpha:1.0f];
}

- (void)loadIntroView {
    [self.navigationController setNavigationBarHidden:YES animated:NO];
    
    splashView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"splash_image"]];
    [self performSelector:@selector(dismissIntroView) withObject:nil afterDelay:4.0];
    
    [self.view addSubview:splashView];    
}

- (void)loadSubviews {
    CGRect screenRect = [UIScreen mainScreen].bounds;
    [self.view setBackgroundColor:[UIColor colorWithRed:(225/255.f) green:(225/255.f) blue:(225/255.f) alpha:1.0f]];
    
    [self setupMap];
    [self setupMapControls];
    [self setupActionButtons];
    
    userLocationButton = [[UIButton alloc] initWithFrame:CGRectMake(10, _mapView.frame.size.height-57, 46, 46)];
    [userLocationButton setBackgroundImage:[UIImage imageNamed:@"button-my-location-centered"] forState:UIControlStateNormal];
    [userLocationButton addTarget:self action:@selector(centerAtCurrentLocation) forControlEvents:UIControlEventTouchUpInside];
    [self.view insertSubview:userLocationButton belowSubview:splashView];
    
    UIImageView *layerImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"button-layers-entrypoint"]];
    layerImageView.frame = CGRectMake(64 - layerImageView.frame.size.width, 64 - layerImageView.frame.size.height, layerImageView.frame.size.width, layerImageView.frame.size.height);
    layerImageView.contentMode = UIViewContentModeRight;
    pageDragView = [[XBPageDragView alloc] initWithFrame:CGRectMake(screenRect.size.width - 64, _mapView.frame.size.height-64, 64, 64)];
    [pageDragView addSubview:layerImageView];
    pageDragView.viewToCurl = _mapView;
    pageDragView.delegate = self;
    [self.view insertSubview:pageDragView belowSubview:splashView];
}

- (void)setupMap {
    CGRect screenRect = [UIScreen mainScreen].bounds;
    _mapView = [[MTDMapView alloc] initWithFrame:CGRectMake(0, 0, screenRect.size.width, screenRect.size.height-120)];
    [_mapView setShowsUserLocation:YES];
    _mapView.delegate = self;
    UILongPressGestureRecognizer *lpgr = [[UILongPressGestureRecognizer alloc] initWithTarget:self
                                                                                       action:@selector(addPointToMap:)];
    lpgr.minimumPressDuration = 1.0;
    [_mapView addGestureRecognizer:lpgr];
    [self.view insertSubview:_mapView belowSubview:splashView];
    
    _mapView.layer.masksToBounds = NO;
    _mapView.layer.shadowOffset = CGSizeMake(0, 1);
    _mapView.layer.shadowRadius = 3;
    _mapView.layer.shadowOpacity = 0.6;
    _mapView.layer.shadowPath = [UIBezierPath bezierPathWithRect:CGRectMake(0, 0, _mapView.frame.size.width, _mapView.frame.size.height)].CGPath;
    
    MTDDirectionsSetLogLevel(MTDLogLevelInfo);
    MTDDirectionsSetActiveAPI(MTDDirectionsAPIGoogle);
    MTDDirectionsSetMeasurementSystem(MTDMeasurementSystemMetric);
}

- (void)setupMapControls {
    CGRect screenRect = [UIScreen mainScreen].bounds;
    
    mapTypeControl = [[UISegmentedControl alloc] initWithItems:[NSArray arrayWithObjects:@"Standard", @"Hybrid", @"Satellite", nil]];
    mapTypeControl.frame = CGRectMake(screenRect.size.width-265, screenRect.size.height - 165, 260, 44);
    [mapTypeControl addTarget:self action:@selector(mapTypeSwitch:) forControlEvents:UIControlEventValueChanged];
    [mapTypeControl setSelectedSegmentIndex:[[NSUserDefaults standardUserDefaults] integerForKey:@"mapType"]];
    [self mapTypeSwitch:mapTypeControl];
    [self.view insertSubview:mapTypeControl belowSubview:_mapView];
    
    directionsTypeControl = [[UISegmentedControl alloc] initWithItems:[NSArray arrayWithObjects:@"Driving", @"Walking", @"Bicycling", nil]];
    directionsTypeControl.frame = CGRectMake(screenRect.size.width-265, screenRect.size.height - 210, 260, 44);
    [directionsTypeControl addTarget:self action:@selector(directionsTypeSwitch:) forControlEvents:UIControlEventValueChanged];
    [directionsTypeControl setSelectedSegmentIndex:directionsType/2];
    [self.view insertSubview:directionsTypeControl belowSubview:_mapView];
    
    mapTypeLabel = [[UILabel alloc] initWithFrame:CGRectMake(135, directionsTypeControl.frame.origin.y - 25, mapTypeControl.frame.size.width, 21)];
    [mapTypeLabel setBackgroundColor:[UIColor clearColor]];
    [mapTypeLabel setText:@"Map/Directions Type"];
    [mapTypeLabel setTextColor:[UIColor colorWithRed:(115/255.f) green:(115/255.f) blue:(115/255.f) alpha:1.0f]];
    [mapTypeLabel setShadowColor:[UIColor whiteColor]];
    [mapTypeLabel setShadowOffset:CGSizeMake(0, 1)];
    [mapTypeLabel setFont:[UIFont boldSystemFontOfSize:18.0]];
    [self.view insertSubview:mapTypeLabel belowSubview:_mapView];
}

- (void)setupActionButtons {
    CGRect screenRect = [UIScreen mainScreen].bounds;
    clearMapButton = [[UIButton alloc] initWithFrame:CGRectMake(0, _mapView.frame.size.height + 5, 0, 45)];
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
    
    getDirButton = [[UIButton alloc] initWithFrame:CGRectMake(5, _mapView.frame.size.height + 5, screenRect.size.width-10, 45)];
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
    [_twoLineTitleView.titleLabel setText:@"Car Finder"];
    [_twoLineTitleView.subTitleLabel setText:@"Not tracking car's location"];
    showingDirections = NO;
    carFinderAnnotationView = nil;
    [_mapView removeAnnotations:_mapView.annotations];
    [_mapView removeDirectionsOverlay];
    [getDirButton setTitle:@"Directions" forState:UIControlStateNormal];
    [UIView animateWithDuration:0.3 animations:^{
        CGRect screenRect = [UIScreen mainScreen].bounds;
        clearMapButton.frame = CGRectMake(0, _mapView.frame.size.height + 5, 0, 45);
        getDirButton.frame = CGRectMake(5, _mapView.frame.size.height + 5, screenRect.size.width - 10, 45);
    }];
}

- (void)askForDirections {
    if (showingDirections) {
        UIAlertView *endNavAlert = [[UIAlertView alloc] initWithTitle:@"End Navigation"
                                                              message:@"Do you wish to end navigation?"
                                                             delegate:self
                                                    cancelButtonTitle:@"NO"
                                                    otherButtonTitles:@"YES", nil];
        endNavAlert.tag = End_Nav_Alert_Tag;
        [endNavAlert show];
    } else {
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

- (void)mapTypeSwitch:(id)sender {
    if (mapTypeControl.selectedSegmentIndex == 0) {
        _mapView.mapType = MKMapTypeStandard;
    } else if (mapTypeControl.selectedSegmentIndex == 1) {
        _mapView.mapType = MKMapTypeHybrid;
    } else if (mapTypeControl.selectedSegmentIndex == 2) {
        _mapView.mapType = MKMapTypeSatellite;
    }
    [[NSUserDefaults standardUserDefaults] setInteger:mapTypeControl.selectedSegmentIndex forKey:@"mapType"];
    [pageDragView uncurlPageAnimated:YES completion:nil];
}

- (void)directionsTypeSwitch:(id)sender {
    directionsType = directionsTypeControl.selectedSegmentIndex*2;
    [[NSUserDefaults standardUserDefaults] setInteger:directionsType forKey:@"directionsType"];
    [pageDragView uncurlPageAnimated:YES completion:nil];
}

#pragma mark - XBPageDragViewDelegate methods

- (void)pageDidCurl:(BOOL)pageCurled {
    if (pageCurled) {
        [userLocationButton setHidden:YES];
    } else {
        [userLocationButton setHidden:NO];
    }
}

#pragma mark - UIAlertViewDelegate methods

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (alertView.tag == Add_Pin_Alert_Tag) {
        if (buttonIndex == 1) {
            [_mapView removeAnnotations:_mapView.annotations];
            [_mapView addAnnotation:carFinderAnnotationView];
            [_twoLineTitleView.subTitleLabel setText:@"Car Location Tracked"];
            [UIView animateWithDuration:0.3 animations:^{
                CGRect screenRect = [UIScreen mainScreen].bounds;
                clearMapButton.frame = CGRectMake(5, _mapView.frame.size.height + 5, (screenRect.size.width/2)-8, 45);
                getDirButton.frame = CGRectMake(clearMapButton.frame.origin.x + clearMapButton.frame.size.width + 5, _mapView.frame.size.height + 5, (screenRect.size.width/2)-7, 45);
            }];
        } else {
            carFinderAnnotationView = nil;
        }
    } else if (alertView.tag == Get_Dir_Alert_Tag) {
        if (buttonIndex == 1) {
            [_mapView loadDirectionsFrom:_mapView.userLocation.coordinate
                                      to:carFinderAnnotationView.coordinate
                               routeType:directionsType
                    zoomToShowDirections:YES];
            showingDirections = YES;
            [getDirButton setTitle:@"End Navigation" forState:UIControlStateNormal];
            hudView = [AlertHUDView showHUDWithMessage:@"Loading..." inViewController:self];
            
        }
    } else if (alertView.tag == End_Nav_Alert_Tag) {
        if (buttonIndex == 1) {
            [_mapView removeDirectionsOverlay];
            showingDirections = NO;
            [_twoLineTitleView.titleLabel setText:@"Car Finder"];
            [_twoLineTitleView.subTitleLabel setText:@"Car Location Tracked"];
            [getDirButton setTitle:@"Directions" forState:UIControlStateNormal];
            [self centerAtCurrentLocation];
        }
    }
}

#pragma mark - MTDMapViewDelegate methods

- (void)mapView:(MTDMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation distanceToActiveRoute:(CGFloat)distanceToActiveRoute {
    [self centerAtCurrentLocation];
    [_twoLineTitleView.subTitleLabel setText:[NSString stringWithFormat:@"%@ mi", [formatter stringFromNumber:[NSNumber numberWithDouble:distanceToActiveRoute]]]];
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


- (MTDDirectionsOverlay *)mapView:(MTDMapView *)mapView didFinishLoadingDirectionsOverlay:(MTDDirectionsOverlay *)directionsOverlay {
    [hudView dismiss];
    [_twoLineTitleView.titleLabel setText:directionsOverlay.activeRoute.name];
    [_twoLineTitleView.subTitleLabel setText:[NSString stringWithFormat:@"%@ mi - %@", [formatter stringFromNumber:[NSNumber numberWithDouble:directionsOverlay.activeRoute.distance.distanceInCurrentMeasurementSystem]], [self getTravelTimeFromDirections:directionsOverlay.activeRoute.timeInSeconds]]];
    return directionsOverlay;
}

- (void)mapView:(MTDMapView *)mapView didActivateRoute:(MTDRoute *)route ofDirectionsOverlay:(MTDDirectionsOverlay *)directionsOverlay {
    [_twoLineTitleView.titleLabel setText:route.name];
    [_twoLineTitleView.subTitleLabel setText:[NSString stringWithFormat:@"%@ mi - %@", [formatter stringFromNumber:[NSNumber numberWithDouble:route.distance.distanceInCurrentMeasurementSystem]], [self getTravelTimeFromDirections:directionsOverlay.timeInSeconds]]];
}

- (void)mapView:(MTDMapView *)mapView didFailLoadingDirectionsOverlayWithError:(NSError *)error {
    [hudView dismiss];
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error Occurred"
                                                    message:@"Unable to load directions at this time. Please try again later."
                                                   delegate:nil
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    [alert show];
}

#pragma mark - Utility methods 

- (NSString*)getTravelTimeFromDirections:(double)totalSeconds {
    int hours = totalSeconds / (60 * 60);
    int minutes = (int)(totalSeconds / 60) % 60;
    
    if ( hours > 0 ) {
        return [NSString stringWithFormat:@"%d hrs, %02d min", hours, minutes];
    } else {
        return [NSString stringWithFormat:@"%d min", minutes];
    }
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
