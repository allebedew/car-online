//
//  ALTelemetryModel.m
//  Car Online
//
//  Created by Lebedev Aleksey on 8/1/15.
//
//

#import "ALTelemetryModel.h"
#import "Convertions.h"

@implementation ALTelemetryModel

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
    return @{
        @"averageSpeed": @"averageSpeed",
        @"engineTime": @"engineTime",
        @"maxSpeed": @"maxSpeed",
        @"mileage": @"mileage",
        @"standsCount": @"standsCount",
        @"waysCount": @"waysCount"
    };
}

- (NSString*)mileageString {
    return [NSString stringWithFormat:@"%.1f", self.mileage.floatValue / 1000];
}

- (NSString*)averageSpeedString {
    return [NSString stringWithFormat:@"%.0f", self.averageSpeed.floatValue];
}

- (NSString*)engineTimeString {
    return [@(self.engineTime.floatValue * MS_TO_S / 60) timeStringFromMinutes];
}

- (NSString*)maxSpeedString {
    return [NSString stringWithFormat:@"%.0f", self.maxSpeed.floatValue];
}

@end
