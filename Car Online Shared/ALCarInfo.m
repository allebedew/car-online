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


