//
//  PasscodeViewController.h
//  https://github.com/jawj/PasscodeViewController
//
//  Copyright (c) 2011 George MacKerron
//  Released under the MIT licence: http://opensource.org/licenses/mit-license
//

#import <QuartzCore/QuartzCore.h>  // for CALayer.cornerRadius
#import "UIView+ImageAdditions.h"

#define kPasscodeEntryPause                     0.2  // seconds
#define kPasscodeFailedAttemptsShakeCount       5    // count
#define kPasscodeFailedAttemptsShakeOffset      7    // pixels
#define kPasscodeFailedAttemptsShakeDelay       0.05 // seconds
#define kPasscodeFailedAttemptsUndelayedCount   5    // count
#define kPasscodeFailedAttemptsDelayFactor      1.0  // seconds
                                  
#define kPasscodeKey                @"com.mackerron.passcode"
#define kPasscodeFailedAttemptsKey  @"com.mackerron.passcodeFailedAttempts"

#define kPasscodeImageBlank         [UIImage imageNamed:@"passcodeDigitBlank.png"]
#define kPasscodeImageDigit         [UIImage imageNamed:@"passcodeDigitEntered.png"]

typedef enum {
  PasscodeDisplayStateChallenge,
  PasscodeDisplayStateChangeEnterOld,
  PasscodeDisplayStateChangeEnterNew1,
  PasscodeDisplayStateChangeEnterNew2
} PasscodeDisplayState;

@protocol PasscodeViewControllerDelegate

@optional
- (void)passcodeChallengeSucceeded;
- (void)passcodeChallengeCancelled;
- (void)passcodeSetSucceeded;
- (void)passcodeSetCancelled;

@end

@interface PasscodeViewController : UIViewController {
  UINavigationBar *navBar;
  UINavigationItem *navItem;
  UITextField *hiddenEntryField;
  UIView *containingView;
  UIImageView *slideOutImageView;
  UILabel *promptLabel;
  UIActivityIndicatorView *delaySpinner;
  UIImageView *digit1;
  UIImageView *digit2;
  UIImageView *digit3;
  UIImageView *digit4;
  UIButton *failureLabel;
  UILabel *mismatchLabel;
  
  PasscodeDisplayState state;
  BOOL ignoringInput;
  BOOL mismatch;
  NSObject <PasscodeViewControllerDelegate> *passcodeDelegate;
  NSString *newPasscode;
}

@property (nonatomic, retain) IBOutlet UINavigationBar *navBar;
@property (nonatomic, retain) IBOutlet UINavigationItem *navItem;
@property (nonatomic, retain) IBOutlet UITextField *hiddenEntryField;
@property (nonatomic, retain) IBOutlet UIView *containingView;
@property (nonatomic, retain) IBOutlet UIImageView *slideOutImageView;
@property (nonatomic, retain) IBOutlet UILabel *promptLabel;
@property (nonatomic, retain) IBOutlet UIActivityIndicatorView *delaySpinner;
@property (nonatomic, retain) IBOutlet UIImageView *digit1;
@property (nonatomic, retain) IBOutlet UIImageView *digit2;
@property (nonatomic, retain) IBOutlet UIImageView *digit3;
@property (nonatomic, retain) IBOutlet UIImageView *digit4;
@property (nonatomic, retain) IBOutlet UIButton *failureLabel;
@property (nonatomic, retain) IBOutlet UILabel *mismatchLabel;

@property (nonatomic, assign) NSObject *passcodeDelegate;
@property (nonatomic, retain) NSString *newPasscode;

- (IBAction)passcodeChanged;
- (IBAction)cancelled;

+ (void)challengeWithDelegate:(NSObject *)aDelegate parentViewController:(UIViewController *)pvc;
+ (void)setWithDelegate:(NSObject *)aDelegate parentViewController:(UIViewController *)pvc;
+ (void)clear;
+ (NSString *)passcode;
+ (NSInteger)failedAttempts;

@end
