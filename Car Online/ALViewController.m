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
#import "ALSettingsController.h"

#define ZOOM_METTERS 250

@interface ALViewController () <MKMapViewDelegate, ALSettingsDelegate>

@property (strong, nonatomic) IBOutlet MKMapView *mapView;
@property (strong, nonatomic) IBOutlet UILabel *descriptionLabel1;
@property (strong, nonatomic) IBOutlet UILabel *descriptionLabel2;

- (void)loadData;

@end

@implementation ALViewController

@synthesize mapView, descriptionLabel1, descriptionLabel2;

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.descriptionLabel1.alpha = 0.;
    self.descriptionLabel2.alpha = 0.;
    
    if ([[NSUserDefaults standardUserDefaults] objectForKey:@"api-key"]) {
        [self loadData];
    } else {
        [self performSelector:@selector(showSettings:) withObject:self afterDelay:1.];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self becomeFirstResponder];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self resignFirstResponder];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqual:@"settings"]) {
        ((ALSettingsController*)segue.destinationViewController).delegate = self;
    }
}

- (void)settingsControllerDidSaveChanges:(ALSettingsController *)controller {
    [self loadData];
    [controller dismissModalViewControllerAnimated:YES];
}

- (void)loadData {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSArray *points = [ALRequest runRequest:@"points"];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (!points.count)
                return;
            NSLog(@"%d gps points. last: %@", points.count, [points objectAtIndex:0]);
            
            // removing annotation
            for (id annotation in self.mapView.annotations) {
                if ([annotation isKindOfClass:[NSDictionary class]]) {
                    [self.mapView removeAnnotation:annotation];
                }
            }
            
            // adding annotation
            NSDictionary *lastPoint = [points objectAtIndex:0];
            [self.mapView setRegion:MKCoordinateRegionMakeWithDistance(lastPoint.coordinate, ZOOM_METTERS, ZOOM_METTERS) animated:YES];
            [self.mapView addAnnotation:lastPoint];
            
            // add route
            [self.mapView addOverlay:points];
        });
    });
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSDictionary *info = [[ALRequest runRequest:@"telemetry"] lastObject];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (!info)
                return;
            NSLog(@"telemetry data: %@", info);
            
            self.descriptionLabel1.text = [NSString stringWithFormat:@"%@ km (%@)", [info objectForKey:@"mileage"], [[info objectForKey:@"engineTime"] timeStringFromMinutes]];
            self.descriptionLabel2.text = [NSString stringWithFormat:@"%@ km/h max", [info objectForKey:@"maxSpeed"]];
            if (self.descriptionLabel1.alpha < 1.) {
                [UIView animateWithDuration:.3 animations:^{
                    self.descriptionLabel1.alpha = 1.;
                    self.descriptionLabel2.alpha = 1.;
                }];
            }
        });
    });
}

#pragma mark Map Kit Delegate

- (void)mapView:(MKMapView *)mapView didAddAnnotationViews:(NSArray *)views {
    for (MKAnnotationView *annotationView in views) {
        if ([annotationView.annotation isKindOfClass:[NSDictionary class]]) {
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

@implementation NSDictionary (MapKit)

- (CLLocationCoordinate2D)coordinate {
    return CLLocationCoordinate2DMake([[self objectForKey:@"lat"] doubleValue], [[self objectForKey:@"lon"] doubleValue]);
}

- (NSString*)title {
    return @"Car";
}

- (NSString*)subtitle {
    NSMutableString *subtitle = [[[self objectForKey:@"date"] agoString] mutableCopy];
    if ([[self objectForKey:@"speed"] integerValue] > 0)
        [subtitle appendFormat:@", %@ km/h", [self objectForKey:@"speed"]];
    return subtitle;
}

@end

@implementation NSArray (MapKit)

- (CLLocationCoordinate2D)coordinate {
    return CLLocationCoordinate2DMake(0, 0);
}

- (MKMapRect)boundingMapRect {
    return MKMapRectMake(0, 0, 1000, 1000);
}

- (BOOL)intersectsMapRect:(MKMapRect)mapRect {
    return YES;
}

@end
