//
//  ALCarLocationAnnotation.m
//  Car Online
//
//  Created by Alex on 10/14/14.
//
//

#import "ALCarLocationAnnotation.h"
#import "ALPointModel.h"
#import "Convertions.h"

@interface ALCarLocationAnnotation ()

@property (nonatomic, strong, readwrite) ALParkingModel *parking;

@end

@implementation ALCarLocationAnnotation

- (instancetype)initWithParking:(ALParkingModel*)parking {
    self = [super init];
    if (self) {
        NSParameterAssert(parking);
        _parking = parking;
    }
    return self;
}

- (BOOL)isLastLocation {
    return self.parking.isLastLocation;
}

- (void)setUserLocation:(CLLocation *)userLocation {
    _userLocation = [userLocation copy];
    [self update];
}

- (void)update {
    [self willChangeValueForKey:@"subtitle"];
    [self didChangeValueForKey:@"subtitle"];
}

#pragma mark MKAnnotation Protocol

- (CLLocationCoordinate2D)coordinate {
    return self.parking.coord;
}

- (NSString*)title {
    return self.isLastLocation ? @"Last Location" : @"Parking";
}

- (NSString*)subtitle {
    NSString *beginString = [self.parking.beginTime formattedTimeString];
    
    NSDate *endTime = self.isLastLocation ? [NSDate date] : self.parking.endTime;
    NSTimeInterval duration = [endTime timeIntervalSinceDate:self.parking.beginTime];
    NSString *durationString = [@(duration) timeStringFromSeconds];
    
    if (self.isLastLocation) {
        if (self.userLocation) {
            CLLocation *parkingLocation = [[CLLocation alloc] initWithLatitude:self.parking.coord.latitude
                                                                     longitude:self.parking.coord.longitude];
            CLLocationDistance distance = [self.userLocation distanceFromLocation:parkingLocation];
            NSString *distanceString = [NSString stringWithFormat:@"%.0fm from me", distance];
            
            return [NSString stringWithFormat:@"%@ (%@) - %@", beginString, durationString, distanceString];
        } else {
            return [NSString stringWithFormat:@"%@ (%@)", beginString, durationString];
        }
    } else {
        NSString *endString = [self.parking.endTime formattedTimeString];
        
        return [NSString stringWithFormat:@"%@ - %@ (%@)", beginString, endString, durationString];
    }
}

@end