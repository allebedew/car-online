//
//  ALTelemetryModel.h
//  Car Online
//
//  Created by Lebedev Aleksey on 8/1/15.
//
//

#import "Mantle.h"

@interface ALTelemetryModel : MTLModel <MTLJSONSerializing>

@property (nonatomic, copy, readwrite) NSNumber *averageSpeed;
@property (nonatomic, copy, readwrite) NSNumber *engineTime;
@property (nonatomic, copy, readwrite) NSNumber *maxSpeed;
@property (nonatomic, copy, readwrite) NSNumber *mileage;
@property (nonatomic, copy, readwrite) NSNumber *standsCount;
@property (nonatomic, copy, readwrite) NSNumber *waysCount;

@property (nonatomic, readonly) NSString *mileageString;
@property (nonatomic, readonly) NSString *averageSpeedString;
@property (nonatomic, readonly) NSString *engineTimeString;
@property (nonatomic, readonly) NSString *maxSpeedString;

@end
