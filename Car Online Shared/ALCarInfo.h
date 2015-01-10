//
//  ALCarInfo.h
//  Car Online
//
//  Created by Alex on 1/31/14.
//
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import <MapKit/MKAnnotation.h>
#import <MapKit/MKOverlay.h>

extern NSString* const ALCarInfoErrorDomain;

@interface ALCarInfo : NSObject

- (id)initWithServerData:(NSData*)data;

@property (nonatomic, strong) NSError *error;

@end

// ==============================================

@interface ALCarEventGroup : NSObject

@property (nonatomic, readonly) NSUInteger count;
@property (nonatomic, readonly) NSDate *lastEventTime;
@property (nonatomic, readonly) NSString *title;
@property (nonatomic, readonly) BOOL iconAvailable;
@property (nonatomic, readonly) UIImage *icon;

@end

@interface ALCarEvents : ALCarInfo

@property (nonatomic, readonly) NSArray *events;

@end
