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

#define ZOOM_METTERS 250

@interface ALLocationController () <MKMapViewDelegate>

@property (strong, nonatomic) IBOutlet MKMapView *mapView;
@property (strong, nonatomic) IBOutlet UILabel *descriptionLabel1;
@property (strong, nonatomic) IBOutlet UILabel *descriptionLabel2;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *trackButton;

- (IBAction)loadData:(id)sender;
- (IBAction)trackButtonPressed:(id)sender;
- (void)updateAnnotation;

@end

@implementation ALLocationController

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.descriptionLabel1.alpha = 0.;
    self.descriptionLabel2.alpha = 0.;
    [self loadData:self];
}

#pragma mark - Private

- (void)updateAnnotation {
    for (MKShape *annotation in self.mapView.annotations) {
        if ([annotation isKindOfClass:[MKPointAnnotation class]]) {
            if (self.mapView.userLocation.location) {
                annotation.title = [NSString stringWithFormat:@"Car is %.0fm away", [self.mapView.userLocation.location distanceFromLocation:[[[CLLocation alloc] initWithLatitude:annotation.coordinate.latitude longitude:annotation.coordinate.longitude] autorelease]]];
            } else {
                annotation.title = @"Car";
            }
        }
    }
}

#pragma mark - Actions

- (IBAction)loadData:(id)sender {
    if (![[NSUserDefaults standardUserDefaults] objectForKey:@"api-key"]) {
        return;
    }
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSArray *points = [ALRequest runRequest:@"points"];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (points.count > 0) {
                NSLog(@"%d gps points. last: %@", points.count, [points objectAtIndex:0]);
                
                // removing annotation
                for (id annotation in self.mapView.annotations) {
                    if ([annotation isKindOfClass:[MKPointAnnotation class]]) {
                        [self.mapView removeAnnotation:annotation];
                    }
                }
                
                // adding annotation
                NSDictionary *point = [points objectAtIndex:0];
                MKPointAnnotation *annotation = [[[MKPointAnnotation alloc] init] autorelease];
                annotation.coordinate = CLLocationCoordinate2DMake([[point objectForKey:@"lat"] doubleValue], [[point objectForKey:@"lon"] doubleValue]);
                annotation.title = @"Car";
                if ([[point objectForKey:@"speed"] integerValue] > 0) {
                    annotation.subtitle = [NSString stringWithFormat:@"%@, %@ km/h", [[point objectForKey:@"date"] agoFromNow], [point objectForKey:@"speed"]];
                } else {
                    annotation.subtitle = [[point objectForKey:@"date"] agoFromNow];
                }
                [self.mapView setRegion:MKCoordinateRegionMakeWithDistance(annotation.coordinate, ZOOM_METTERS, ZOOM_METTERS) animated:YES];
                [self.mapView addAnnotation:annotation];
                [self updateAnnotation];
            }
            
            // remove route
            [self.mapView removeOverlays:self.mapView.overlays];
            
            // add route
            if (points.count > 1) {
                CLLocationCoordinate2D* coords = malloc(points.count * sizeof(CLLocationCoordinate2D));
                for (int i = 0; i < points.count; i++) {
                    coords[i] = CLLocationCoordinate2DMake([[[points objectAtIndex:i] objectForKey:@"lat"] doubleValue], [[[points objectAtIndex:i] objectForKey:@"lon"] doubleValue]);
                }
                [self.mapView addOverlay:[MKPolyline polylineWithCoordinates:coords count:points.count]];
                free(coords);
            }
            
        });
        if (!points)
            return;
        NSDictionary *info = [[ALRequest runRequest:@"telemetry"] lastObject];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (!info)
                return;
//            NSLog(@"telemetry data: %@", info);
            
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

- (IBAction)trackButtonPressed:(id)sender {
    [self.mapView setUserTrackingMode:MKUserTrackingModeFollowWithHeading animated:YES];
}

#pragma mark Map Kit Delegate

- (void)mapView:(MKMapView *)mapView didChangeUserTrackingMode:(MKUserTrackingMode)mode animated:(BOOL)animated {
    self.trackButton.enabled = mode == MKUserTrackingModeNone;
}

- (void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation {
    [self updateAnnotation];
}
/*
- (MKAnnotationView*)mapView:(MKMapView *)aMapView viewForAnnotation:(id<MKAnnotation>)annotation {
    static NSString *DefaultIdentifier = @"default";
    if ([annotation isKindOfClass:[MKPointAnnotation class]]) {
        MKPinAnnotationView *annotationView = (MKPinAnnotationView*)[aMapView dequeueReusableAnnotationViewWithIdentifier:DefaultIdentifier];
        if (!annotationView) {
            annotationView = [[[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:DefaultIdentifier] autorelease];
            annotationView.canShowCallout = YES;
            annotationView.animatesDrop = YES;
        }
        return annotationView;
    }
    return nil;
}
*/
- (void)mapView:(MKMapView *)mapView didAddAnnotationViews:(NSArray *)views {
    for (MKAnnotationView *annotationView in views) {
        if ([annotationView isKindOfClass:[MKPinAnnotationView class]]) {
            ((MKPinAnnotationView*)annotationView).animatesDrop = YES;
            [self.mapView selectAnnotation:annotationView.annotation animated:YES];
            break;
        }
    }
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
