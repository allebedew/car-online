//
//  ALPointModel.h
//  Car Online
//
//  Created by Lebedev Aleksey on 9/1/15.
//
//

#import "Mantle.h"
#import <CoreLocation/CoreLocation.h>

@interface ALPointModel : MTLModel <MTLJSONSerializing>

@property (nonatomic, copy) NSNumber *speed;
@property (nonatomic, copy) NSDate *time;
@property (nonatomic, copy) NSNumber *lat;
@property (nonatomic, copy) NSNumber *lon;
@property (nonatomic) CLLocationCoordinate2D coord;

+ (NSArray*)filteredPointsFromPoints:(NSArray*)points;
+ (NSArray*)parkingsFromPoints:(NSArray*)points;

@end

@interface ALParkingModel : NSObject

@property (nonatomic) CLLocationCoordinate2D coord;
@property (nonatomic, copy) NSDate *beginTime;
@property (nonatomic, copy) NSDate *endTime;
@property (nonatomic, readonly) NSTimeInterval duration;
@property (nonatomic, readonly) BOOL isLastLocation;

@end

