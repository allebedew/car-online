//
//  ALCarInfo.m
//  Car Online
//
//  Created by Alex on 1/31/14.
//
//

#import "ALCarInfo.h"
#import "GDataXMLNode.h"
#import "Convertions.h"

#import <MapKit/MapKit.h>

#define KMPH_TO_MPH 0.277777777777778
#define MS_TO_S 0.001

#define SERVER_TIME_ZONE 4
#define MIN_PARKING_DURATION 300

NSString* const ALCarInfoErrorDomain = @"com.alexlebedev.carinfo";

@interface ALCarInfo ()

@property (nonatomic, strong) GDataXMLDocument *xml;

@end

@implementation ALCarInfo

- (id)initWithServerData:(NSData*)data {
    self = [super init];
    if (self) {
        [self createXMLDocumentWithData:data];
        if (!self.error) {
            [self checkForError];
            if (!self.error) {
                [self parseXMLDocument];
            }
        }
    }
    return self;
}

- (void)createXMLDocumentWithData:(NSData*)data {
    NSError *error = nil;
    self.xml = [[GDataXMLDocument alloc] initWithData:data options:0 error:&error];
    if (error) {
        self.error = error;
    }
}

- (void)checkForError {
    if ([self.xml.rootElement.name isEqualToString:@"error"]) {
        NSString *errorString = self.xml.rootElement.stringValue;
        NSString *description = [NSString stringWithFormat:@"%@", errorString];
        NSDictionary *userInfo = @{NSLocalizedDescriptionKey:description};
        NSError *error = [NSError errorWithDomain:ALCarInfoErrorDomain code:-1 userInfo:userInfo];
        self.error = error;
    }
}

- (void)parseXMLDocument {
    NSAssert(NO, @"Should be implemented by subclass");
}

@end

#pragma mark -

@interface ALCarLocationPoint ()

@property (nonatomic, strong, readwrite) CLLocation *location;
@property (nonatomic, strong, readwrite) NSDate *startTime;
@property (nonatomic, strong, readwrite) NSDate *endTime;
@property (nonatomic, assign, readwrite) NSTimeInterval duration;

@end

@implementation ALCarLocationPoint

- (id)initWithLocation:(CLLocation*)location begin:(NSDate*)begin end:(NSDate*)end lastLocation:(BOOL)lastLocation {
    self = [super init];
    if (self) {
        _isLastLocation = lastLocation;
        _location = location;
        _beginTime = begin;
        _endTime = end;
        if (_beginTime != nil && _endTime != nil) {
            _duration = [end timeIntervalSinceDate:begin];
        }
    }
    return self;
}

- (NSString*)description {
    return [NSString stringWithFormat:@"%@ (location=%@ begin=%@ end=%@ duration=%f",
            [super description], self.location, self.beginTime, self.endTime, self.duration];
}

@end

@interface ALCarLocation ()

@property (nonatomic, assign, readwrite) CLLocationCoordinate2D *coordinates;
@property (nonatomic, assign, readwrite) NSUInteger coordinatesCount;
@property (nonatomic, strong, readwrite) ALCarLocationPoint *lastLocation;
@property (nonatomic, strong, readwrite) NSArray *parkings;

@end

@implementation ALCarLocation

- (void)dealloc {
    free(self.coordinates);
}

- (NSString*)description {
    return [NSString stringWithFormat:@"%@ (lastLocation=%@ coordinatesCount=%d parkings=%@",
            [super description], self.lastLocation, self.coordinatesCount, self.parkings];
}

- (void)parseXMLDocument {
    GDataXMLElement *rootElement = self.xml.rootElement;
    
    if (![rootElement.name  isEqualToString:@"gpslist"]) {
        self.error = [NSError errorWithDomain:ALCarInfoErrorDomain code:-3 userInfo:nil];
        return;
    }
    
    NSUInteger nodesCount = rootElement.childCount;
    if (nodesCount == 0) {
        return;
    }

    // Parsing last location
    
    GDataXMLElement *firstNode = rootElement.children.firstObject;
    if (firstNode) {
        CLLocation *location = [[self class] parseLocationFromXMLElement:firstNode];
        self.lastLocation = [[ALCarLocationPoint alloc] initWithLocation:location begin:location.timestamp end:nil lastLocation:YES];
    }
  
    NSDate *parkingEndTime = nil;
    NSMutableArray *parkings = [NSMutableArray array];
    CLLocationCoordinate2D* coords = malloc(nodesCount * sizeof(CLLocationCoordinate2D));
    for (int i = 0; i < nodesCount; i++) {
    
        // Processing coordinates
        
        GDataXMLElement *node = rootElement.children[i];
        CLLocationDegrees latitude = [[[node attributeForName:@"latitude"] stringValue] doubleValue];
        CLLocationDegrees longitude = [[[node attributeForName:@"longitude"] stringValue] doubleValue];
        coords[i] = CLLocationCoordinate2DMake(latitude, longitude);
      
        // Processing parkings
        
        CLLocationSpeed speed = [[[node attributeForName:@"speed"] stringValue] doubleValue];
        if (!parkingEndTime) {
            if (speed == 0) {
                parkingEndTime = [[self class] parseDateFormTimestampXMLNode:[node attributeForName:@"gpsTime"]];
            }
        } else {
            BOOL isLastPoint = (i == nodesCount - 1);
            if (isLastPoint ||
                ([[[rootElement.children[i+1] attributeForName:@"speed"] stringValue] doubleValue] > 0)) { // next point is moving
                
                CLLocation *location = [[self class] parseLocationFromXMLElement:node];
                ALCarLocationPoint *parking = [[ALCarLocationPoint alloc] initWithLocation:location begin:location.timestamp end:parkingEndTime lastLocation:NO];
                parkingEndTime = nil;
                if (parking.duration >= MIN_PARKING_DURATION || isLastPoint) {
                    [parkings addObject:parking];
                }
            }
        }
    }
    self.coordinates = coords;
    self.coordinatesCount = nodesCount;
    self.parkings = [parkings copy];
}

+ (CLLocation*)parseLocationFromXMLElement:(GDataXMLElement*)element {
    CLLocationDegrees latitude = [[[element attributeForName:@"latitude"] stringValue] doubleValue];
    CLLocationDegrees longitude = [[[element attributeForName:@"longitude"] stringValue] doubleValue];
    CLLocationDirection course = [[[element attributeForName:@"course"] stringValue] doubleValue];
    CLLocationSpeed speed = [[[element attributeForName:@"speed"] stringValue] doubleValue] * KMPH_TO_MPH;
    NSDate *timestamp = [[self class] parseDateFormTimestampXMLNode:[element attributeForName:@"gpsTime"]];
    CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake(latitude, longitude);
  
    return [[CLLocation alloc] initWithCoordinate:coordinate
                                       altitude:0
                             horizontalAccuracy:0
                               verticalAccuracy:0
                                         course:course
                                          speed:speed
                                      timestamp:timestamp];
}
                                             
+ (NSDate*)parseDateFormTimestampXMLNode:(GDataXMLNode*)element {
    double gpsTime = [[element stringValue] doubleValue];
    return [NSDate dateWithTimeIntervalSince1970:gpsTime * MS_TO_S];
}

@end

#pragma mark -

@interface ALCarTelemetry ()

@property (nonatomic, strong, readwrite) NSString *averengeSpeedString;
@property (nonatomic, strong, readwrite) NSString *engineTimeString;
@property (nonatomic, strong, readwrite) NSString *maxSpeedString;
@property (nonatomic, strong, readwrite) NSString *mileageString;
@property (nonatomic, assign, readwrite) NSUInteger standsCount;
@property (nonatomic, assign, readwrite) NSUInteger waysCount;

@end

@implementation ALCarTelemetry

- (NSString*)description {
    return [NSString stringWithFormat:@"%@ (averengeSpeed=%@, engineTime=%@, maxSpeed=%@, mileage=%@, standsCount=%d, waysCount=%d)",
            [super description], self.averengeSpeedString, self.engineTimeString, self.maxSpeedString,
            self.mileageString, self.standsCount, self.waysCount];
}

- (void)parseXMLDocument {
    GDataXMLElement *rootElement = self.xml.rootElement;
    
    if (![rootElement.name  isEqualToString:@"telemetry"]) {
        self.error = [NSError errorWithDomain:ALCarInfoErrorDomain code:-3 userInfo:nil];
        return;
    }
    
    double averengeSpeed = [[[rootElement attributeForName:@"averageSpeed"] stringValue] doubleValue];
    self.averengeSpeedString = [NSString stringWithFormat:@"%.0f km/h", averengeSpeed];
    double maxSpeed = [[[rootElement attributeForName:@"maxSpeed"] stringValue] doubleValue];
    self.maxSpeedString = [NSString stringWithFormat:@"%.0f km/h", maxSpeed];
    double engineTime = [[[rootElement attributeForName:@"engineTime"] stringValue] doubleValue];
    self.engineTimeString = [@(engineTime * MS_TO_S / 60) timeStringFromMinutes];
    double mileage = [[[rootElement attributeForName:@"mileage"] stringValue] doubleValue];
    self.mileageString = [NSString stringWithFormat:@"%.1f km", mileage / 1000];
    self.standsCount = [[[rootElement attributeForName:@"standsCount"] stringValue] integerValue];
    self.waysCount = [[[rootElement attributeForName:@"waysCount"] stringValue] integerValue];
}

@end

#pragma mark - ALCarEvents

@interface ALCarEventGroup ()

@property (nonatomic, assign) NSUInteger count;
@property (nonatomic, strong) NSDate *lastEventTime;
@property (nonatomic, assign) NSInteger type;

@end

@implementation ALCarEventGroup

- (NSString*)description {
    return [NSString stringWithFormat:@"%@ (count=%d time=%@, type=%d)",
            [super description], self.count, self.lastEventTime, self.type];
}

+ (NSDictionary*)eventsInfoDictionary {
    static NSDictionary *eventsInfo = nil;
    if (!eventsInfo) {
        eventsInfo = [[NSDictionary alloc] initWithContentsOfFile:
            [[NSBundle mainBundle] pathForResource:@"EventTypes" ofType:@"plist"]];
    }
    return eventsInfo;
}

- (NSDictionary*)info {
    NSString *key = [@(self.type) stringValue];
    return [[self class] eventsInfoDictionary][key];
}

- (NSString*)title {
    return self.info[@"title"];
}

- (BOOL)iconAvailable {
    return (self.info[@"icon"] != nil);
}

- (UIImage*)icon {
    return [[UIImage alloc] initWithContentsOfFile:
        [[NSBundle mainBundle] pathForResource:self.info[@"icon"] ofType:@"gif"]];
}

@end

@interface ALCarEvents ()

@property (nonatomic, strong) NSArray *events;
@end

@implementation ALCarEvents

const NSInteger eventTypeToFilter = 98;

- (NSString*)description {
    return [NSString stringWithFormat:@"%@ (events=%@)", [super description], self.events];
}

- (void)parseXMLDocument {
    GDataXMLElement *rootElement = self.xml.rootElement;
    
    if (![rootElement.name  isEqualToString:@"eventlist"]) {
        self.error = [NSError errorWithDomain:ALCarInfoErrorDomain code:-3 userInfo:nil];
        return;
    }
    
    NSUInteger nodesCount = rootElement.childCount;
    if (nodesCount == 0) {
        return;
    }

    NSMutableArray *events = [NSMutableArray arrayWithCapacity:nodesCount];
    
    NSInteger count = 0;
    for (int i = 0; i < nodesCount; i++) {
        GDataXMLElement *node = rootElement.children[i];
        if ([[[node attributeForName:@"type"] stringValue] integerValue] == eventTypeToFilter) {
            continue;
        }
        
        count++;
        
        NSInteger eventType = [[[node attributeForName:@"type"] stringValue] integerValue];
        double eventTime = [[[node attributeForName:@"eventTime"] stringValue] doubleValue];
        
        GDataXMLElement *nextNode = (i + 1 < nodesCount) ? rootElement.children[i + 1] : nil;
        NSInteger nextEventType = [[[nextNode attributeForName:@"type"] stringValue] integerValue];
        if (nextEventType == eventType) {
            continue;
        }

        ALCarEventGroup *event = [ALCarEventGroup new];
        event.lastEventTime = [NSDate dateWithTimeIntervalSince1970:eventTime * MS_TO_S];
        event.type = eventType;
        event.count = count;
        [events addObject:event];

        count = 0;
    }
    self.events = [events copy];
}

@end

