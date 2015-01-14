//
//  ALRequestFactory.h
//  Car Online
//
//  Created by Lebedev Aleksey on 8/1/15.
//
//

#import <Foundation/Foundation.h>

@interface ALRequestFactory : NSObject

+ (NSURLRequest*)requestForTelemetry;
+ (NSURLRequest*)requestForGPSList;

@end
