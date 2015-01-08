//
//  ALMainViewController.m
//  Car Online
//
//  Created by Alex Lebedev on 6/9/13.
//
//

#import "ALMainViewController.h"
#import "ALRequest.h"

@import MapKit;

@interface ALMainViewController () <NSAlertDelegate>

@property (nonatomic, strong) IBOutlet NSTextField *textLabel;
@property (nonatomic, strong) IBOutlet MKMapView *mapView;

- (IBAction)loadData:(id)sender;

@end

@implementation ALMainViewController

- (id)init {
    self = [super initWithNibName:NSStringFromClass([self class]) bundle:nil];
    if (self) {
    }
    return self;
}

- (IBAction)loadData:(id)sender {
    [ALRequest setAPIKey:@"1e23019c8FdbffB2bec223311e1682"];
    [ALRequest requestCarTelemetryWithCallback:^(ALCarInfo *carInfo) {
        if (!carInfo) {
            return;
        }
        NSDictionary *telemetry = nil;
        [self.textLabel setStringValue:[NSString stringWithFormat:@"%ld stands, %ld km, %ld max",
                                        (long)[telemetry[@"standsCount"] integerValue], [telemetry[@"mileage"] integerValue], [telemetry[@"maxSpeed"] integerValue]]];
    }];
}

@end
