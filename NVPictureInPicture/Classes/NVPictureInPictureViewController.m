//
//  NVPictureInPictureViewController.m
//  NVPictureInPicture
//
//  Created by Nitesh Vijay on 10/05/18.
//

#import "NVPictureInPictureViewController.h"

#define NVAssertMainThread NSAssert([NSThread isMainThread], @"[NVPictureInPicture] NVPictureInPicture should be called from main thread only.")


typedef NS_ENUM(NSInteger, PictureInPictureVerticalPosition) {
  top = -1,
  bottom = 1
};

typedef NS_ENUM(NSInteger, PictureInPictureHorizontalPosition) {
  left = -1,
  right = 1
};

static const CGSize DefaultPictureInPictureSize = {100, 150};
static const UIEdgeInsets DefaultPictureInPictureEdgeInsets = {5,5,5,5};
static const CGFloat PanSensitivity = 1.5f;
static const CGFloat ThresholdTranslationPercentageForPictureInPicture = 0.4;
static const CGFloat AnimationDuration = 0.3f;
static const CGFloat FreeFlowTimeAfterPan = 0.05;
static const CGFloat AnimationDamping = 1.0f;
static const CGFloat PresentationAnimationDuration = 0.5f;
static const CGFloat PresentationAnimationVelocity = 0.5f;

@interface NVPictureInPictureViewController ()

@property (nonatomic) BOOL pictureInPictureActive;
@property (nonatomic) BOOL pictureInPictureEnabled;
@property (nonatomic, getter=isRecognizingGesture) BOOL recognizingGesture;
@property (nonatomic) UIPanGestureRecognizer *panGesture;
@property (nonatomic) CGSize pipSize;
@property (nonatomic) CGSize fullScreenSize;
@property (nonatomic) UIEdgeInsets pipEdgeInsets;
@property (nonatomic) CGFloat keyboardHeight;
@property (nonatomic) CGPoint pipCenter;
@property (nonatomic) CGPoint fullScreenCenter;
@property (nonatomic) CGPoint lastPointBeforeKeyboardToggle;
@property (nonatomic) BOOL noInteractionFlag;

@end

@implementation NVPictureInPictureViewController

- (void)loadView {
  [super loadView];
  [self loadValues];
  self.panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
}

- (void)viewDidLoad {
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(keyboardWillShow:)
                                               name:UIKeyboardWillShowNotification
                                             object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(keyboardWillHide:)
                                               name:UIKeyboardWillHideNotification
                                             object:nil];
  [UIApplication.sharedApplication sendAction:@selector(resignFirstResponder) to:nil from:nil forEvent:nil];
}

- (void)loadValues {
  self.pipEdgeInsets = [self pictureInPictureEdgeInsets];
  self.pipSize = [self pictureInPictureSize];
  self.fullScreenSize = [UIScreen mainScreen].bounds.size;
  self.fullScreenCenter = CGPointMake(self.fullScreenSize.width / 2, self.fullScreenSize.height / 2);
  if (self.isPictureInPictureActive) {
    self.pipCenter = [self validCenterPoint:self.pipCenter withSize:self.pipSize];
  } else {
    [self setPIPCenterWithVerticalPosition:bottom horizontalPosition:right];
  }
}

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark Setter

- (void)setPipCenter:(CGPoint)pipCenter {
  _pipCenter = pipCenter;
  if (self.isPictureInPictureActive) {
    self.view.center = pipCenter;
  }
}


#pragma mark Public Methods

- (void)reloadPictureInPicture {
  NVAssertMainThread;
  [self resetPanGesture];
  [self loadValues];
  [self validateUIForCurrentStateAnimated:YES];
}

- (void)enablePictureInPicture {
  NVAssertMainThread;
  if (self.isPictureInPictureEnabled) {
    NSLog(@"[NVPictureInPicture] Warning: enablePictureInPicture called when Picture in Picture is already enabled.");
    return;
  }
  self.pictureInPictureEnabled = YES;
  [self.view addGestureRecognizer:self.panGesture];
}

- (void)disablePictureInPicture {
  NVAssertMainThread;
  if (!self.isPictureInPictureEnabled) {
    NSLog(@"[NVPictureInPicture] Warning: disablePictureInPicture called when Picture in Picture is already disabled.");
    return;
  }
  self.pictureInPictureEnabled = NO;
  [self.view removeGestureRecognizer:self.panGesture];
}

- (void)startPictureInPictureAnimated:(BOOL)animated {
  NVAssertMainThread;
  [self resetPanGesture];
  if (!self.isPictureInPictureEnabled) {
    NSLog(@"[NVPictureInPicture] Warning: startPictureInPicture called when Picture in Picture is disabled");
    [self validateUIForCurrentStateAnimated:animated];
    return;
  }
  if (self.isPictureInPictureActive) {
    NSLog(@"[NVPictureInPicture] Warning: startPictureInPicture called when view is already in picture-in-picture.");
    [self validateUIForCurrentStateAnimated:animated];
    return;
  }
  if (self.pictureInPictureDelegate != nil
      && [self.pictureInPictureDelegate respondsToSelector:@selector(pictureInPictureViewControllerWillStartPictureInPicture:)]) {
    [self.pictureInPictureDelegate pictureInPictureViewControllerWillStartPictureInPicture:self];
  }
  [self translateViewToPictureInPictureWithInitialSpeed:0.0f animated:animated];
}

- (void)stopPictureInPictureAnimated:(BOOL)animated {
  NVAssertMainThread;
  [self resetPanGesture];
  if (!self.isPictureInPictureActive) {
    NSLog(@"[NVPictureInPicture] stopPictureInPicture called when view is already in full-screen.");
    [self validateUIForCurrentStateAnimated:animated];
    return;
  }
  if (self.pictureInPictureDelegate != nil
      && [self.pictureInPictureDelegate respondsToSelector:@selector(pictureInPictureViewControllerWillStopPictureInPicture:)]) {
    [self.pictureInPictureDelegate pictureInPictureViewControllerWillStopPictureInPicture:self];
  }
  [self translateViewToFullScreenWithInitialSpeed:0.0f animated:animated];
}

#pragma mark Datasource Methods

- (UIEdgeInsets)pictureInPictureEdgeInsets {
  if (@available(iOS 11.0, *)) {
    UIEdgeInsets safeAreaInsets = UIApplication.sharedApplication.keyWindow.safeAreaInsets;
    return UIEdgeInsetsMake(DefaultPictureInPictureEdgeInsets.top + safeAreaInsets.top,
                            DefaultPictureInPictureEdgeInsets.left + safeAreaInsets.left,
                            DefaultPictureInPictureEdgeInsets.bottom + safeAreaInsets.bottom,
                            DefaultPictureInPictureEdgeInsets.right + safeAreaInsets.right);
  }
  return DefaultPictureInPictureEdgeInsets;
}

- (CGSize)pictureInPictureSize {
  return DefaultPictureInPictureSize;
}

#pragma mark Pan Gesture Handler

- (void)handlePan:(UIPanGestureRecognizer *)gestureRecognizer {
  if (self.isPictureInPictureActive) {
    [self handlePanInPictureInPicture:gestureRecognizer];
  } else {
    [self handlePanInFullScreen:gestureRecognizer];
  }
}

- (void)handlePanInFullScreen:(UIPanGestureRecognizer *)gestureRecognizer {
  static NSInteger yMultiplier;
  static NSInteger xMultiplier;
  if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {
    [self.panGesture setTranslation:CGPointZero inView:self.view];
    yMultiplier = 0;
    xMultiplier = 0;
    self.recognizingGesture = YES;
    if (self.pictureInPictureDelegate != nil
        && [self.pictureInPictureDelegate respondsToSelector:@selector(pictureInPictureViewControllerWillStartPictureInPicture:)]) {
      [self.pictureInPictureDelegate pictureInPictureViewControllerWillStartPictureInPicture:self];
    }
  } else {
    CGPoint translation = [gestureRecognizer translationInView:self.view];
    if (yMultiplier == 0 && translation.y != 0) {
      yMultiplier = translation.y / fabs(translation.y);
      xMultiplier = (translation.x == 0
                     ? yMultiplier
                     : (translation.x / fabs(translation.x)));
      [self setPIPCenterWithVerticalPosition:yMultiplier
                          horizontalPosition:xMultiplier];
    }
    CGFloat percentage = fmax(0.0,
                              PanSensitivity * yMultiplier * (translation.y / (self.fullScreenSize.height - self.pipSize.height)));
    if (gestureRecognizer.state == UIGestureRecognizerStateChanged) {
      if (percentage < 1.0) {
        [self updateViewWithTranslationPercentage:percentage];
      } else {
        [self updateViewWithTranslationPercentage:1.0];
      }
    } else if (gestureRecognizer.state == UIGestureRecognizerStateEnded
               || gestureRecognizer.state == UIGestureRecognizerStateCancelled
               || gestureRecognizer.state == UIGestureRecognizerStateFailed) {
      if (self.isRecognizingGesture) {
        self.recognizingGesture = NO;
        CGFloat velocity = yMultiplier * [gestureRecognizer velocityInView:self.view].y;
        [self setDisplayModeWithTranslationPercentage:percentage velocity:velocity];
      }
    }
  }
}

- (void)handlePanInPictureInPicture:(UIPanGestureRecognizer *)gestureRecognizer {
  if (gestureRecognizer.state == UIGestureRecognizerStateChanged) {
    CGPoint translation = [gestureRecognizer translationInView:self.view];
    [self.panGesture setTranslation:CGPointZero inView:self.view];
    self.recognizingGesture = YES;
    CGPoint center = self.view.center;
    center.x += translation.x;
    center.y += translation.y;
    self.pipCenter = center;
  } else if (gestureRecognizer.state == UIGestureRecognizerStateEnded
             || gestureRecognizer.state == UIGestureRecognizerStateCancelled
             || gestureRecognizer.state == UIGestureRecognizerStateFailed) {
    if (self.isRecognizingGesture) {
      self.noInteractionFlag = NO;
      self.recognizingGesture = NO;
      CGPoint velocity = [gestureRecognizer velocityInView:self.view];
      CGFloat speed = fabs(velocity.y / (self.fullScreenSize.height - self.pipSize.height));
      [self animateViewAnimated:YES
                          speed:speed
                 animationBlock:^{
                   CGPoint center = self.view.center;
                   center.x += velocity.x * FreeFlowTimeAfterPan;
                   center.y += velocity.y * FreeFlowTimeAfterPan;
                   self.pipCenter = [self validCenterPoint:center withSize:self.pipSize];
                 } completionBlock:nil];
    }
  }
}

#pragma mark Helper Methods

- (void)resetPanGesture {
  self.recognizingGesture = NO;
  self.panGesture.enabled = NO;
  self.panGesture.enabled = YES;
}

- (void)validateUIForCurrentStateAnimated:(BOOL)animated {
  if (self.isPictureInPictureActive) {
    [self translateViewToPictureInPictureWithInitialSpeed:0.0f animated:animated];
  } else {
    [self translateViewToFullScreenWithInitialSpeed:0.0 animated:animated];
  }
}

- (CGFloat)normalizePercentage:(CGFloat)percentage WithVelocity:(CGFloat)velocity {
  return percentage + (velocity * FreeFlowTimeAfterPan) / (self.fullScreenSize.height - self.pipSize.height);
}

- (CGFloat)normalizeSpeedWithVelocity:(CGFloat)velocity withPercentage:(CGFloat)percentage {
  return fabs(velocity / (self.fullScreenSize.height - self.pipSize.height));
}

- (void)setDisplayModeWithTranslationPercentage:(CGFloat)percentage velocity:(CGFloat)velocity {
  CGFloat speed = [self normalizeSpeedWithVelocity:velocity withPercentage:percentage];
  CGFloat normalizePercentage = [self normalizePercentage:percentage WithVelocity:velocity];
  if (normalizePercentage > ThresholdTranslationPercentageForPictureInPicture) {
    [self translateViewToPictureInPictureWithInitialSpeed:speed animated:YES];
  } else {
    [self translateViewToFullScreenWithInitialSpeed:speed animated:YES];
  }
}

- (void)updateViewWithTranslationPercentage:(CGFloat)percentage {
  CGSize sizeDifference = CGSizeMake(self.fullScreenSize.width - self.pipSize.width,
                                     self.fullScreenSize.height - self.pipSize.height);
  CGPoint centerDifference = CGPointMake(self.fullScreenCenter.x - self.pipCenter.x,
                                         self.fullScreenCenter.y - self.pipCenter.y);
  self.view.bounds = CGRectMake(0,
                                0,
                                self.fullScreenSize.width - sizeDifference.width * percentage,
                                self.fullScreenSize.height - sizeDifference.height * percentage);
  self.view.center = CGPointMake(self.fullScreenCenter.x - centerDifference.x * percentage,
                                 self.fullScreenCenter.y - centerDifference.y * percentage);
}

- (void)stickPictureInPictureToEdge {
  if (!self.isPictureInPictureActive) {
    NSLog(@"[NVPictureInPicture] Warning: stickPictureInPictureToEdge called when Picture-In-Picture is inactive.");
    return;
  }
  [UIView animateWithDuration:AnimationDuration animations:^{
    self.pipCenter = [self validCenterPoint:self.view.center
                                     withSize:self.view.bounds.size];
  }];
}

- (CGPoint)validCenterPoint:(CGPoint)point
                   withSize:(CGSize)size {
  CGSize screenSize = [UIScreen mainScreen].bounds.size;
  if (point.x < screenSize.width / 2) {
    point.x = self.pipEdgeInsets.left + size.width / 2;
  } else {
    point.x = screenSize.width - size.width / 2 - self.pipEdgeInsets.right;
  }
  if (point.y < self.pipEdgeInsets.top + size.height / 2) {
    point.y = self.pipEdgeInsets.top + size.height / 2;
  }else if (point.y > screenSize.height - size.height / 2 - self.pipEdgeInsets.bottom - self.keyboardHeight) {
    point.y = screenSize.height - size.height / 2 - self.pipEdgeInsets.bottom - self.keyboardHeight;
  }
  return point;
}

- (void)setPIPCenterWithVerticalPosition:(PictureInPictureVerticalPosition)verticalPosition
                      horizontalPosition:(PictureInPictureHorizontalPosition)horizontalPosition{
  CGPoint center = CGPointMake(0, 0);
  if(verticalPosition == top) {
    center.y = 0 + self.pipEdgeInsets.top + self.pipSize.height / 2;
  } else {
    center.y = self.fullScreenSize.height - self.pipEdgeInsets.bottom - self.pipSize.height / 2;
  }
  if(horizontalPosition == left) {
    center.x = 0 + self.pipEdgeInsets.left + self.pipSize.width / 2;
  } else {
    center.x = self.fullScreenSize.width - self.pipEdgeInsets.right - self.pipSize.width / 2;
  }
  self.pipCenter = center;
}

#pragma mark Translation Methods

- (void)translateViewToPictureInPictureWithInitialSpeed:(CGFloat)speed animated:(BOOL)animated {
  self.pictureInPictureActive = YES;
  self.view.autoresizingMask = UIViewAutoresizingNone;
  __weak typeof(self) weakSelf = self;
  void(^animationBlock)(void) = ^{
    [weakSelf updateViewWithTranslationPercentage:1.0f];
  };
  void(^completionBlock)(void) = ^{
    if (weakSelf.pictureInPictureDelegate != nil
        && [weakSelf.pictureInPictureDelegate respondsToSelector:@selector(pictureInPictureViewControllerDidStartPictureInPicture:)]) {
      [weakSelf.pictureInPictureDelegate pictureInPictureViewControllerDidStartPictureInPicture:self];
    }
  };
  [self animateViewAnimated:animated speed:speed animationBlock:animationBlock completionBlock:completionBlock];
}

- (void)translateViewToFullScreenWithInitialSpeed:(CGFloat)speed animated:(BOOL)animated {
  self.pictureInPictureActive = NO;
  [UIApplication.sharedApplication sendAction:@selector(resignFirstResponder) to:nil from:nil forEvent:nil];
  self.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
  
  __weak typeof(self) weakSelf = self;
  void(^animationBlock)(void) = ^{
    [weakSelf updateViewWithTranslationPercentage:0.0f];
  };
  void(^completionBlock)(void) = ^{
    if (weakSelf.pictureInPictureDelegate != nil
        && [weakSelf.pictureInPictureDelegate respondsToSelector:@selector(pictureInPictureViewControllerDidStopPictureInPicture:)]) {
      [weakSelf.pictureInPictureDelegate pictureInPictureViewControllerDidStopPictureInPicture:self];
    }
  };
  [self animateViewAnimated:animated speed:speed animationBlock:animationBlock completionBlock:completionBlock];
}

- (void)animateViewAnimated:(BOOL)animated speed:(CGFloat)speed animationBlock:(void (^)(void))animationBlock completionBlock:(void (^)(void))completionBlock {
  if (animated) {
    [UIView animateWithDuration:AnimationDuration
                          delay:0
         usingSpringWithDamping:AnimationDamping
          initialSpringVelocity:speed
                        options:UIViewAnimationOptionLayoutSubviews | UIViewAnimationCurveEaseInOut
                     animations:animationBlock
                     completion:^(BOOL finished) {
                       (finished
                        ? (completionBlock != nil ? completionBlock() : nil)
                        : [self validateUIForCurrentStateAnimated:animated]);
                     }];
  } else {
    animationBlock != nil ? animationBlock() : nil;
    completionBlock != nil ? completionBlock() : nil;
  }
}

#pragma mark Keyboard Handler

- (void)animateWithKeyboardInfoDictionary:(NSDictionary *)info animations:(void (^)(void))animations {
  CGFloat keyboardAnimationDuration = [[info objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
  NSInteger keyboardAnimationCurve = [[info objectForKey:UIKeyboardAnimationCurveUserInfoKey] integerValue];
  [UIView beginAnimations:nil context:NULL];
  [UIView setAnimationDuration:keyboardAnimationDuration];
  [UIView setAnimationCurve:keyboardAnimationCurve];
  [UIView setAnimationBeginsFromCurrentState:YES];
  animations();
  [UIView commitAnimations];
}

- (void)keyboardWillShow:(NSNotification *)notification {
  NSDictionary* info = [notification userInfo];
  self.keyboardHeight = [[info objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue].size.height;
  if (self.isPictureInPictureActive) {
    self.lastPointBeforeKeyboardToggle = self.view.center;
    self.noInteractionFlag = YES;
    [self animateWithKeyboardInfoDictionary:info animations:^{
      self.pipCenter = [self validCenterPoint:self.view.center withSize:self.view.bounds.size];
    }];
  }
}

- (void)keyboardWillHide:(NSNotification *)notification {
  self.keyboardHeight = 0.0f;
  NSDictionary* info = [notification userInfo];
  if (self.isPictureInPictureActive && self.noInteractionFlag) {
    [self animateWithKeyboardInfoDictionary:info animations:^{
      self.pipCenter = [self validCenterPoint:self.lastPointBeforeKeyboardToggle withSize:self.view.bounds.size];
    }];
    self.noInteractionFlag = NO;
  }
}

#pragma mark Rotation Handler

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
  self.noInteractionFlag = NO;
  [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
    if (self.isPictureInPictureActive) {
      CGPoint originRatio = CGPointMake((self.view.frame.origin.x - self.pipEdgeInsets.left)
                                        / (self.fullScreenSize.width - self.pipSize.width - self.pipEdgeInsets.left - self.pipEdgeInsets.right),
                                        (self.view.frame.origin.y - self.pipEdgeInsets.top)
                                        / (self.fullScreenSize.height - self.pipSize.height - self.pipEdgeInsets.top - self.pipEdgeInsets.bottom));
      [self reloadPictureInPicture];
      CGPoint newCenter;
      newCenter.x = self.pipEdgeInsets.left + self.pipSize.width / 2 + originRatio.x * (size.width - self.pipSize.width - self.pipEdgeInsets.left - self.pipEdgeInsets.right);
      newCenter.y = self.pipEdgeInsets.top + self.pipSize.height / 2 + originRatio.y * (size.height - self.pipSize.height - self.pipEdgeInsets.top - self.pipEdgeInsets.bottom);
      self.pipCenter = [self validCenterPoint:newCenter withSize:self.view.bounds.size];
    }
  } completion:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
    [self reloadPictureInPicture];
  }];
}

# pragma mark Presentor

- (void)presentPictureInPictureViewControllerOnWindow:(UIWindow *)window animated:(BOOL)animated completion:(void (^ _Nullable)(void))completion {
  NVAssertMainThread;
  self.view.frame = CGRectMake(0,
                               self.fullScreenSize.height,
                               self.fullScreenSize.width,
                               self.fullScreenSize.height);
  [window addSubview:self.view];
  void(^animationBlock)(void) = ^{
    self.view.frame = CGRectMake(0,
                                 0,
                                 self.fullScreenSize.width,
                                 self.fullScreenSize.height);
  };
  void(^completionBlock)(void) = ^{
    [window.rootViewController addChildViewController:self];
    [self didMoveToParentViewController:window.rootViewController];
    if (completion != NULL) {
      completion();
    }
  };
  if (animated) {
    [UIView animateWithDuration:PresentationAnimationDuration
                          delay:0.0f
         usingSpringWithDamping:AnimationDamping
          initialSpringVelocity:PresentationAnimationVelocity
                        options:UIViewAnimationOptionCurveEaseIn
                     animations:^{
                       animationBlock();
                     } completion:^(BOOL finished) {
                       completionBlock();
                     }];
  } else {
    animationBlock();
    completionBlock();
  }
}

- (void)dismissPictureInPictureViewControllerAnimated:(BOOL)animated completion:(void (^ __nullable)(void))completion {
  NVAssertMainThread;
  [self viewWillDisappear:YES];
  __weak typeof(self) weakSelf = self;
  void(^animationBlock)(void) = ^{
    self.view.frame = CGRectMake(self.view.frame.origin.x,
                                 self.fullScreenSize.height,
                                 self.view.frame.size.width,
                                 self.view.frame.size.height);
  };
  void(^completionBlock)(void) = ^{
    [weakSelf.view removeFromSuperview];
    [weakSelf viewDidDisappear:YES];
    [weakSelf removeFromParentViewController];
    if (completion != NULL) {
      completion();
    }
  };
  if (animated) {
    [UIView animateWithDuration:PresentationAnimationDuration
                          delay:0.0f
         usingSpringWithDamping:AnimationDamping
          initialSpringVelocity:PresentationAnimationVelocity
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
                       animationBlock();
                     } completion:^(BOOL finished) {
                       completionBlock();
                     }];
  } else {
    animationBlock();
    completionBlock();
  }
}

@end
