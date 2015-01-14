//
//  ALPointModel.m
//  Car Online
//
//  Created by Lebedev Aleksey on 9/1/15.
//
//

#import "ALPointModel.h"

@implementation ALPointModel

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
    return @{
        @"speed": @"speed",
        @"time": @"gpsTime",
        @"lat": @"latitude",
        @"lon": @"longitude"
    };
}

+ (NSValueTransformer*)timeJSONTransformer {
    return [MTLValueTransformer transformerWithBlock:^id(NSNumber *value) {
        return [NSDate dateWithTimeIntervalSince1970:value.doubleValue * 0.001];
    }];
}

- (instancetype)initWithDictionary:(NSDictionary *)dictionary error:(NSError **)error {
    self = [super initWithDictionary:dictionary error:error];
    if (self) {
        self.coord = CLLocationCoordinate2DMake(self.lat.doubleValue, self.lon.doubleValue);
    }
    return self;
}

+ (NSArray*)filteredPointsFromPoints:(NSArray*)points {
    NSMutableArray *filteredPoints = [NSMutableArray array];
    [points enumerateObjectsUsingBlock:^(ALPointModel *point, NSUInteger idx, BOOL *stop) {
        ALPointModel *previous = (idx > 0) ? points[idx - 1] : nil;
        if (point.lat.doubleValue == previous.lat.doubleValue &&
            point.lon.doubleValue == previous.lon.doubleValue) {
            return;
        }
        [filteredPoints addObject:point];
    }];
    return [filteredPoints copy];
}

+ (NSArray*)parkingsFromPoints:(NSArray*)points {

    static const NSTimeInterval kMinParkingTime = 300;

    NSMutableArray *parkings = [NSMutableArray array];

    if (points.firstObject) {
        ALPointModel *point = points.firstObject;
        ALParkingModel *parking = [ALParkingModel new];
        parking.coord = point.coord;
        parking.beginTime = point.time;
        [parkings addObject:parking];
    }

    __block NSDate *parkingEndTime = nil;
    [points enumerateObjectsUsingBlock:^(ALPointModel *point, NSUInteger idx, BOOL *stop) {

        if (parkingEndTime) {
            // last point or next point is moving
            BOOL isLast = (idx == points.count - 1);
            if (isLast || ((ALPointModel*)points[idx + 1]).speed.doubleValue > 0) {

                ALParkingModel *parking = [ALParkingModel new];
                parking.coord = point.coord;
                parking.beginTime = point.time;
                parking.endTime = parkingEndTime;

                if (parking.duration >= kMinParkingTime || isLast) {
                    [parkings addObject:parking];
                }
                parkingEndTime = nil;
            }

        } else {
            if (point.speed.doubleValue == 0) {
                parkingEndTime = point.time;
            }
        }

    }];

    return [parkings copy];
}

@end

@implementation ALParkingModel

- (BOOL)isLastLocation {
    return self.endTime == nil;
}

- (NSTimeInterval)duration {
    return [self.endTime timeIntervalSinceDate:self.beginTime];
}

@end
