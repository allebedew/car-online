//
//  ALSettingsController.h
//  Car Online
//
//  Created by Alex Lebedev on 28-03-12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ALSettingsDelegateProtocol.h"

@interface ALSettingsController : UIViewController

@property (nonatomic, weak) id <ALSettingsDelegate> delegate;

@end
