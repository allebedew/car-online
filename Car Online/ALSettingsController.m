//
//  ALSettingsController.m
//  Car Online
//
//  Created by Alex Lebedev on 28-03-12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ALSettingsController.h"
#import "ALRequest.h"

@interface ALSettingsController ()

@property (nonatomic, strong) IBOutlet UITextField *apiKeyField;
@property (nonatomic, strong) IBOutlet UIBarButtonItem *cancelButton;
@property (nonatomic, strong) IBOutlet UIBarButtonItem *doneButton;
@property (nonatomic, strong) IBOutlet UIActivityIndicatorView *activityIndicator;

- (IBAction)cancelPressed:(id)sender;
- (IBAction)donePressed:(id)sender;
- (IBAction)textFieldChanged:(id)sender;
- (void)updateDoneButton;

@end

@implementation ALSettingsController

@synthesize apiKeyField, cancelButton, doneButton, activityIndicator;

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return interfaceOrientation == UIInterfaceOrientationPortrait;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.apiKeyField.text = [[NSUserDefaults standardUserDefaults] objectForKey:@"api-key"];
    self.apiKeyField.rightView = self.activityIndicator;
    self.apiKeyField.rightViewMode = UITextFieldViewModeAlways;
    [self updateDoneButton];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.apiKeyField becomeFirstResponder];
}

- (void)updateDoneButton {
    self.doneButton.enabled = self.apiKeyField.text.length > 0;
}

- (IBAction)cancelPressed:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)donePressed:(id)sender {
    if (self.apiKeyField.text.length == 0)
        return;
    NSString *oldValue = [[NSUserDefaults standardUserDefaults] objectForKey:@"api-key"];
    [[NSUserDefaults standardUserDefaults] setObject:self.apiKeyField.text forKey:@"api-key"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [self.activityIndicator startAnimating];
//    self.cancelButton.enabled = NO;
    self.doneButton.enabled = NO;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSArray *data = [ALRequest runRequest:@"telemetry"];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.activityIndicator stopAnimating];
            self.cancelButton.enabled = YES;
            self.doneButton.enabled = YES;
            if (!data) {
                if (oldValue) {
                    [[NSUserDefaults standardUserDefaults] setObject:oldValue forKey:@"api-key"];
                } else {
                    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"api-key"];
                }
                [[NSUserDefaults standardUserDefaults] synchronize];
            }
            [[NSNotificationCenter defaultCenter] postNotificationName:@"api-key-changed" object:self];
            [self dismissViewControllerAnimated:YES completion:nil];
        });
    });
}

- (IBAction)textFieldChanged:(id)sender {
    [self updateDoneButton];
}

@end
