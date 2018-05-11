//
//  NVPictureInPictureViewController.m
//  NVPictureInPicture
//
//  Created by Nitesh Vijay on 10/05/18.
//

#import "NVPictureInPictureViewController.h"

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

@interface NVPictureInPictureViewController ()

@property (nonatomic) BOOL pictureInPictureActive;
@property (nonatomic) UIPanGestureRecognizer *panGesture;
@property (nonatomic) UITapGestureRecognizer *pipTapGesture;
@property (nonatomic) CGSize pipSize;
@property (nonatomic) CGSize fullScreenSize;
@property (nonatomic) UIEdgeInsets pipEdgeInsets;
@property (nonatomic) CGFloat keyboardHeight;
@property (nonatomic) CGPoint pipCenter;
@property (nonatomic) CGPoint fullScreenCenter;

@end

@implementation NVPictureInPictureViewController

- (void)viewDidLoad {
  [self loadValues];
  self.view.bounds = CGRectMake(0, 0, self.fullScreenSize.width, self.fullScreenSize.height);
  self.view.center = self.fullScreenCenter;
  self.panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
  [self.view addGestureRecognizer:self.panGesture];
  self.pipTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
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
  [self setPIPCenterWithVerticalPosition:bottom horizontalPosition:right];
}

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
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
    if (self.delegate != nil
        && [self.delegate respondsToSelector:@selector(pictureInPictureViewControllerWillStartPictureInPicture:)]) {
      [self.delegate pictureInPictureViewControllerWillStartPictureInPicture:self];
    }
  } else {
    CGPoint translation = [gestureRecognizer translationInView:self.view];
    if (yMultiplier == 0) {
      yMultiplier = translation.y / fabs(translation.y);
      xMultiplier = translation.x / fabs(translation.x);
      xMultiplier = xMultiplier == 0 ? yMultiplier : xMultiplier;
      [self setPIPCenterWithVerticalPosition:yMultiplier horizontalPosition:xMultiplier];
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
      CGFloat velocity = yMultiplier * [gestureRecognizer velocityInView:self.view].y;
      [self setDisplayModeWithTranslationPercentage:percentage velocity:velocity];
    }
  }
}

- (void)handlePanInPictureInPicture:(UIPanGestureRecognizer *)gestureRecognizer {
  if (gestureRecognizer.state == UIGestureRecognizerStateChanged) {
    CGPoint translation = [gestureRecognizer translationInView:self.view];
    [self.panGesture setTranslation:CGPointZero inView:self.view];
    CGPoint center = self.view.center;
    center.x += translation.x;
    center.y += translation.y;
    self.view.center = center;
  } else if (gestureRecognizer.state == UIGestureRecognizerStateEnded
             || gestureRecognizer.state == UIGestureRecognizerStateCancelled
             || gestureRecognizer.state == UIGestureRecognizerStateFailed) {
    CGPoint velocity = [gestureRecognizer velocityInView:self.view];
    CGFloat speed = fabs(velocity.y / (self.fullScreenSize.height - self.pipSize.height));
    [UIView animateWithDuration:AnimationDuration
                          delay:0
         usingSpringWithDamping:AnimationDamping
          initialSpringVelocity:speed
                        options:UIViewAnimationOptionLayoutSubviews
                     animations:^{
                       CGPoint center = self.view.center;
                       center.x += velocity.x * FreeFlowTimeAfterPan;
                       center.y += velocity.y * FreeFlowTimeAfterPan;
                       self.view.center = [self validCenterPoint:center withSize:self.pipSize];;
                     }
                     completion:^(BOOL finished) {
                     }];
  }
}

#pragma mark Helper Methods

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
    [self translateViewToPictureInPictureWithInitialSpeed:speed];
  } else {
    [self stopPictureInPicture];
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
    self.view.center = [self validCenterPoint:self.view.center
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
  } else if(verticalPosition == bottom) {
    center.y = self.fullScreenSize.height - self.pipEdgeInsets.bottom - self.pipSize.height / 2;
  }
  if(horizontalPosition == left) {
    center.x = 0 + self.pipEdgeInsets.left + self.pipSize.width / 2;
  } else if(horizontalPosition == right){
    center.x = self.fullScreenSize.width - self.pipEdgeInsets.right - self.pipSize.width / 2;
  }
  self.pipCenter = center;
}

#pragma mark Tap Gesture Handler

- (void)handleTap:(UIGestureRecognizer *)gestureRecognizer {
  if (self.isPictureInPictureActive) {
    if (self.delegate != nil
        && [self.delegate respondsToSelector:@selector(pictureInPictureViewControllerWillStopPictureInPicture:)]) {
      [self.delegate pictureInPictureViewControllerWillStopPictureInPicture:self];
    }
    [self stopPictureInPicture];
  }
}

#pragma mark Translation Methods

- (void)translateViewToPictureInPictureWithInitialSpeed:(CGFloat)speed {
  self.view.autoresizingMask = UIViewAutoresizingNone;
  __weak typeof(self) weakSelf = self;
  [UIView animateWithDuration:AnimationDuration
                        delay:0
       usingSpringWithDamping:AnimationDamping
        initialSpringVelocity:speed
                      options:UIViewAnimationOptionLayoutSubviews
                   animations:^{
    [weakSelf updateViewWithTranslationPercentage:1.0f];
  }
                   completion:^(BOOL finished) {
    if (finished) {
      [weakSelf.view addGestureRecognizer:self.pipTapGesture];
      weakSelf.pictureInPictureActive = YES;
      if (weakSelf.delegate != nil
          && [weakSelf.delegate respondsToSelector:@selector(pictureInPictureViewControllerDidStartPictureInPicture:)]) {
        [weakSelf.delegate pictureInPictureViewControllerDidStartPictureInPicture:self];
      }
    }
  }];
}

- (void)translateViewToFullScreen {
  [UIApplication.sharedApplication sendAction:@selector(resignFirstResponder) to:nil from:nil forEvent:nil];
  self.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
  
  __weak typeof(self) weakSelf = self;
  [UIView animateWithDuration:AnimationDuration animations:^{
    [weakSelf updateViewWithTranslationPercentage:0.0f];
    [weakSelf.view layoutIfNeeded];
  } completion:^(BOOL finished) {
    if (finished) {
      [weakSelf.view removeGestureRecognizer:self.pipTapGesture];
      weakSelf.pictureInPictureActive = NO;
      if (weakSelf.delegate != nil
          && [weakSelf.delegate respondsToSelector:@selector(pictureInPictureViewControllerDidStopPictureInPicture:)]) {
        [weakSelf.delegate pictureInPictureViewControllerDidStopPictureInPicture:self];
      }
    }
  }];
}

#pragma mark Public Methods

- (void)reload {
  [self loadValues];
  if (self.isPictureInPictureActive) {
    self.view.bounds = CGRectMake(0, 0, self.pipSize.width, self.pipSize.height);
    [self stickPictureInPictureToEdge];
  } else {
    self.view.bounds = CGRectMake(0, 0, self.fullScreenSize.width, self.fullScreenSize.height);
    self.view.center = self.fullScreenCenter;
  }
}

- (void)startPictureInPicture {
  if (self.isPictureInPictureActive) {
    NSLog(@"[NVPictureInPicture] Warning: startPictureInPicture called when view is already in picture-in-picture.");
    return;
  }
  if (self.delegate != nil
      && [self.delegate respondsToSelector:@selector(pictureInPictureViewControllerWillStartPictureInPicture:)]) {
    [self.delegate pictureInPictureViewControllerWillStartPictureInPicture:self];
  }
  [self translateViewToPictureInPictureWithInitialSpeed:0.0f];
}

- (void)stopPictureInPicture {
  if (!self.isPictureInPictureActive) {
    NSLog(@"[NVPictureInPicture] stopPictureInPicture called when view is already in full-screen.");
    return;
  }
  if (self.delegate != nil
      && [self.delegate respondsToSelector:@selector(pictureInPictureViewControllerWillStopPictureInPicture:)]) {
    [self.delegate pictureInPictureViewControllerWillStopPictureInPicture:self];
  }
  [self translateViewToFullScreen];
}

- (void)movePictureInPictureWithOffset:(CGPoint)offset animated:(BOOL)animated {
  
}

#pragma mark Keyboard Handler

- (void)keyboardWillShow:(NSNotification *)notification {
  NSDictionary* info = [notification userInfo];
  self.keyboardHeight = [[info objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue].size.height;
  if (self.isPictureInPictureActive) {
    CGFloat keyboardAnimationDuration = [[info objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    NSInteger keyboardAnimationCurve = [[info objectForKey:UIKeyboardAnimationCurveUserInfoKey] integerValue];
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:keyboardAnimationDuration];
    [UIView setAnimationCurve:keyboardAnimationCurve];
    [UIView setAnimationBeginsFromCurrentState:YES];
    self.view.center = [self validCenterPoint:self.view.center withSize:self.view.bounds.size];
    [UIView commitAnimations];
    
  }
  
}

- (void)keyboardWillHide:(NSNotification *)notification {
  self.keyboardHeight = 0.0f;
}

#pragma mark Rotation Handler

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
  [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
    if (self.isPictureInPictureActive) {
      CGPoint centerRatio = CGPointMake((self.view.center.x - self.pipSize.width / 2) / (self.fullScreenSize.width - self.pipSize.width),
                                        (self.view.center.y - self.pipSize.height / 2) / (self.fullScreenSize.height - self.pipSize.height));
      CGPoint newCenter;
      newCenter.x = centerRatio.x * size.width;
      newCenter.y = centerRatio.y * size.height;
      self.view.center = [self validCenterPoint:newCenter withSize:self.view.bounds.size];
    }
  } completion:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
    [self reload];
  }];
}

@end
