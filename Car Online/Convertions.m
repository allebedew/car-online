//
//  NSDate+Covertions.m
//  Car Online
//
//  Created by Alex Lebedev on 19-03-12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "Convertions.h"

@implementation NSDate (Convertions)

+ (NSDate*)startOfTheDayDate {
  NSCalendar *cal = [NSCalendar calendarWithIdentifier:NSCalendarIdentifierGregorian];
  return [cal dateBySettingHour:0 minute:0 second:0 ofDate:[self date] options:0];
}

- (NSString*)agoFromNow {
    NSInteger secs = fabs([self timeIntervalSinceNow]);
    if (secs > 60*60*24) {
        return [NSString stringWithFormat:@"%d days ago", secs / (60*60*24)];
    } else if (secs > 60*60) {
        return [NSString stringWithFormat:@"%d hours ago", secs / (60*60)];
    } else if (secs > 60) {
        return [NSString stringWithFormat:@"%d minutes ago", secs / 60];
    }
    return [NSString stringWithFormat:@"%d seconds ago", secs];
}

- (NSString*)formattedString {
    static NSDateFormatter *formatter = nil;
    if (!formatter) {
        formatter = [[NSDateFormatter alloc] init];
        [formatter setDateStyle:NSDateFormatterShortStyle];
        [formatter setTimeStyle:NSDateFormatterMediumStyle];
    }
    return [formatter stringFromDate:self];
}

@end

@implementation NSNumber (Convertions)

- (NSString*)timeStringFromMinutes {
    NSInteger mins = self.integerValue;
    NSInteger hours = mins / 60;
    mins -= hours * 60;
    return [NSString stringWithFormat:@"%d:%.2d", hours, mins];
}

@end