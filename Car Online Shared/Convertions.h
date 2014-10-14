//
//  NSDate+Covertions.h
//  Car Online
//
//  Created by Alex Lebedev on 19-03-12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

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