//
//  CarFinderAnnotationView.m
//  CarFinder
//
//  Created by Garrett Franks on 5/9/13.
//  Copyright (c) 2013 Garrett Franks. All rights reserved.
//

#import "CarFinderAnnotationView.h"

@implementation CarFinderAnnotationView

@synthesize coordinate, title;

- (id)initWithCoordinate:(CLLocationCoordinate2D)coord {
    if (self = [super init]) {
        coordinate = coord;
        title = @"Your Car's Location";
    }
    return self;
}

@end
