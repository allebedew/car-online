//
//  ALCarInfo.h
//  Car Online
//
//  Created by Alex on 1/31/14.
//
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import <MapKit/MKAnnotation.h>
#import <MapKit/MKOverlay.h>

extern NSString* const ALCarInfoErrorDomain;

@interface ALCarInfo : NSObject

- (id)initWithServerData:(NSData*)data;

@property (nonatomic, strong) NSError *error;

@end

// ==============================================

@interface ALCarParkingInfo : NSObject <MKAnnotation>

@property (nonatomic, readonly) CLLocation *location;
@property (nonatomic, readonly) NSDate *beginTime;
@property (nonatomic, readonly) NSDate *endTime;
@property (nonatomic, readonly) NSTimeInterval duration;

@end

@interface ALCarLocation : ALCarInfo

@property (nonatomic, readonly) CLLocation *lastLocation;
@property (nonatomic, readonly) CLLocationCoordinate2D *coordinates;
@property (nonatomic, readonly) NSUInteger coordinatesCount;
@property (nonatomic, readonly) NSArray *parkings;

@end

// ==============================================

@interface ALCarTelemetry : ALCarInfo

@property (nonatomic, readonly) NSString *averengeSpeedString;
@property (nonatomic, readonly) NSString *engineTimeString;
@property (nonatomic, readonly) NSString *maxSpeedString;
@property (nonatomic, readonly) NSString *mileageString;
@property (nonatomic, readonly) NSUInteger standsCount;
@property (nonatomic, readonly) NSUInteger waysCount;

@end

// ==============================================

@interface ALCarEventGroup : NSObject

@property (nonatomic, readonly) NSUInteger count;
@property (nonatomic, readonly) NSDate *lastEventTime;
@property (nonatomic, readonly) NSString *title;
@property (nonatomic, readonly) BOOL iconAvailable;
@property (nonatomic, readonly) UIImage *icon;

@end

@interface ALCarEvents : ALCarInfo

@property (nonatomic, readonly) NSArray *events;

@end
