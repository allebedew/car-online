//
//  ALCarLocationAnnotation.h
//  Car Online
//
//  Created by Alex on 10/14/14.
//
//

#import <Foundation/Foundation.h>
#import <MapKit/MKAnnotation.h>

@class ALCarLocationPoint;

@interface ALCarLocationAnnotation : NSObject <MKAnnotation>

@property (nonatomic, copy) CLLocation *userLocation;
@property (nonatomic, readonly) BOOL isLastLocation;

- (instancetype)initWithCarLocationPoint:(ALCarLocationPoint*)point;
- (void)update;

@end
