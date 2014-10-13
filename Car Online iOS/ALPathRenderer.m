//
//  ALPathRenderer.m
//  Car Online
//
//  Created by Alex on 10/12/14.
//
//

#import "ALPathRenderer.h"

@implementation ALPathRenderer

- (void)createPath {
    NSLog(@"CREATE");
    [super createPath];
}

- (void)drawMapRect:(MKMapRect)mapRect zoomScale:(MKZoomScale)zoomScale inContext:(CGContextRef)context {
//    NSLog(@"DRAW %@", NSStringFromCGRect([self rectForMapRect:mapRect]));
    [super drawMapRect:mapRect zoomScale:zoomScale inContext:context];
}

- (void)applyStrokePropertiesToContext:(CGContextRef)context
                           atZoomScale:(MKZoomScale)zoomScale {
    NSLog(@"APPLY z=%f", zoomScale);
    [super applyStrokePropertiesToContext:context atZoomScale:zoomScale];
    UIColor* color = [self getNextColor];
    CGContextSetStrokeColorWithColor(context, color.CGColor);
}

- (void)strokePath:(CGPathRef)path inContext:(CGContextRef)context {
    NSLog(@"STROKE %@", path);
    [super strokePath:path inContext:context];
}

- (UIColor*)getNextColor {
    static CGFloat i = 0;
    i = i >= 1 ? 0 : i + .1;
    UIColor *color = [UIColor colorWithHue:i saturation:1 brightness:1 alpha:1];
    return color;
}

@end
