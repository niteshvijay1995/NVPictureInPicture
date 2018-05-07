//
//  NVPIPSubViewController.m
//  NVPictureInPicture_Example
//
//  Created by Nitesh Vijay on 03/05/18.
//  Copyright © 2018 niteshvijay1995. All rights reserved.
//

#import "NVPIPSubViewController.h"

static const CGFloat EdgeInset = 5;

@interface NVPIPSubViewController () <NVPIPViewControllerDelegate>

@property (weak, nonatomic) IBOutlet UIButton *closeButton;
@property (weak, nonatomic) IBOutlet UIButton *backButton;

@end

@implementation NVPIPSubViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  self.view.clipsToBounds = YES;
  self.delegate = self;
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(keyboardDidShow:)
                                               name:UIKeyboardDidShowNotification
                                             object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(keyboardDidHide:)
                                               name:UIKeyboardDidHideNotification
                                             object:nil];
  self.compactModeEdgeInsets = [self edgeInsetsWithKeyboardHeight:0.0f];
}

- (UIEdgeInsets)edgeInsetsWithKeyboardHeight:(CGFloat)keyboardHeight {
  UIEdgeInsets safeAreaInsets;
  if (@available(iOS 11.0, *)) {
    safeAreaInsets = [UIApplication sharedApplication].keyWindow.safeAreaInsets;
  } else {
    safeAreaInsets = UIEdgeInsetsMake(0, 0, 0, 0);
  }
  return UIEdgeInsetsMake(EdgeInset + safeAreaInsets.top,
                          EdgeInset + safeAreaInsets.left,
                          EdgeInset + safeAreaInsets.bottom + keyboardHeight,
                          EdgeInset + safeAreaInsets.right);
}

- (CGRect)frameForDisplayMode:(NVPIPDisplayMode)displayMode {
  CGSize screenSize = [UIScreen mainScreen].bounds.size;
  if (displayMode == NVPIPDisplayModeCompact) {
    return CGRectMake(2 * screenSize.width / 3 ,
                      2 * screenSize.height / 3,
                      100,
                      150);
  }
  return [super frameForDisplayMode:displayMode];
}

- (void)pipViewController:(NVPIPViewController *)viewController willStartTransitionToDisplayMode:(NVPIPDisplayMode)displayMode {
  if (displayMode == NVPIPDisplayModeCompact) {
    self.closeButton.alpha = 0;
    self.backButton.alpha = 0;
  }
}

- (void)pipViewController:(NVPIPViewController *)viewController didChangeToDisplayMode:(NVPIPDisplayMode)displayMode {
  if (displayMode == NVPIPDisplayModeExpanded) {
    self.closeButton.alpha = 1;
    self.backButton.alpha = 1;
  }
}

- (IBAction)back:(id)sender {
  self.closeButton.alpha = 0;
  self.backButton.alpha = 0;
  [self setDisplayMode:NVPIPDisplayModeCompact animated:YES];
}

- (IBAction)close:(id)sender {
  self.closeBlock();
}

- (void)keyboardDidShow:(NSNotification *)notification {
  NSDictionary* info = [notification userInfo];
  CGSize kbSize = [[info objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue].size;
  self.compactModeEdgeInsets = [self edgeInsetsWithKeyboardHeight:kbSize.height];
  [self stickCompactViewToEdge];
}

- (void)keyboardDidHide:(NSNotification *)notification {
  self.compactModeEdgeInsets = [self edgeInsetsWithKeyboardHeight:0.0f];
  [self stickCompactViewToEdge];
}

@end
