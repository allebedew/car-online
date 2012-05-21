//
//  ALSettingsDelegateProtocol.h
//  Car Online
//
//  Created by Alex Lebedev on 31-03-12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ALSettingsController;

@protocol ALSettingsDelegate <NSObject>

- (void)settingsControllerDidSaveChanges:(ALSettingsController*)controller;

@end
