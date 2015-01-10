//
//  ALViewController.m
//  Car Online
//
//  Created by Alex Lebedev on 3/19/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ALLocationController.h"
#import "Convertions.h"
#import "ALPathRenderer.h"
#import "ALCarLocationAnnotation.h"
#import "ALAppDelegate.h"
#import "ALRequestFactory.h"
#import "ALTelemetryModel.h"
#import "ALPointModel.h"

#import "Mantle.h"
#import "AFNetworking.h"
#import <MapKit/MapKit.h>
#import <QuartzCore/QuartzCore.h>

@interface ALLocationController () <MKMapViewDelegate>

@property (nonatomic, strong) IBOutlet UILabel *tripsLabel;
@property (nonatomic, strong) IBOutlet UILabel *timeLabel;
@property (nonatomic, strong) IBOutlet UILabel *distanceLabel;
@property (nonatomic, strong) IBOutlet UILabel *maxSpeedLabel;

@property (nonatomic, strong) IBOutlet UILabel *updatedLabel;
@property (nonatomic, strong) IBOutlet MKMapView *mapView;
@property (nonatomic, strong) IBOutlet UIProgressView *progressView;

@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, weak) ALCarLocationAnnotation *lastLocationAnnotation;
@property (nonatomic, weak) NSTimer *updateTimer;
@property (nonatomic, strong) NSDate *updatedDate;
@property (nonatomic, assign) BOOL mapRegionUpdatedWithUserLocation;

@property (nonatomic, weak) NSURLSessionDataTask *telemetryTask;
@property (nonatomic, weak) NSURLSessionDataTask *pointsTask;

@property (nonatomic, copy) ALTelemetryModel *telemetryModel;
@property (nonatomic, copy) NSArray *points;
@property (nonatomic, copy) NSArray *parkings;

- (IBAction)loadData:(id)sender;

@end

@implementation ALLocationController

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self startAutoupdateTimeLabel];
    BOOL allDataLoaded = (self.telemetryModel && self.points);
    BOOL requestsRunning = (self.telemetryTask || self.pointsTask);
    if (!allDataLoaded && !requestsRunning) {
        [self loadData:self];
    }
    [self displayUserLocation];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self stopAutoupdateTimeLabel];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.leftBarButtonItem = [[MKUserTrackingBarButtonItem alloc] initWithMapView:self.mapView];
    [self reloadTelemetryData];
    [self reloadPointsData];

    self.progressView.alpha = 0.0f;
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
    self.navigationItem.rightBarButtonItem.enabled = YES;
}

- (void)updateTimeLabel {
    self.updatedLabel.text = [NSString stringWithFormat:@"Updated %@", self.updatedDate ? [self.updatedDate agoFromNow] : @"never"];
}

- (BOOL)progressBarHidden {
    return self.progressView.alpha == 0.0f;
}

- (void)setProgressBarHidden:(BOOL)hidden {
    [UIView animateWithDuration:0.3f animations:^{
        self.progressView.alpha = (hidden ? 0.0f : 1.0f);
    }];
}

#pragma mark - Actions

- (IBAction)loadData:(id)sender {
    NSParameterAssert([[NSUserDefaults standardUserDefaults] objectForKey:@"api-key"]);

    __weak typeof(self) weakSelf = self;

    self.telemetryTask =
        [[ALAppDelegate appDelegate].sessionManager
            dataTaskWithRequest:[ALRequestFactory requestForTelemetry]
              completionHandler:^(NSURLResponse *response, id responseObject, NSError *error)
    {
        self.progressView.progress += 0.5;
        if (self.progressView.progress >= 1) {
            self.progressBarHidden = YES;
        }

        if (error) {
            NSLog(@"%@", error);
            return;
        }
        weakSelf.telemetryModel =
            [MTLJSONAdapter modelOfClass:[ALTelemetryModel class] fromJSONDictionary:responseObject error:&error];

        [weakSelf reloadTelemetryData];

    }];
    [self.telemetryTask resume];

    self.pointsTask =
        [[ALAppDelegate appDelegate].sessionManager
            dataTaskWithRequest:[ALRequestFactory requestForGPSList]
              completionHandler:^(NSURLResponse *response, id responseObject, NSError *error)
    {
        self.progressView.progress += 0.5;
        if (self.progressView.progress >= 1) {
            self.progressBarHidden = YES;
        }


        if (error) {
            NSLog(@"%@", error);
            return;
        }
        weakSelf.points =
            [MTLJSONAdapter modelsOfClass:[ALPointModel class] fromJSONArray:responseObject[@"gpslist"] error:&error];
        weakSelf.parkings = [ALPointModel parkingsFromPoints:weakSelf.points];

        [weakSelf reloadPointsData];
    }];
    [self.pointsTask resume];

    self.progressView.progress = 0.1;
    self.progressBarHidden = NO;

    [self updateReloadButon];
}

#pragma mark - Data Presentation

- (void)reloadTelemetryData {
    if (self.telemetryModel) {
        self.tripsLabel.text = self.telemetryModel.waysCount.stringValue;
        self.distanceLabel.text = self.telemetryModel.mileageString;
        self.timeLabel.text = self.telemetryModel.engineTimeString;
        self.maxSpeedLabel.text = self.telemetryModel.maxSpeedString;
    } else {
        self.tripsLabel.text = @"-";
        self.distanceLabel.text = @"-";
        self.timeLabel.text = @"-";
        self.maxSpeedLabel.text = @"-";
    }
}

- (void)reloadPointsData {

    // remove all annotations
    [self.mapView removeAnnotations:self.mapView.annotations];
    self.lastLocationAnnotation = nil;

    // remove route
    [self.mapView removeOverlays:self.mapView.overlays];

    // add parking annotations
    [self.parkings enumerateObjectsUsingBlock:^(ALParkingModel *parking, NSUInteger idx, BOOL *stop) {

        ALCarLocationAnnotation *annotation = [[ALCarLocationAnnotation alloc] initWithParking:parking];
        [self.mapView addAnnotation:annotation];

        if (idx == 0) {
            self.lastLocationAnnotation = annotation;

            static const CLLocationDistance kArea = 250;
            [self.mapView setRegion:MKCoordinateRegionMakeWithDistance(annotation.coordinate, kArea, kArea) animated:YES];
        }
    }];

    // add route
    if (self.points.count > 0) {
        __block CLLocationCoordinate2D* coords = malloc(self.points.count * sizeof(CLLocationCoordinate2D));

        [self.points enumerateObjectsUsingBlock:^(ALPointModel *point, NSUInteger idx, BOOL *stop) {
            coords[idx] = point.coord;
        }];

        [self.mapView addOverlay:[MKPolyline polylineWithCoordinates:coords count:self.points.count]];
    }
}

#pragma mark Map Kit Delegate

- (void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation {
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
    if ([annotation isKindOfClass:[MKUserLocation class]]) {
        return nil;
    }
    NSParameterAssert(NO);
    return nil;
}

- (MKOverlayRenderer*)mapView:(MKMapView *)mapView rendererForOverlay:(id<MKOverlay>)overlay {
    if ([overlay isKindOfClass:[MKPolyline class]]) {
        MKPolyline *polyline = (MKPolyline*)overlay;
        MKPolylineRenderer *renderer = [[MKPolylineRenderer alloc] initWithPolyline:polyline];
        renderer.strokeColor = [UIColor greenColor];
        renderer.alpha = .75;
        renderer.lineWidth = 5.;
        return renderer;
    }
    NSParameterAssert(NO);
    return nil;
}

@end
