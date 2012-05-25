//
//  ALMapKitObjects.m
//  Car Online
//
//  Created by Алексей Лебедев on 25-05-12.
//  Copyright (c) 2012 Shakuro. All rights reserved.
//

#import "ALMapKitObjects.h"

@implementation ALAnnotation

@synthesize coordinate, title, subtitle, gpsPoint;

@end

@implementation NSArray (MapKit)

- (CLLocationCoordinate2D)coordinate {
    return CLLocationCoordinate2DMake(0, 0);
}

- (MKMapRect)boundingMapRect {
    return MKMapRectMake(0, 0, 1000, 1000);
}

- (BOOL)intersectsMapRect:(MKMapRect)mapRect {
    return YES;
}

@end
