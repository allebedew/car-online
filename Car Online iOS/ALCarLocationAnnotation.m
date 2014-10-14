//
//  ALCarLocationAnnotation.m
//  Car Online
//
//  Created by Alex on 10/14/14.
//
//

#import "ALCarLocationAnnotation.h"
#import "ALCarInfo.h"
#import "Convertions.h"

@interface ALCarLocationAnnotation ()

@property (nonatomic, strong, readwrite) ALCarLocationPoint *point;

@end

@implementation ALCarLocationAnnotation

- (instancetype)initWithCarLocationPoint:(ALCarLocationPoint*)point {
    self = [super init];
    if (self) {
        NSParameterAssert(point);
        _point = point;
    }
    return self;
}

- (BOOL)isLastLocation {
    return self.point.isLastLocation;
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
    return self.point.location.coordinate;
}

- (NSString*)title {
    return self.isLastLocation ? @"Last Location" : @"Parking";
}

- (NSString*)subtitle {
    NSString *beginString = [self.point.beginTime formattedTimeString];
    
    NSDate *endTime = self.isLastLocation ? [NSDate date] : self.point.endTime;
    NSTimeInterval duration = [endTime timeIntervalSinceDate:self.point.beginTime];
    NSString *durationString = [@(duration) timeStringFromSeconds];
    
    if (self.isLastLocation) {
        if (self.userLocation) {
            CLLocationDistance distance = [self.userLocation distanceFromLocation:self.point.location];
            NSString *distanceString = [NSString stringWithFormat:@"%.0fm from me", distance];
            
            return [NSString stringWithFormat:@"%@ (%@) - %@", beginString, durationString, distanceString];
        } else {
            return [NSString stringWithFormat:@"%@ (%@)", beginString, durationString];
        }
    } else {
        NSString *endString = [self.point.endTime formattedTimeString];
        
        return [NSString stringWithFormat:@"%@ - %@ (%@)", beginString, endString, durationString];
    }
}

@end