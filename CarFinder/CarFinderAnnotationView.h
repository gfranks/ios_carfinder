//
//  CarFinderAnnotationView.h
//  CarFinder
//
//  Created by Garrett Franks on 5/9/13.
//  Copyright (c) 2013 Garrett Franks. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

@interface CarFinderAnnotationView : NSObject<MKAnnotation> {
    CLLocationCoordinate2D coordinate;
}

@property (nonatomic, readonly) CLLocationCoordinate2D coordinate;
@property (nonatomic, readonly) NSString *title;

// add an init method so you can set the coordinate property on startup
- (id) initWithCoordinate:(CLLocationCoordinate2D)coord;

@end