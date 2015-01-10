//
//  NSDate+Covertions.h
//  Car Online
//
//  Created by Alex Lebedev on 19-03-12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

#define KMPH_TO_MPH 0.277777777777778
#define MS_TO_S 0.001

#define SERVER_TIME_ZONE 4
#define MIN_PARKING_DURATION 300

@interface NSDate (Convertions)

+ (NSDate*)startOfTheDayDate;

- (NSString*)agoFromNow;
- (NSString*)formattedString;
- (NSString*)formattedTimeString;

@end

@interface NSNumber (Convertions)

- (NSString*)timeStringFromMinutes;
- (NSString*)timeStringFromSeconds;

@end