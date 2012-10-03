//
//  PasscodeViewController.h
//  https://github.com/jawj/PasscodeViewController
//
//  Copyright (c) 2011 George MacKerron
//  Released under the MIT licence: http://opensource.org/licenses/mit-license
//

#import "PasscodeViewController.h"

@interface PasscodeViewController ()

- (void)configureDisplay;
- (void)shakeWithStage:(NSNumber *)wrappedStage;
- (void)passcodeEntered;
+ (void)setPasscode:(NSString *)passcode;
+ (void)setFailedAttempts:(NSInteger)attempts;
- (void)challengeSucceeded;
- (void)setSucceeded;
- (void)dismiss;

@end

@implementation PasscodeViewController

@synthesize navBar, navItem, hiddenEntryField, containingView, slideOutImageView, promptLabel,
  delaySpinner, digit1, digit2, digit3, digit4, failureLabel, mismatchLabel, passcodeDelegate,
  theNewPasscode;

- (void)viewDidLoad {
  [super viewDidLoad];
  [self configureDisplay];
}

- (void)configureDisplay {
  BOOL passcodeExists = !! [PasscodeViewController passcode];
  
  BOOL sliding = state == PasscodeDisplayStateChangeEnterNew2 || 
                (state == PasscodeDisplayStateChangeEnterNew1 && (passcodeExists || mismatch));
  if (sliding) [slideOutImageView setImage:[containingView asUIImage]];
  
  ignoringInput = NO;
  hiddenEntryField.text = @"";
  [self passcodeChanged];  // clear the four * images
  [hiddenEntryField becomeFirstResponder];
  
  [delaySpinner stopAnimating];
  
  mismatchLabel.hidden = ! (mismatch && state == PasscodeDisplayStateChangeEnterNew1);
  
  NSInteger attempts = [PasscodeViewController failedAttempts];
  failureLabel.hidden = (attempts == 0);
  if (attempts > 0) {
    NSString *failureText = [NSString stringWithFormat:@"%i Failed Passcode Attempt%@", 
                             attempts, (attempts > 1 ? @"s" : @"")];
    [failureLabel setTitle:failureText forState:UIControlStateNormal];
    UIImage *bgImage = [UIImage imageNamed:@"passcodeFailedBackground.png"];
    [failureLabel setBackgroundImage:
      [bgImage stretchableImageWithLeftCapWidth:13.0 topCapHeight:13.0]
      forState:UIControlStateNormal];
    CGRect frame = failureLabel.frame;
    frame.size = CGSizeMake([failureText sizeWithFont:failureLabel.titleLabel.font].width + 35,
                            bgImage.size.height);
    failureLabel.frame = frame;
    failureLabel.center = CGPointMake(320.0 * 0.5, failureLabel.center.y);
  }
  
  if (state == PasscodeDisplayStateChallenge) {
    navItem.title = @"Enter passcode";
    promptLabel.text = @"Enter your passcode";
  } else {
    navItem.title = passcodeExists ? @"Change passcode" : @"Set passcode";
    if (passcodeExists)
      promptLabel.text = [NSString stringWithFormat:@"%@ your %@ passcode",
                          state == PasscodeDisplayStateChangeEnterNew2 ? @"Re-enter" : @"Enter",
                          state == PasscodeDisplayStateChangeEnterOld  ? @"old" : @"new"];
    else
      promptLabel.text = state == PasscodeDisplayStateChangeEnterNew1 ? @"Enter a passcode" : 
                                                                        @"Re-enter your passcode";
  }
  
  if (sliding) {
    CGPoint offLeftCenter  = CGPointMake(320.0 * -0.5, containingView.center.y);
    CGPoint onCenter       = CGPointMake(320.0 *  0.5, containingView.center.y);
    CGPoint offRightCenter = CGPointMake(320.0 *  1.5, containingView.center.y);
    slideOutImageView.center = onCenter;
    containingView.center    = offRightCenter;
    [UIView beginAnimations:nil context:nil];
    slideOutImageView.center = offLeftCenter;
    containingView.center    = onCenter;
    [UIView commitAnimations];
  }
}

- (void)shakeWithStage:(NSNumber *)wrappedStage {  
  // stages start at 0, and last stage re-centers; so e.g. 4 = right, left, right, left, center
  NSInteger stage = [wrappedStage integerValue];
  if (stage > kPasscodeFailedAttemptsShakeCount) [self configureDisplay];
  else {
    CGFloat xOffset = (stage == kPasscodeFailedAttemptsShakeCount ? 0 : 
                       kPasscodeFailedAttemptsShakeOffset * (stage % 2 ? 1 : -1));
    containingView.center = CGPointMake(320.0 * 0.5 + xOffset, containingView.center.y);
    [self performSelector:@selector(shakeWithStage:) 
               withObject:[NSNumber numberWithInt:stage + 1]
               afterDelay:kPasscodeFailedAttemptsShakeDelay];
  }
}

- (IBAction)cancelled {
  if (state == PasscodeDisplayStateChallenge && 
      [passcodeDelegate respondsToSelector:@selector(passcodeChallengeCancelled)]) 
    [passcodeDelegate passcodeChallengeCancelled];
  if (state != PasscodeDisplayStateChallenge && 
      [passcodeDelegate respondsToSelector:@selector(passcodeSetCancelled)]) 
    [passcodeDelegate passcodeSetCancelled];
  [self dismiss];
}

- (IBAction)passcodeChanged {
  if (ignoringInput) return;
  NSInteger length = [hiddenEntryField.text length];
  [digit1 setImage:(length > 0 ? kPasscodeImageDigit : kPasscodeImageBlank)];
  [digit2 setImage:(length > 1 ? kPasscodeImageDigit : kPasscodeImageBlank)];
  [digit3 setImage:(length > 2 ? kPasscodeImageDigit : kPasscodeImageBlank)];
  [digit4 setImage:(length > 3 ? kPasscodeImageDigit : kPasscodeImageBlank)];
  if (length > 3) [self passcodeEntered];
}

- (void)passcodeEntered {
  ignoringInput = YES;
  
  switch (state) {
    case PasscodeDisplayStateChallenge:
    case PasscodeDisplayStateChangeEnterOld:
      ;  // no-op weirdly seems required here to avoid syntax complaint with LLVM
      NSInteger failedAttempts = [PasscodeViewController failedAttempts];
      NSTimeInterval failureDelay = kPasscodeFailedAttemptsDelayFactor * 
        (failedAttempts >= kPasscodeFailedAttemptsUndelayedCount ?
        failedAttempts - kPasscodeFailedAttemptsUndelayedCount + 1 : 0);
      if (failureDelay > 0) [delaySpinner startAnimating];
      NSTimeInterval totalDelay = kPasscodeEntryPause + failureDelay;
      BOOL passcodeIsCorrect = [hiddenEntryField.text isEqual:[PasscodeViewController passcode]]; 
      if (passcodeIsCorrect) {
        [PasscodeViewController setFailedAttempts:0];
        if (state == PasscodeDisplayStateChallenge) {
          [self performSelector:@selector(challengeSucceeded) withObject:nil afterDelay:totalDelay];
        } else {
          state = PasscodeDisplayStateChangeEnterNew1;
          [self performSelector:@selector(configureDisplay) withObject:nil afterDelay:totalDelay];
        }
      } else { 
        [PasscodeViewController setFailedAttempts:failedAttempts + 1];
        [self performSelector:@selector(shakeWithStage:) 
                   withObject:[NSNumber numberWithInt:0]
                   afterDelay:totalDelay];
      }
      return;  // skip display reconfiguration at end of method
      
    case PasscodeDisplayStateChangeEnterNew1:
      self.theNewPasscode = hiddenEntryField.text;
      state = PasscodeDisplayStateChangeEnterNew2;
      break;
      
    case PasscodeDisplayStateChangeEnterNew2:
      ;  // no-op weirdly seems required here to avoid syntax complaint with LLVM
      BOOL passcodeMatches = [hiddenEntryField.text isEqual:theNewPasscode];
      if (passcodeMatches) {
        [PasscodeViewController setPasscode:theNewPasscode];
        [self performSelector:@selector(setSucceeded) 
                   withObject:nil 
                   afterDelay:kPasscodeEntryPause];
        return;  // skip display reconfiguration at end of method
      } else {
        mismatch = YES;
        state = PasscodeDisplayStateChangeEnterNew1;
      }      
  }
  [self performSelector:@selector(configureDisplay) withObject:nil afterDelay:kPasscodeEntryPause];
}

- (void)challengeWithDelegate:(NSObject *)aDelegate parentViewController:(UIViewController *)pvc {
  passcodeDelegate = aDelegate;
  if ([PasscodeViewController passcode]) {
    state = PasscodeDisplayStateChallenge;
    [pvc presentModalViewController:self animated:YES];
  } else {
    if ([passcodeDelegate respondsToSelector:@selector(passcodeChallengeSucceeded)]) 
      [passcodeDelegate passcodeChallengeSucceeded];
    [self release];
  }
}

+ (void)challengeWithDelegate:(NSObject *)aDelegate parentViewController:(UIViewController *)pvc {
  PasscodeViewController *vc = [[PasscodeViewController alloc] initWithNibName:nil bundle:nil];
  [vc challengeWithDelegate:aDelegate parentViewController:pvc];
}

- (void)setWithDelegate:(NSObject *)aDelegate parentViewController:(UIViewController *)pvc {
  passcodeDelegate = aDelegate;
  state = [PasscodeViewController passcode] ? PasscodeDisplayStateChangeEnterOld : 
                                              PasscodeDisplayStateChangeEnterNew1;
  [pvc presentModalViewController:self animated:YES];
}

+ (void)setWithDelegate:(NSObject *)aDelegate parentViewController:(UIViewController *)pvc {
  PasscodeViewController *vc = [[PasscodeViewController alloc] initWithNibName:nil bundle:nil];
  [vc setWithDelegate:aDelegate parentViewController:pvc];
}

+ (NSString *)passcode {
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  return [defaults stringForKey:kPasscodeKey];
}
         
+ (void)setPasscode:(NSString *)passcode {
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  [defaults setObject:passcode forKey:kPasscodeKey];
  [defaults synchronize];
}
       
+ (void)clear {
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  [defaults removeObjectForKey:kPasscodeKey];
  [defaults synchronize];
}

+ (NSInteger)failedAttempts {
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  [defaults synchronize];
  return [defaults integerForKey:kPasscodeFailedAttemptsKey];
}
 
+ (void)setFailedAttempts:(NSInteger)attempts {
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  [defaults setInteger:attempts forKey:kPasscodeFailedAttemptsKey];
  [defaults synchronize];
}

- (void)challengeSucceeded {
  if ([passcodeDelegate respondsToSelector:@selector(passcodeChallengeSucceeded)])
    [passcodeDelegate passcodeChallengeSucceeded];
  [self dismiss];
}

- (void)setSucceeded {
  if ([passcodeDelegate respondsToSelector:@selector(passcodeSetSucceeded)])
    [passcodeDelegate passcodeSetSucceeded];
  [self dismiss];
}

- (void)dismiss {
  failureLabel.hidden = YES;
  [NSObject cancelPreviousPerformRequestsWithTarget:self];
  [self dismissModalViewControllerAnimated:YES];
  [self release];
}
       
- (void)dealloc {
  self.navBar = nil;
  self.navItem = nil;
  self.hiddenEntryField = nil;
  self.containingView = nil;
  self.slideOutImageView = nil;
  self.promptLabel = nil;
  self.delaySpinner = nil;
  self.digit1 = nil;
  self.digit2 = nil;
  self.digit3 = nil;
  self.digit4 = nil;
  self.failureLabel = nil;
  self.mismatchLabel = nil;
  self.theNewPasscode = nil;
  [super dealloc];
}

@end
