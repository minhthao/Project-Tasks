//
//  PasswordResetViewController.h
//  Magpie
//
//  Created by minh thao nguyen on 9/3/15.
//  Copyright (c) 2015 Magpie. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>

@interface PasswordResetViewController : UIViewController <UITextFieldDelegate>
@property (nonatomic, strong) PFObject *userObj;
@end
