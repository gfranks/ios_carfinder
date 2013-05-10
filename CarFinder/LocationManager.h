//
//  LocationManager.h
//  CarFinder
//
//  Created by Garrett Franks on 5/9/13.
//  Copyright (c) 2013 Garrett Franks. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#define kDisabledLocServices -1
#define kPurposeOfLocationServices @"We need to use your location for Search Nearby features."
#define kThirtyMinutes 30*60 //in seconds
#define kThreeKilometers 3000.00

typedef enum {
    LocationServicesStatusDisabled,
    LocationServicesStatusAuthorized,
    LocationServicesStatusRestricted,
    LocationServicesStatusDenied,
    LocationServicesStatusNotDetermined
} LocationServicesStatus;

@interface LocationManager : NSObject <CLLocationManagerDelegate>

@property (nonatomic, strong) CLLocationManager* locationManager;
@property (strong, nonatomic) NSTimer* locationTimer;
@property (strong, nonatomic) CLLocation* currentLocation;
@property (strong, nonatomic) NSNumber* stillDeterminingLocation;

+ (LocationManager *)sharedInstance;
- (void)startListeningForLocation;
- (int)getLocationServicesStatus;
- (void)stopListeningForLocation;
@end
