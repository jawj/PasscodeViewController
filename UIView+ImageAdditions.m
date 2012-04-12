//
//  UIView+ImageAdditions.m
//  https://github.com/jawj/PasscodeViewController
//
//  Copyright (c) 2011 George MacKerron
//  Released under the MIT licence: http://opensource.org/licenses/mit-license
//

#import "UIView+ImageAdditions.h"

@implementation UIView (ImageAdditions)

- (UIImage *)asUIImage {
  UIGraphicsBeginImageContext(self.bounds.size);
  [self.layer renderInContext:UIGraphicsGetCurrentContext()];
  UIImage *viewImage = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();
  return viewImage;
}

@end