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
#import "ALPathRenderer.h"
#import "ALCarLocationAnnotation.h"

#import <MapKit/MapKit.h>
#import <QuartzCore/QuartzCore.h>

#define ZOOM_METTERS 250

@interface ALLocationController () <MKMapViewDelegate, ALRequestDelegate>

@property (nonatomic, strong) IBOutlet UILabel *updatedLabel;
@property (nonatomic, strong) IBOutlet MKMapView *mapView;
@property (nonatomic, strong) IBOutlet UIView *descriptionView;
@property (nonatomic, strong) IBOutlet UILabel *descriptionLabel1;
@property (nonatomic, strong) IBOutlet UILabel *descriptionLabel2;
@property (nonatomic, strong) IBOutlet UIProgressView *progressView;

@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, weak) ALCarLocationAnnotation *lastLocationAnnotation;
@property (nonatomic, weak) NSTimer *updateTimer;
@property (nonatomic, strong) NSDate *updatedDate;
@property (nonatomic, assign) BOOL mapRegionUpdatedWithUserLocation;

@property (nonatomic, weak) ALRequest *locationRequest;
@property (nonatomic, weak) ALRequest *telemetryRequest;
@property (nonatomic, strong) ALCarLocation *carLocationInfo;
@property (nonatomic, strong) ALCarTelemetry *carTelemetryInfo;
@property (nonatomic, assign) BOOL locationRequestFinished;
@property (nonatomic, assign) BOOL telemetryRequestFinished;

- (IBAction)loadData:(id)sender;

@end

@implementation ALLocationController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.leftBarButtonItem = [[MKUserTrackingBarButtonItem alloc] initWithMapView:self.mapView];
    [self updateWithCarLocationInfo];
    [self updateWithTelemetryInfo];
    self.progressView.alpha = 0.0f;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self startAutoupdateTimeLabel];
    BOOL allDataLoaded = (self.carLocationInfo != nil && self.carTelemetryInfo != nil);
    BOOL requestsRunning = (self.locationRequest.running || self.telemetryRequest.running);
    if (!allDataLoaded && !requestsRunning) {
        [self loadData:self];
    }
    [self displayUserLocation];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self stopAutoupdateTimeLabel];
}

#pragma mark - Properties

- (CLLocationManager*)locationManager {
  if (!_locationManager) {
    _locationManager = [CLLocationManager new];
  }
  return _locationManager;
}

#pragma mark - Private

- (void)displayUserLocation {
  if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusNotDetermined) {
    [self.locationManager requestWhenInUseAuthorization];
  }
}

- (void)startAutoupdateTimeLabel {
    [self updateTimerFired];
    self.updateTimer = [NSTimer scheduledTimerWithTimeInterval:1.0f target:self selector:@selector(updateTimerFired) userInfo:nil repeats:YES];
}

- (void)stopAutoupdateTimeLabel {
    [self.updateTimer invalidate];
}

- (void)updateTimerFired {
    [self updateTimeLabel];
    [self.lastLocationAnnotation update];
}

- (void)updateReloadButon {
    self.navigationItem.rightBarButtonItem.enabled =
        !self.locationRequest.running && !self.telemetryRequest.running;
}

- (void)updateProgressBar {
    BOOL showBar = self.locationRequest.running || self.telemetryRequest.running;
    
    if (showBar && self.progressBarHidden) {
        self.progressBarHidden = NO;
    } else if (!showBar && !self.progressBarHidden) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1.0 * NSEC_PER_SEC), dispatch_get_main_queue(), ^(void){
            self.progressBarHidden = YES;
        });
    }
    
    float progress = 0.0f;
    progress += self.locationRequestFinished ? 1.0 : self.locationRequest.progress;
    progress += self.telemetryRequestFinished ? 1.0 : self.telemetryRequest.progress;
    progress /= 2.0f;
    NSAssert(progress >= 0.0f && progress <= 1.0f, @"");
    self.progressView.progress = progress;
}

- (BOOL)progressBarHidden {
    return self.progressView.alpha == 0.0f;
}

- (void)setProgressBarHidden:(BOOL)hidden {
    [UIView animateWithDuration:0.3f animations:^{
        self.progressView.alpha = (hidden ? 0.0f : 1.0f);
    }];
}

#pragma mark - ALRequestDelegate

- (void)requestDidUpdateProgress:(ALRequest *)request {
    [self updateProgressBar];
}

#pragma mark - Actions

- (IBAction)loadData:(id)sender {
    if (![[NSUserDefaults standardUserDefaults] objectForKey:@"api-key"]) {
        return;
    }
    
    self.locationRequestFinished = NO;
    self.telemetryRequestFinished = NO;
    self.locationRequest = [ALRequest requestCarLocationWithCallback:^(ALCarInfo *carInfo) {
        NSLog(@"%@", carInfo);
        self.locationRequestFinished = YES;
        [self updateReloadButon];
        
        self.carLocationInfo = (ALCarLocation*)carInfo;
        [self updateWithCarLocationInfo];
        
        self.updatedDate = [NSDate date];
        [self updateTimeLabel];
    } delegate:self];

    self.telemetryRequest = [ALRequest requestCarTelemetryWithCallback:^(ALCarInfo *carInfo) {
        NSLog(@"%@", carInfo);
        self.telemetryRequestFinished = YES;
        [self updateReloadButon];
        
        self.carTelemetryInfo = (ALCarTelemetry*)carInfo;
        [self updateWithTelemetryInfo];
    } delegate:self];
    
    [self updateProgressBar];
    [self updateReloadButon];
}

#pragma mark - Data Presentation

- (void)updateTimeLabel {
    self.updatedLabel.text = [NSString stringWithFormat:@"Updated %@", self.updatedDate ? [self.updatedDate agoFromNow] : @"never"];
}

- (void)updateWithCarLocationInfo {
    // remove all annotations
    [self.mapView removeAnnotations:self.mapView.annotations];
    self.lastLocationAnnotation = nil;
    
    // remove route
    [self.mapView removeOverlays:self.mapView.overlays];
    
    // add last location annotation
    if (self.carLocationInfo.lastLocation) {
        ALCarLocationAnnotation *annotation = [[ALCarLocationAnnotation alloc] initWithCarLocationPoint:self.carLocationInfo.lastLocation];
        [self.mapView addAnnotation:annotation];
        self.lastLocationAnnotation = annotation;
        
        [self.mapView setRegion:MKCoordinateRegionMakeWithDistance(self.lastLocationAnnotation.coordinate, ZOOM_METTERS, ZOOM_METTERS)
                       animated:YES];
    }
    
    // add parking annotations
    for (ALCarLocationPoint *point in self.carLocationInfo.parkings) {
        [self.mapView addAnnotation:[[ALCarLocationAnnotation alloc] initWithCarLocationPoint:point]];
    }

    // add route
    if (self.carLocationInfo.coordinatesCount > 0) {
        [self.mapView addOverlay:[MKPolyline polylineWithCoordinates:self.carLocationInfo.coordinates
                                                               count:self.carLocationInfo.coordinatesCount]];
    }
}

- (void)updateWithTelemetryInfo {
    BOOL showDescription = (self.carTelemetryInfo != nil);
    if ((self.descriptionView.alpha == 1.0f) != showDescription) {
        [UIView animateWithDuration:0.3 animations:^{
            self.descriptionView.alpha = (showDescription ? 1.0f : 0.0f);
        }];
    }
    
    self.descriptionLabel1.text = [NSString stringWithFormat:@"%@ for %@",
                                   self.carTelemetryInfo.mileageString, self.carTelemetryInfo.engineTimeString];
    self.descriptionLabel2.text = [NSString stringWithFormat:@"%@ max, %d runs",
                                   self.carTelemetryInfo.maxSpeedString, self.carTelemetryInfo.waysCount];
}

#pragma mark Map Kit Delegate

- (void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation {
    if (!self.mapRegionUpdatedWithUserLocation && self.carLocationInfo == nil) {
        [self.mapView setRegion:MKCoordinateRegionMakeWithDistance(userLocation.coordinate, ZOOM_METTERS, ZOOM_METTERS)
                       animated:YES];
    }
    self.lastLocationAnnotation.userLocation = userLocation.location;
}

- (MKAnnotationView*)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation {    
    if ([annotation isKindOfClass:[ALCarLocationAnnotation class]]) {
        ALCarLocationAnnotation *locationAnnotation = (ALCarLocationAnnotation*)annotation;
        static NSString *identifier = @"location";
        MKPinAnnotationView *pin = (MKPinAnnotationView*)[mapView dequeueReusableAnnotationViewWithIdentifier:identifier];
        if (!pin) {
            pin = [[MKPinAnnotationView alloc] initWithAnnotation:locationAnnotation reuseIdentifier:identifier];
            pin.canShowCallout = YES;
            pin.animatesDrop = YES;
        }
        pin.annotation = locationAnnotation;
        pin.pinColor = locationAnnotation.isLastLocation ? MKPinAnnotationColorRed : MKPinAnnotationColorPurple;
        return pin;
    }
    NSParameterAssert(NO);
    return nil;
}

- (MKOverlayRenderer*)mapView:(MKMapView *)mapView rendererForOverlay:(id<MKOverlay>)overlay {
    if ([overlay isKindOfClass:[MKPolyline class]]) {
        MKPolyline *polyline = (MKPolyline*)overlay;
        MKPolylineRenderer *renderer = [[MKPolylineRenderer alloc] initWithPolyline:polyline];
        renderer.strokeColor = [UIColor blueColor];
        renderer.alpha = .75;
        renderer.lineWidth = 5.;
        return renderer;
    }
    NSParameterAssert(NO);
    return nil;
}

@end
