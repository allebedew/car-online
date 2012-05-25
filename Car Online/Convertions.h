//
//  NSDate+Covertions.h
//  Car Online
//
//  Created by Alex Lebedev on 19-03-12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSDate (Convertions)

- (NSString*)agoFromNow;
- (NSString*)formattedString;

@end

@interface NSNumber (Convertions)

- (NSString*)timeStringFromMinutes;

@end
