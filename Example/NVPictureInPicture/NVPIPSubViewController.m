//
//  NVPIPSubViewController.m
//  NVPictureInPicture_Example
//
//  Created by Nitesh Vijay on 03/05/18.
//  Copyright © 2018 niteshvijay1995. All rights reserved.
//

#import "NVPIPSubViewController.h"

static const CGFloat EdgeInset = 5;

@interface NVPIPSubViewController ()

@end

@implementation NVPIPSubViewController

- (UIEdgeInsets)edgeInsetsForDisplayModeCompact {
  UIEdgeInsets safeAreaInsets;
  if (@available(iOS 11.0, *)) {
    safeAreaInsets = [UIApplication sharedApplication].keyWindow.safeAreaInsets;
  } else {
    safeAreaInsets = UIEdgeInsetsMake(0, 0, 0, 0);
  }
  return UIEdgeInsetsMake(EdgeInset + safeAreaInsets.top,
                          EdgeInset + safeAreaInsets.left,
                          EdgeInset + safeAreaInsets.bottom,
                          EdgeInset + safeAreaInsets.right);
}

- (CGRect)frameForDisplayMode:(NVPIPDisplayMode)displayMode {
  CGSize screenSize = [UIScreen mainScreen].bounds.size;
  if (displayMode == NVPIPDisplayModeCompact) {
    return CGRectMake(2 * screenSize.width / 3 ,
                      2 * screenSize.height / 3,
                      screenSize.width / 4,
                      screenSize.height / 5);
  }
  return [super frameForDisplayMode:displayMode];
}

@end
