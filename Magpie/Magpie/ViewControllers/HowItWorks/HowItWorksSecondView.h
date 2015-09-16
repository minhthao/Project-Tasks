//
//  ValuePropSecondView.h
//  Magpie
//
//  Created by minh thao nguyen on 7/29/15.
//  Copyright (c) 2015 Magpie. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HowItWorksViewController.h"

@interface HowItWorksSecondView : UIView <HowItWorkViewDelegate>
@property (nonatomic, weak) id<HowItWorkViewDelegate> howItWorksViewDelegate;
-(void)showView;
-(void)hideView;
@end
