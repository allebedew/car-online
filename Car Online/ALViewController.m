//
//  ALViewController.m
//  Car Online
//
//  Created by Alex Lebedev on 3/19/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ALViewController.h"
#import "ALRequest.h"
#import "Convertions.h"
#import "ALMapKitObjects.h"

#define ZOOM_METTERS 250

@interface ALViewController () <MKMapViewDelegate>

@property (strong, nonatomic) IBOutlet MKMapView *mapView;
@property (strong, nonatomic) IBOutlet UILabel *descriptionLabel1;
@property (strong, nonatomic) IBOutlet UILabel *descriptionLabel2;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *trackButton;

- (void)loadData;
- (void)setAutoUpdateAnnotation:(BOOL)on;
- (void)updateAnnotation;
- (IBAction)trackButtonPressed:(id)sender;

@end

@implementation ALViewController

@synthesize mapView, descriptionLabel1, descriptionLabel2, trackButton;

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}

- (void)awakeFromNib {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loadData) name:UIApplicationWillEnterForegroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loadData) name:@"api-key-changed" object:nil];
    [self setAutoUpdateAnnotation:YES];
    [self loadData];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.descriptionLabel1.alpha = 0.;
    self.descriptionLabel2.alpha = 0.;
}

- (void)loadData {
    if (![[NSUserDefaults standardUserDefaults] objectForKey:@"api-key"]) {
        [self performSelector:@selector(showSettings) withObject:nil afterDelay:1.];
        return;
    }
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSArray *points = [ALRequest runRequest:@"points"];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (!points.count)
                return;
            NSLog(@"%d gps points. last: %@", points.count, [points objectAtIndex:0]);
            
            // removing annotation
            for (id annotation in self.mapView.annotations) {
                if ([annotation isKindOfClass:[ALAnnotation class]]) {
                    [self.mapView removeAnnotation:annotation];
                }
            }
            
            // adding annotation
            ALAnnotation *annotation = [[ALAnnotation alloc] init];
            annotation.gpsPoint = [points objectAtIndex:0];
            annotation.coordinate = CLLocationCoordinate2DMake([[annotation.gpsPoint objectForKey:@"lat"] doubleValue], [[annotation.gpsPoint objectForKey:@"lon"] doubleValue]);
            [self.mapView setRegion:MKCoordinateRegionMakeWithDistance(annotation.coordinate, ZOOM_METTERS, ZOOM_METTERS) animated:YES];
            [self.mapView addAnnotation:annotation];
            [self updateAnnotation];
            
            // add route
//            [self.mapView addOverlay:points];
        });
        if (!points)
            return;
        NSDictionary *info = [[ALRequest runRequest:@"telemetry"] lastObject];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (!info)
                return;
            NSLog(@"telemetry data: %@", info);
            
            self.descriptionLabel1.text = [NSString stringWithFormat:@"%@ km for %@", [info objectForKey:@"mileage"], [[info objectForKey:@"engineTime"] timeStringFromMinutes]];
            self.descriptionLabel2.text = [NSString stringWithFormat:@"%@ km/h max, %d runs", [info objectForKey:@"maxSpeed"], [[info objectForKey:@"waysCount"] integerValue]];
            if (self.descriptionLabel1.alpha < 1.) {
                [UIView animateWithDuration:.3 animations:^{
                    self.descriptionLabel1.alpha = 1.;
                    self.descriptionLabel2.alpha = 1.;
                }];
            }
        });
    });
}

- (void)showSettings {
    [self performSegueWithIdentifier:@"settings" sender:self];
}

- (void)setAutoUpdateAnnotation:(BOOL)on {
    if (on) {
        updateTimer = [NSTimer scheduledTimerWithTimeInterval:10. target:self selector:@selector(updateAnnotation) userInfo:nil repeats:YES];
    } else {
        [updateTimer invalidate];
    }
}

- (void)updateAnnotation {
    for (id anAnnotation in self.mapView.annotations) {
        if ([anAnnotation isKindOfClass:[ALAnnotation class]]) {
            ALAnnotation *annotation = anAnnotation;
            if (mapView.userLocation.location) {
                annotation.title = [NSString stringWithFormat:@"Car is %.0fm away", [self.mapView.userLocation.location distanceFromLocation:[[CLLocation alloc] initWithLatitude:annotation.coordinate.latitude longitude:annotation.coordinate.longitude]]];            
            } else {
                annotation.title = @"Car";
            }
            if ([[annotation.gpsPoint objectForKey:@"speed"] integerValue] > 0) {
                annotation.subtitle = [NSString stringWithFormat:@"%@, %@ km/h", [[annotation.gpsPoint objectForKey:@"date"] agoFromNow], [annotation.gpsPoint objectForKey:@"speed"]];
            } else {
                annotation.subtitle = [[annotation.gpsPoint objectForKey:@"date"] agoFromNow];
            }
        }
    }
}

- (IBAction)trackButtonPressed:(id)sender {
    if (self.mapView.userTrackingMode == MKUserTrackingModeNone) {
        [self.mapView setUserTrackingMode:MKUserTrackingModeFollowWithHeading animated:YES];
    } else {
        [self.mapView setUserTrackingMode:MKUserTrackingModeNone animated:YES];
    }
}

#pragma mark Map Kit Delegate

- (void)mapView:(MKMapView *)mapView didChangeUserTrackingMode:(MKUserTrackingMode)mode animated:(BOOL)animated {
    self.trackButton.tintColor = mode == MKUserTrackingModeNone ? [UIColor colorWithWhite:.4 alpha:1.] : [UIColor colorWithHue:.58 saturation:.7 brightness:.8 alpha:1.];
}

- (void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation {
    [self updateAnnotation];
}

- (void)mapView:(MKMapView *)mapView didAddAnnotationViews:(NSArray *)views {
    for (MKAnnotationView *annotationView in views) {
        if ([annotationView.annotation isKindOfClass:[ALAnnotation class]]) {
            [self.mapView selectAnnotation:annotationView.annotation animated:YES];
            break;
        }
    }
}

- (MKOverlayView *)mapView:(MKMapView *)mapView viewForOverlay:(id < MKOverlay >)overlay {
    NSLog(@"view for overlay %@", nil);
    return nil;
}

- (void)mapView:(MKMapView *)mapView didAddOverlayViews:(NSArray *)overlayViews {
    NSLog(@"add overlays %@", overlayViews);
}

#pragma Shake Detection

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self becomeFirstResponder];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self resignFirstResponder];
}

- (BOOL)canBecomeFirstResponder {
    return YES;
}

- (void)motionEnded:(UIEventSubtype)motion withEvent:(UIEvent *)event {
    if (motion == UIEventSubtypeMotionShake) {
        NSLog(@"shake detected");
        [self loadData];
    }
}

@end
