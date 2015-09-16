//
//  TripDetailViewController.m
//  Magpie
//
//  Created by minh thao nguyen on 5/21/15.
//  Copyright (c) 2015 Magpie. All rights reserved.
//

#import "TripDetailViewController.h"
#import "RoundButton.h"
#import "FontColor.h"
#import "DatePickerButton.h"
#import "FloatPlaceholderTextField.h"
#import "DatePickerViewController.h"
#import "Device.h"
#import "UnderLineButton.h"
#import "TripPlaceSelectTableViewController.h"
#import "ErrorMessageDisplay.h"
#import "UserManager.h"
#import "Device.h"
#import "TermsOfServiceViewController.h"
#import "ChatViewController.h"
#import "Mixpanel.h"
#import "MyPlaceListViewController.h"

static NSString * TITLE = @"Let's exchange";
static NSString * NAVIGATION_BAR_BACK_ICON_NAME = @"NavigationBarBackIconRed";
static NSString * PLACE_HOLDER_NUM_PEOPLE = @"Number of people";
static NSString * TERMS_OF_SERVICE_TITLE = @"Terms of Service";
static NSString * BOOK_BUTTON_TITLE = @"Request to stay";

static NSString * ERROR_NO_LISTING_TITLE = @"No active place";
static NSString * ERROR_NO_LISTING_DESCRIPTION = @"%@ currently doesn't have a place available for exchange. Please ask %@ for more information.";

@interface TripDetailViewController ()
@property (nonatomic, assign) CGFloat screenWidth;
@property (nonatomic, assign) CGFloat screenHeight;

@property (nonatomic, strong) ImportNudgePopup *importNudgePopup;

@property (nonatomic, strong) PMPeriod *currentPeriod;

@property (nonatomic, strong) UIBarButtonItem *backButton;
@property (nonatomic, strong) TripDetailPlaceView *pickPlaceView;
@property (nonatomic, strong) DatePickerButton *datePicker;
@property (nonatomic, strong) FloatPlaceholderTextField *numGuestsTextField;
@property (nonatomic, strong) UIToolbar *doneButton;
@property (nonatomic, strong) RoundButton *bookButton;

@end

@implementation TripDetailViewController
#pragma mark - initiation
/**
 * Lazily init the import nudge popup
 * @return ImportNudgePopup
 */
-(ImportNudgePopup *)importNudgePopup {
    if (_importNudgePopup == nil) {
        _importNudgePopup = [[ImportNudgePopup alloc] init];
        _importNudgePopup.importNudgeDelegate = self;
    }
    return _importNudgePopup;
}

/**
 * Lazily init the back button item
 * @return UIBarButtonItem
 */
-(UIBarButtonItem *)backButton {
    if (_backButton == nil) {
        _backButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:NAVIGATION_BAR_BACK_ICON_NAME]
                                                       style:UIBarButtonItemStyleBordered
                                                      target:self
                                                      action:@selector(goBack)];
    }
    return _backButton;
}

/**
 * Lazily init the trip detail place button
 * @return TripDetailPlaceView
 */
-(TripDetailPlaceView *)pickPlaceView {
    if (_pickPlaceView == nil) {
        CGRect frame = CGRectMake(15, 84, self.screenWidth - 30, 200);
        if ([Device isIphone4]) frame = CGRectMake(15, 18, self.screenWidth - 30, 150);
        _pickPlaceView = [[TripDetailPlaceView alloc] initWithFrame:frame];
        _pickPlaceView.tripDetailPlaceDelegate = self;
    }
    return _pickPlaceView;
}

/**
 * Lazily init the trip date
 * @return DatePickerButton
 */
-(DatePickerButton *)datePicker {
    if (_datePicker == nil) {
        _datePicker = [[DatePickerButton alloc] initWithFrame:CGRectMake(15, CGRectGetMaxY(self.pickPlaceView.frame) + 15, self.screenWidth - 30, 50)];
        [_datePicker addTarget:self action:@selector(datePickerClicked) forControlEvents:UIControlEventTouchUpInside];
    }
    return _datePicker;
}

/**
 * Lazily init the number of guests text field
 * @return FloatPlaceholderTextField
 */
-(FloatPlaceholderTextField *)numGuestsTextField {
    if (_numGuestsTextField == nil) {
        _numGuestsTextField = [[FloatPlaceholderTextField alloc] initWithPlaceHolder:PLACE_HOLDER_NUM_PEOPLE andFrame:CGRectMake(15, CGRectGetMaxY(self.datePicker.frame) + 15, self.screenWidth - 30, 50)];
        _numGuestsTextField.keyboardType = UIKeyboardTypeNumberPad;
        _numGuestsTextField.delegate = self;
        [_numGuestsTextField setInputAccessoryView:[self doneButton]];
    }
    return _numGuestsTextField;
}

/**
 * Lazily init the done button
 * @return UIToolbar
 */
-(UIToolbar *)doneButton {
    if (_doneButton == nil) {
        _doneButton = [[UIToolbar alloc] init];
        [_doneButton setBarStyle:UIBarStyleDefault];
        [_doneButton sizeToFit];
        
        UIBarButtonItem *flex = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:self action:nil];
        UIBarButtonItem *done =[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(hideKeyboard)];
        [_doneButton setItems:[NSArray arrayWithObjects:flex, done, nil]];
    }
    return _doneButton;
}

/**
 * Lazily init the book button
 * @return RoundButton
 */
-(RoundButton *)bookButton {
    if (_bookButton == nil) {
        _bookButton = [[RoundButton alloc] initWithFrame:CGRectMake(15, self.screenHeight - 70, self.screenWidth - 30, 50)];
        [_bookButton setTitle:BOOK_BUTTON_TITLE forState:UIControlStateNormal];
        _bookButton.enabled = NO;
        [_bookButton addTarget:self action:@selector(bookButtonClicked) forControlEvents:UIControlEventTouchUpInside];
    }
    return _bookButton;
}

#pragma mark - public methods
- (void)viewDidLoad {
    [super viewDidLoad];
    self.screenWidth = [UIScreen mainScreen].bounds.size.width;
    self.screenHeight = [UIScreen mainScreen].bounds.size.height;
    self.navigationItem.leftBarButtonItem = [self backButton];
    self.title = TITLE;
    self.view.backgroundColor = [UIColor whiteColor];
    self.view.userInteractionEnabled = YES;
    
    [self.view addSubview:[self pickPlaceView]];
    [self.view addSubview:[self datePicker]];
    [self.view addSubview:[self numGuestsTextField]];
    [self.view addSubview:[self bookButton]];
    
    if (self.propertyObj != nil) [self.pickPlaceView setPropertyObj:self.propertyObj];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideKeyboard)];
    [self.view addGestureRecognizer:tap];
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [UIApplication sharedApplication].statusBarHidden = NO;
    [self.navigationController setNavigationBarHidden:NO animated:false];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault];
    
    self.numGuestsTextField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:PLACE_HOLDER_NUM_PEOPLE attributes:@{NSForegroundColorAttributeName:[FontColor descriptionColor], NSFontAttributeName:[UIFont fontWithName:@"AvenirNext-Regular" size:14]}];
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [[UserManager sharedUserManager] getUserWithCompletionHandler:^(PFObject *userObj) {
        if ([userObj[@"numProperties"] intValue] == 0) [self performSelector:@selector(showNudgePopup) withObject:nil afterDelay:0.5];
    }];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
}

-(void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}

#pragma mark - public/private methods
/**
 * Show the nudge popup
 */
-(void)showNudgePopup {
    [[self importNudgePopup] showInParent];
}

/**
 * Set the new property object
 * @param PFObject
 */
-(void)setNewPropertyObj:(PFObject *)propertyObj {
    self.propertyObj = propertyObj;
    [self.pickPlaceView setPropertyObj:self.propertyObj];
}

/**
 * Set the trip duration
 * @param PMPeriod
 */
-(void)setTripDuration:(PMPeriod *)period {
    self.currentPeriod = period;
    if ([period.endDate compare:period.startDate] == NSOrderedAscending) self.currentPeriod =[PMPeriod periodWithStartDate:period.endDate endDate:period.startDate];
    NSString *durationTxt = [NSString stringWithFormat:@"%@ - %@", [self.currentPeriod.startDate dateStringWithFormat:@"MMM dd yyyy"], [self.currentPeriod.endDate dateStringWithFormat:@"MMM dd yyyy"]];
    [self.datePicker setDatePicked:durationTxt];
    [self toggleBookingButtonEnableState];
}

/**
 * Reset the enable state of the booking button
 */
-(void)toggleBookingButtonEnableState {
    self.bookButton.enabled = (self.propertyObj != nil && self.datePicker.titleLabel.text.length > 0 && self.numGuestsTextField.text.length > 0);
}

#pragma mark - keyboard
/**
 * Keyboard delegate - keyboard will show
 * @param NSNotification
 */
- (void)keyboardWillShow:(NSNotification *)notif {
    CGRect keyboardBounds;
    [[notif.userInfo valueForKey:UIKeyboardFrameBeginUserInfoKey] getValue:&keyboardBounds];
    CGFloat keyboardHeight = keyboardBounds.size.height;
    [UIView animateWithDuration:0.3 animations:^{
        self.view.transform = CGAffineTransformMakeTranslation(0, MIN(0, self.screenHeight - CGRectGetMaxY(self.numGuestsTextField.frame) - 40 - keyboardHeight));
    }];
}

/**
 * Keyboard delegate - keyboard will hide
 * @param NSNotification
 */
-(void)keyboardWillHide:(NSNotification *)notification {
    [UIView animateWithDuration:0.3 animations:^{
        self.view.transform = CGAffineTransformMakeTranslation(0, 0);
    }];
    [self toggleBookingButtonEnableState];
}

#pragma mark - UI gesture
/**
 * Align the text when it is in editting state
 * @param UITextField
 */
-(void)textFieldDidBeginEditing:(UITextField *)textField {
    self.numGuestsTextField.textAlignment = NSTextAlignmentCenter;
    
    self.numGuestsTextField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:PLACE_HOLDER_NUM_PEOPLE attributes:@{NSForegroundColorAttributeName:[FontColor descriptionColor], NSFontAttributeName:[UIFont fontWithName:@"AvenirNext-Regular" size:14]}];
}

/**
 * Align the text when it ended editting state
 * @param UITextField
 */
-(void)textFieldDidEndEditing:(UITextField *)textField {
    self.numGuestsTextField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:PLACE_HOLDER_NUM_PEOPLE attributes:@{NSForegroundColorAttributeName:[FontColor descriptionColor], NSFontAttributeName:[UIFont fontWithName:@"AvenirNext-Regular" size:14]}];
    if ([self.numGuestsTextField.text isEqual:PLACE_HOLDER_NUM_PEOPLE] || self.numGuestsTextField.text.length == 0) self.numGuestsTextField.textAlignment = NSTextAlignmentLeft;
    else self.numGuestsTextField.textAlignment = NSTextAlignmentCenter;
}

/**
 * Go back to the prev screen without updating
 */
-(void)goBack {
    [self.numGuestsTextField resignFirstResponder];
    [self.navigationController popViewControllerAnimated:YES];
}

/**
 * Resign the first responder from num guests text field
 */
-(void)hideKeyboard {
    [self.numGuestsTextField resignFirstResponder];
}

/**
 * Go to the date picker view controller when the date picker is clicked
 */
-(void)datePickerClicked {
    [self.numGuestsTextField resignFirstResponder];
    DatePickerViewController *datePickerViewController = [[DatePickerViewController alloc] init];
    datePickerViewController.targetUserName = [UserManager getUserNameFromUserObj:self.receiverObj];
    if (self.currentPeriod != nil) datePickerViewController.currentPeriod = self.currentPeriod;
    [self.navigationController pushViewController:datePickerViewController animated:YES];
}

/**
 * Select the new property if the user's has more property
 */
-(void)selectNewProperty {
    [self.numGuestsTextField resignFirstResponder];
    if (self.receiverObj[@"email"]) {
        //legitimate user
        int numActiveProperty = [self.receiverObj[@"numProperties"] intValue];
        if (numActiveProperty > 0) {
            TripPlaceSelectTableViewController *selectNewPlaceViewController = [[TripPlaceSelectTableViewController alloc] init];
            selectNewPlaceViewController.userObj = self.receiverObj;
            [self.navigationController pushViewController:selectNewPlaceViewController animated:YES];
        } else {
            NSString *targetUserName = [UserManager getUserNameFromUserObj:self.receiverObj];
            NSString *errorDescription = [NSString stringWithFormat:ERROR_NO_LISTING_DESCRIPTION, targetUserName, targetUserName];
            [ErrorMessageDisplay displayErrorAlertOnViewController:self withTitle:ERROR_NO_LISTING_TITLE andMessage:errorDescription];
        }
    } else {
        TripPlaceSelectTableViewController *selectNewPlaceViewController = [[TripPlaceSelectTableViewController alloc] init];
        selectNewPlaceViewController.userObj = self.receiverObj;
        [self.navigationController pushViewController:selectNewPlaceViewController animated:YES];
    }
    [self toggleBookingButtonEnableState];
}

/**
 * create new trip instance when the book button is clicked
 */
-(void)bookButtonClicked {
    [[Mixpanel sharedInstance] track:@"Chat - Book Button Click"];
    self.bookButton.enabled = NO;
    NSInteger currentViewControllerIndex = [self.navigationController.viewControllers indexOfObject:self];
    UIViewController *viewController = [self.navigationController.viewControllers objectAtIndex:currentViewControllerIndex - 1];
    if ([viewController isKindOfClass:ChatViewController.class]) {
        ChatViewController *chatViewController = (ChatViewController *)viewController;
        [chatViewController bookTripWithWithStartDate:[self.currentPeriod.startDate dateStringWithFormat:@"yyyy-MM-dd"] endDate:[self.currentPeriod.endDate dateStringWithFormat:@"yyyy-MM-dd"] numberOfGuests:[self.numGuestsTextField.text intValue] andPlace:self.propertyObj];
        [self.navigationController popViewControllerAnimated:YES];
    } else {
        ChatViewController *chatViewController = [[ChatViewController alloc] init];
        chatViewController.userObj = self.senderObj;
        chatViewController.targetUserObj = self.receiverObj;
        chatViewController.targetPropertyObj = self.propertyObj;
        [self.navigationController pushViewController:chatViewController animated:YES];
        [chatViewController bookTripWithWithStartDate:[self.currentPeriod.startDate dateStringWithFormat:@"yyyy-MM-dd"] endDate:[self.currentPeriod.endDate dateStringWithFormat:@"yyyy-MM-dd"] numberOfGuests:[self.numGuestsTextField.text intValue] andPlace:self.propertyObj];
    }
}

/**
 * ImportNudgePopup delegate
 * Go to my place
 */
-(void)goToMyPlace {
    MyPlaceListViewController *myPlaceList = [[MyPlaceListViewController alloc] init];
    [[UserManager sharedUserManager] getUserWithCompletionHandler:^(PFObject *userObj) {
        myPlaceList.userObj = userObj;
        [self.navigationController pushViewController:myPlaceList animated:YES];
    }];
}

/**
 * ImportNudgePopup delegate
 * Go back to the previous screen
 */
-(void)goBackToPreviousScreen {
    [self.navigationController popViewControllerAnimated:YES];
}

@end