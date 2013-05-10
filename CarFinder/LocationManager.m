//
//  LocationManager.m
//  CarFinder
//
//  Created by Garrett Franks on 5/9/13.
//  Copyright (c) 2013 Garrett Franks. All rights reserved.
//

#import "LocationManager.h"

@implementation LocationManager

- (void)startListeningForLocation {
    
    /*
     A 30 second timer that will allow location updates to run continuously until timer
     expires, then location updates will be turned off to safe battery power.
    */
    if ([self.locationTimer isValid]) {
        NSLog(@"LocationManager: startListeningForLocation: A timer is currently counting down, ignored");
        // Do nothing until current timer expires
    } else {
        NSLog(@"LocationManager: startListeningForLocation: Creating a new timer");
        self.locationTimer = [NSTimer scheduledTimerWithTimeInterval:30.0
                                                              target:self
                                                            selector:@selector(stopListeningForLocation)
                                                            userInfo:nil
                                                             repeats:NO];

        // Start listening for location
        if (!self.locationManager) {
            self.locationManager = [[CLLocationManager alloc] init];
        }

        self.locationManager.distanceFilter  = kCLDistanceFilterNone;
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
        
        @synchronized(self.locationManager){
            self.locationManager.delegate    = self;
            [self.locationManager startUpdatingLocation];
        }
        
        self.stillDeterminingLocation = [NSNumber numberWithBool:YES];
    }
}

- (int)getLocationServicesStatus {
    LocationServicesStatus retVal;
    
    // Check to see if location services are enabled
    if([CLLocationManager locationServicesEnabled]){
        NSLog(@"Location Services Enabled");
        
        // Switch through the possible location
        // authorization states
        switch([CLLocationManager authorizationStatus]){
            case kCLAuthorizationStatusAuthorized:
                NSLog(@"We have access to location services");
                retVal = LocationServicesStatusAuthorized;
                break;
                
            case kCLAuthorizationStatusDenied:
                NSLog(@"Location services denied by user");
                retVal = LocationServicesStatusDenied;
                break;
                
            case kCLAuthorizationStatusRestricted:
                NSLog(@"Parental controls restrict location services");
                retVal = LocationServicesStatusRestricted;
                break;
                
            case kCLAuthorizationStatusNotDetermined:
                NSLog(@"Unable to determine, possibly not available");
                retVal = LocationServicesStatusNotDetermined;
                break;
                
            default:
                retVal = LocationServicesStatusNotDetermined;
                break;
        }
    }
    else {
        // locationServicesEnabled was set to NO
        NSLog(@"Location Services Are Disabled");
        
        retVal = LocationServicesStatusDisabled;
    }
    
    return retVal;
}

- (void)stopListeningForLocation {
    @synchronized(self.locationManager){
        [self.locationManager stopUpdatingLocation];
        [self.locationManager setDelegate:nil];
    }
    [self.locationTimer invalidate];
}

# pragma mark - CLLocationManagerDelegate Methods

- (void)locationManager:(CLLocationManager *)manager 
    didUpdateToLocation:(CLLocation *)newLocation 
           fromLocation:(CLLocation *)oldLocation {
    
    // Ensure we get a recent and accurate location
    NSDate * locationTimestamp = [newLocation timestamp];
    NSTimeInterval timeDifference = [locationTimestamp timeIntervalSinceNow];
    double thirtyMins = (kThirtyMinutes * -1);
    BOOL locationTimestampIsCurrent = (timeDifference > thirtyMins);
    BOOL isAccurateLocation = (newLocation.horizontalAccuracy <= kThreeKilometers);
    
    // Used for debugging, do not remove
    NSLog(@" ");
    NSLog(@"LocationManager Received New Location START ***********************************************");
    NSLog(@"LocationManager locationTimestamp: %@", locationTimestamp);
    NSLog(@"LocationManager timeDifference: %f", timeDifference);
    NSLog(@"LocationManager newLocation.horizontalAccuracy: %f", newLocation.horizontalAccuracy);
    NSLog(@"LocationManager isAccurateLocaton: %@", (isAccurateLocation) ? @"YES" : @"NO");
    NSLog(@"LocationManager locationTimestampIsCurrent: %@", (locationTimestampIsCurrent) ? @"YES" : @"NO");
    NSLog(@"LocationManager Received New Location END **************************************************");
    NSLog(@" ");
    
    if (locationTimestampIsCurrent && isAccurateLocation) {
        if (self.currentLocation != nil) {
            if (self.currentLocation.coordinate.latitude != newLocation.coordinate.latitude ||
                self.currentLocation.coordinate.longitude != newLocation.coordinate.longitude) {
                self.currentLocation = newLocation;
            }
        } else {
            self.currentLocation = newLocation;
            [[NSNotificationCenter defaultCenter] postNotificationName:@"locationAcquired" object:self.currentLocation];
        }
        
        NSLog(@"Shutting down location services, we have a good location.");
        self.stillDeterminingLocation = [NSNumber numberWithBool:NO];
        [self stopListeningForLocation];
        
    } else {
        // Do nothing, let this method be called again with a new "newLocation" to check its validity.
    }
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    
    NSString * errorMessage = [NSString stringWithFormat:@"LocationManger: locationManager:didFailWithError: ERROR: %@", [error localizedDescription]];
    NSLog(@"%@", errorMessage);
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"locationError" object:nil];
}

# pragma mark - LocationManager singleton methods

+ (LocationManager*)sharedInstance {
    static LocationManager *instance = NULL;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    
    return(instance);
}

@end
