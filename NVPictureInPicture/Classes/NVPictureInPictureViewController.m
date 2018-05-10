//
//  NVPictureInPictureViewController.m
//  NVPictureInPicture
//
//  Created by Nitesh Vijay on 10/05/18.
//

#import "NVPictureInPictureViewController.h"

typedef NS_ENUM(NSInteger, PictureInPictureVerticalPosition) {
  top,
  bottom
};

typedef NS_ENUM(NSInteger, PictureInPictureHorizontalPosition) {
  left,
  right
};

static const CGSize DefaultPictureInPictureSize = {100, 150};
static const UIEdgeInsets DefaultPictureInPictureEdgeInsets = {5,5,5,5};
static const CGFloat PanSensitivity = 1.5f;
static const CGFloat ThresholdTranslationPercentageForPictureInPicture = 0.5;
static const CGFloat AnimationDuration = 0.2f;

@interface NVPictureInPictureViewController ()

@property (nonatomic) BOOL pictureInPictureActive;
@property (nonatomic) UIPanGestureRecognizer *panGesture;
@property (nonatomic) UITapGestureRecognizer *tapGesture;
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
  self.tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(keyboardDidShow:)
                                               name:UIKeyboardDidShowNotification
                                             object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(keyboardDidHide:)
                                               name:UIKeyboardDidHideNotification
                                             object:nil];
}

- (void)loadValues {
  self.pipEdgeInsets = [self pictureInPictureEdgeInsets];
  self.pipSize = [self pictureInPictureSize];
  self.fullScreenSize = [UIScreen mainScreen].bounds.size;
  self.fullScreenCenter = CGPointMake(self.fullScreenSize.width / 2, self.fullScreenSize.height / 2);
  [self setPIPCenterWithVerticalPosition:bottom horizontalPosition:right];
}

- (void)reload {
  [self loadValues];
}

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

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


- (void)handlePan:(UIPanGestureRecognizer *)gestureRecognizer {
  if (self.isPictureInPictureActive) {
    [self handlePanInPictureInPicture:gestureRecognizer];
  } else {
    [self handlePanInFullScreen:gestureRecognizer];
  }
}

- (void)handlePanInFullScreen:(UIPanGestureRecognizer *)gestureRecognizer {
  if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {
    [self.panGesture setTranslation:CGPointZero inView:self.view];
    if (self.delegate != nil
        && [self.delegate respondsToSelector:@selector(pictureInPictureViewControllerWillStartPictureInPicture:)]) {
      [self.delegate pictureInPictureViewControllerWillStartPictureInPicture:self];
    }
  } else {
    CGPoint translation = [gestureRecognizer translationInView:self.view];
    CGFloat percentage = PanSensitivity * fabs(translation.y / (self.fullScreenSize.height - self.pipSize.height));
    if (gestureRecognizer.state == UIGestureRecognizerStateChanged) {
      if (percentage < 1.0) {
        [self updateViewWithTranslationPercentage:percentage];
      } else {
        [self updateViewWithTranslationPercentage:1.0];
      }
    } else if (gestureRecognizer.state == UIGestureRecognizerStateEnded
               || gestureRecognizer.state == UIGestureRecognizerStateCancelled
               || gestureRecognizer.state == UIGestureRecognizerStateFailed) {
      [self setDisplayModeWithTranslationPercentage:percentage];
    }
  }
}

- (void)setDisplayModeWithTranslationPercentage:(CGFloat)percentage {
  if (percentage > ThresholdTranslationPercentageForPictureInPicture) {
    [self startPictureInPicture];
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
    [self stickPictureInPictureToEdge];
  }
}

- (void)stickPictureInPictureToEdge {
  if (!self.isPictureInPictureActive) {
    NSLog(@"Warning: stickPictureInPictureToEdge called when Picture-In-Picture is inactive.");
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

- (void)handleTap:(UIGestureRecognizer *)gestureRecognizer {
  if (self.isPictureInPictureActive) {
    if (self.delegate != nil
        && [self.delegate respondsToSelector:@selector(pictureInPictureViewControllerWillStopPictureInPicture:)]) {
      [self.delegate pictureInPictureViewControllerWillStopPictureInPicture:self];
    }
    [self stopPictureInPicture];
  }
}

- (void)startPictureInPicture {
  if (self.delegate != nil
      && [self.delegate respondsToSelector:@selector(pictureInPictureViewControllerWillStartPictureInPicture:)]) {
    [self.delegate pictureInPictureViewControllerWillStartPictureInPicture:self];
  }
  __weak typeof(self) weakSelf = self;
  [UIView animateWithDuration:AnimationDuration animations:^{
    [weakSelf updateViewWithTranslationPercentage:1.0f];
  } completion:^(BOOL finished) {
    if (finished) {
      [weakSelf.view addGestureRecognizer:self.tapGesture];
      weakSelf.pictureInPictureActive = YES;
      if (weakSelf.delegate != nil
          && [weakSelf.delegate respondsToSelector:@selector(pictureInPictureViewControllerDidStartPictureInPicture:)]) {
        [weakSelf.delegate pictureInPictureViewControllerDidStartPictureInPicture:self];
      }
    }
  }];
}

- (void)stopPictureInPicture {
  if (self.delegate != nil
      && [self.delegate respondsToSelector:@selector(pictureInPictureViewControllerWillStopPictureInPicture:)]) {
    [self.delegate pictureInPictureViewControllerWillStopPictureInPicture:self];
  }
  __weak typeof(self) weakSelf = self;
  [UIView animateWithDuration:AnimationDuration animations:^{
    [weakSelf updateViewWithTranslationPercentage:0.0f];
  } completion:^(BOOL finished) {
    if (finished) {
      [weakSelf.view removeGestureRecognizer:self.tapGesture];
      weakSelf.pictureInPictureActive = NO;
      if (weakSelf.delegate != nil
          && [weakSelf.delegate respondsToSelector:@selector(pictureInPictureViewControllerDidStopPictureInPicture:)]) {
        [weakSelf.delegate pictureInPictureViewControllerDidStopPictureInPicture:self];
      }
    }
  }];
}

- (void)movePictureInPictureWithOffset:(CGPoint)offset animated:(BOOL)animated {
  
}

- (void)keyboardDidShow:(NSNotification *)notification {
  NSDictionary* info = [notification userInfo];
  self.keyboardHeight = [[info objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue].size.height;
  [self stickPictureInPictureToEdge];
}

- (void)keyboardDidHide:(NSNotification *)notification {
  self.keyboardHeight = 0.0f;
}

@end
