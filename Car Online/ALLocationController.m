//
//  ALViewController.m
//  Car Online
//
//  Created by Alex Lebedev on 3/19/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ALLocationController.h"
#import "ALRequest.h"
#import "Convertions.h"
#import <MapKit/MapKit.h>
#import <QuartzCore/QuartzCore.h>

#define ZOOM_METTERS 250

@interface ALLocationController () <MKMapViewDelegate>

@property (nonatomic, strong) IBOutlet UILabel *updatedLabel;
@property (nonatomic, strong) IBOutlet MKMapView *mapView;
@property (nonatomic, strong) IBOutlet UIView *descriptionView;
@property (nonatomic, strong) IBOutlet UILabel *descriptionLabel1;
@property (nonatomic, strong) IBOutlet UILabel *descriptionLabel2;

@property (nonatomic, strong) MKPointAnnotation *carAnnotation;
@property (nonatomic, strong) NSTimer *updateTimer;
@property (nonatomic, strong) NSDate *updatedDate;

- (IBAction)loadData:(id)sender;

@end

@implementation ALLocationController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.leftBarButtonItem = [[MKUserTrackingBarButtonItem alloc] initWithMapView:self.mapView];
    self.descriptionView.layer.cornerRadius = 8.;
    self.descriptionView.alpha = 0.;
    [self loadData:self];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self updateUpdatedLabel];
    self.updateTimer = [NSTimer scheduledTimerWithTimeInterval:1. target:self selector:@selector(updateUpdatedLabel) userInfo:nil repeats:YES];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.updateTimer invalidate];
}

#pragma mark - Private

- (void)updateUpdatedLabel {
    self.updatedLabel.text = [NSString stringWithFormat:@"Updated %@", self.updatedDate ? [self.updatedDate agoFromNow] : @"never"];
}

- (void)updateAnnotation {
    if (self.mapView.userLocation.location) {
        CLLocationDistance distance = [self.mapView.userLocation.location distanceFromLocation:[[[CLLocation alloc] initWithLatitude:self.carAnnotation.coordinate.latitude longitude:self.carAnnotation.coordinate.longitude] autorelease]];
        self.carAnnotation.title = [NSString stringWithFormat:@"Car is %.0fm away", distance];
    } else {
        self.carAnnotation.title = @"Car";
    }
}

#pragma mark - Actions

- (IBAction)loadData:(id)sender {
    if (![[NSUserDefaults standardUserDefaults] objectForKey:@"api-key"]) {
        return;
    }
    self.navigationItem.rightBarButtonItem.enabled = NO;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSArray *points = [ALRequest runRequest:@"points"];
        dispatch_async(dispatch_get_main_queue(), ^{
            self.navigationItem.rightBarButtonItem.enabled = YES;
            if (points.count == 0) {
                return;
            }

            NSLog(@"%d gps points. last: %@", points.count, points[0]);

            // car annotation
            if (!self.carAnnotation) {
                self.carAnnotation = [[MKPointAnnotation alloc] init];
                self.carAnnotation.title = @"Car";
                [self.mapView addAnnotation:self.carAnnotation];
            }
            NSDictionary *point = points[0];
            self.carAnnotation.coordinate = CLLocationCoordinate2DMake([point[@"lat"] doubleValue], [point[@"lon"] doubleValue]);
            if ([point[@"speed"] integerValue] > 0) {
                self.carAnnotation.subtitle = [NSString stringWithFormat:@"%@, %@ km/h", [point[@"date"] agoFromNow], point[@"speed"]];
            } else {
                self.carAnnotation.subtitle = [point[@"date"] agoFromNow];
            }
            [self updateAnnotation];
            
            [self.mapView setRegion:MKCoordinateRegionMakeWithDistance(self.carAnnotation.coordinate, ZOOM_METTERS, ZOOM_METTERS) animated:YES];
        
            // remove route
            [self.mapView removeOverlays:self.mapView.overlays];
            
            // add route
            CLLocationCoordinate2D* coords = malloc(points.count * sizeof(CLLocationCoordinate2D));
            for (int i = 0; i < points.count; i++) {
                coords[i] = CLLocationCoordinate2DMake([points[i][@"lat"] doubleValue], [points[i][@"lon"] doubleValue]);
            }
            [self.mapView addOverlay:[MKPolyline polylineWithCoordinates:coords count:points.count]];
            free(coords);
        });
        if (!points) {
            return;
        }
        NSDictionary *info = [[ALRequest runRequest:@"telemetry"] lastObject];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (!info) {
                return;
            }
//            NSLog(@"telemetry data: %@", info);
            self.updatedDate = [NSDate date];
            [self updateUpdatedLabel];

            self.descriptionLabel1.text = [NSString stringWithFormat:@"%@ km for %@", info[@"mileage"], [info[@"engineTime"] timeStringFromMinutes]];
            self.descriptionLabel2.text = [NSString stringWithFormat:@"%@ km/h max, %d runs", info[@"maxSpeed"], [info[@"waysCount"] integerValue]];
            if (self.descriptionView.alpha < 1.) {
                [UIView animateWithDuration:.3 animations:^{
                    self.descriptionView.alpha = 1.;
                }];
            }
        });
    });
}

#pragma mark Map Kit Delegate

- (void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation {
    [self updateAnnotation];
}

- (MKAnnotationView*)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation {
    if (annotation == self.carAnnotation) {
        MKPinAnnotationView *pin = (MKPinAnnotationView*)[mapView dequeueReusableAnnotationViewWithIdentifier:@"cell"];
        if (!pin) {
            [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"pin"];
            pin.canShowCallout = YES;
            pin.animatesDrop = YES;
        } else {
            pin.annotation = annotation;
        }
        return pin;
    }
    return nil;
}

- (MKOverlayView *)mapView:(MKMapView *)mapView viewForOverlay:(id<MKOverlay>)overlay {
    if ([overlay isKindOfClass:[MKPolyline class]]) {
        MKPolylineView *pathView = [[[MKPolylineView alloc] initWithPolyline:overlay] autorelease];
        pathView.strokeColor = [[UIColor blueColor] colorWithAlphaComponent:.5];
        pathView.lineWidth = 5.;
        return pathView;
    }
    return nil;
}

@end
