//
//  TripPlaceTableViewCell.h
//  Magpie
//
//  Created by minh thao nguyen on 5/27/15.
//  Copyright (c) 2015 Magpie. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>

@interface TripPlaceTableViewCell : UITableViewCell
-(void)setPropertyObj:(PFObject *)propertyObj;
@end
