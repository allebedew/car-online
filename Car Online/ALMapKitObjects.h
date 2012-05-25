//
//  ALMapKitObjects.h
//  Car Online
//
//  Created by Алексей Лебедев on 25-05-12.
//  Copyright (c) 2012 Shakuro. All rights reserved
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

@interface ALAnnotation : NSObject <MKAnnotation>

@property (nonatomic, copy) NSDictionary *gpsPoint;
@property (nonatomic, assign) CLLocationCoordinate2D coordinate;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *subtitle;

@end

@interface NSArray (MapKit) <MKOverlay>

@end

