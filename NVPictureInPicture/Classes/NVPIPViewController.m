//
//  NVPIPViewController.m
//  NVPictureInPicture
//
//  Created by Nitesh Vijay on 02/05/18.
//

#import "NVPIPViewController.h"

static const CGSize DefaultSizeInCompactMode = {100, 150};
static const CGFloat PanSensitivity = 1.5f;
static const CGFloat ThresholdPercentForDisplayModeCompact = 0.5;
static const CGFloat AnimationDuration = 0.2f;

@interface NVPIPViewController()

@property (nonatomic) NVPIPDisplayMode displayMode;
@property (nonatomic) UIPanGestureRecognizer *panGesture;
@property (nonatomic) UITapGestureRecognizer *tapGesture;
@property (nonatomic) CGRect compactModeFrame;
@property (nonatomic) CGRect expandedModeFrame;
@property (nonatomic) UIEdgeInsets edgeInsets;

@end

@implementation NVPIPViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  self.edgeInsets = [self edgeInsetsForDisplayModeCompact];
  self.compactModeFrame = [self frameForDisplayMode:NVPIPDisplayModeCompact];
  self.compactModeFrame = [self validFrameForCompactDisplayModeFrame:self.compactModeFrame];
  self.expandedModeFrame = [self frameForDisplayMode:NVPIPDisplayModeExpanded];
  self.panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
  [self.view addGestureRecognizer:self.panGesture];
  self.tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
  [self setDisplayMode:NVPIPDisplayModeExpanded animated:NO];
}

- (CGRect)frameForDisplayMode:(NVPIPDisplayMode)displayMode {
  CGSize screenSize = [UIScreen mainScreen].bounds.size;
  if (displayMode == NVPIPDisplayModeCompact) {
    return CGRectMake(screenSize.width - self.edgeInsets.right - DefaultSizeInCompactMode.width,
                      screenSize.height - self.edgeInsets.bottom - DefaultSizeInCompactMode.height,
                      DefaultSizeInCompactMode.width,
                      DefaultSizeInCompactMode.height);
  } else {
    return CGRectMake(0,
                      0,
                      screenSize.width,
                      screenSize.height);
  }
}

- (UIEdgeInsets)edgeInsetsForDisplayModeCompact {
  return UIEdgeInsetsMake(10, 10, 10, 10);
}

- (void)handlePan:(UIGestureRecognizer *)gestureRecognizer {
  if (self.displayMode == NVPIPDisplayModeExpanded) {
    [self handlePanForDisplayModeExpanded:(UIPanGestureRecognizer *)gestureRecognizer];
  } else if (self.displayMode == NVPIPDisplayModeCompact) {
    [self handlePanForDisplayModeCompact:(UIPanGestureRecognizer *)gestureRecognizer];
  }
}

- (void)handlePanForDisplayModeExpanded:(UIPanGestureRecognizer *)gestureRecognizer {
  if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {
    [self.panGesture setTranslation:CGPointZero inView:self.view];
    if (self.delegate != nil
        && [self.delegate respondsToSelector:@selector(pipViewController:willChangeToDisplayMode:)]) {
      [self.delegate pipViewController:self willChangeToDisplayMode:NVPIPDisplayModeCompact];
    }
  } else {
    CGPoint translation = [gestureRecognizer translationInView:self.view];
    CGFloat percentage = PanSensitivity * fabs(translation.y / (CGRectGetHeight(self.expandedModeFrame) - CGRectGetHeight(self.compactModeFrame)));
    if (gestureRecognizer.state == UIGestureRecognizerStateChanged
        && percentage <= 1) {
      [self updateViewWithTranslationPercentage:percentage];
    } else if (gestureRecognizer.state == UIGestureRecognizerStateEnded
               || gestureRecognizer.state == UIGestureRecognizerStateCancelled
               || gestureRecognizer.state == UIGestureRecognizerStateFailed) {
      [self setDisplayModeWithTranslationPercentage:percentage];
    }
  }
}

- (void)handlePanForDisplayModeCompact:(UIPanGestureRecognizer *)gestureRecognizer {
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
    [self stickCompactViewToEdge];
  }
}

- (void)updateViewWithTranslationPercentage:(CGFloat)percentage {
  CGSize sizeDifference = CGSizeMake(CGRectGetWidth(self.expandedModeFrame) - CGRectGetWidth(self.compactModeFrame),
                                     CGRectGetHeight(self.expandedModeFrame) - CGRectGetHeight(self.compactModeFrame));
  CGPoint originDifference = CGPointMake(CGRectGetMinX(self.expandedModeFrame) - CGRectGetMinX(self.compactModeFrame),
                                         CGRectGetMinY(self.expandedModeFrame) - CGRectGetMinY(self.compactModeFrame));
  self.view.frame = CGRectMake(CGRectGetMinX(self.expandedModeFrame) - originDifference.x * percentage,
                               CGRectGetMinY(self.expandedModeFrame) - originDifference.y * percentage,
                               CGRectGetWidth(self.expandedModeFrame) - sizeDifference.width * percentage,
                               CGRectGetHeight(self.expandedModeFrame) - sizeDifference.height * percentage);
}

- (void)setDisplayModeWithTranslationPercentage:(CGFloat)percentage {
  if (percentage > ThresholdPercentForDisplayModeCompact) {
    [self setDisplayMode:NVPIPDisplayModeCompact animated:YES];
  } else {
    [self setDisplayMode:NVPIPDisplayModeExpanded animated:YES];
  }
}

- (void)setDisplayMode:(NVPIPDisplayMode)displayMode animated:(BOOL)animated {
  if (self.delegate != nil
      && [self.delegate respondsToSelector:@selector(pipViewController:willChangeToDisplayMode:)]) {
    [self.delegate pipViewController:self willChangeToDisplayMode:displayMode];
  }
  __block CGRect newFrame;
  switch (displayMode) {
    case NVPIPDisplayModeCompact:
      self.displayMode = NVPIPDisplayModeCompact;
      newFrame = self.compactModeFrame;
      [self.view addGestureRecognizer:self.tapGesture];
      break;
    case NVPIPDisplayModeExpanded:
      self.displayMode = NVPIPDisplayModeExpanded;
      newFrame = self.expandedModeFrame;
      [self.view removeGestureRecognizer:self.tapGesture];
      break;
  }
  if (animated) {
    [UIView animateWithDuration:AnimationDuration
                     animations:^{
                       self.view.frame = newFrame;
                     } completion:^(BOOL finished) {
                       if (finished
                           && self.delegate != nil
                           && [self.delegate respondsToSelector:@selector(pipViewController:didChangeToDisplayMode:)]) {
                         [self.delegate pipViewController:self didChangeToDisplayMode:displayMode];
                       }
                     }];
  } else {
    self.view.frame = newFrame;
    if (self.delegate != nil
        && [self.delegate respondsToSelector:@selector(pipViewController:didChangeToDisplayMode:)]) {
      [self.delegate pipViewController:self didChangeToDisplayMode:displayMode];
    }
  }
}

- (void)stickCompactViewToEdge {
  if (self.displayMode == NVPIPDisplayModeExpanded) {
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
    point.x = self.edgeInsets.left + size.width / 2;
  } else {
    point.x = screenSize.width - size.width / 2 - self.edgeInsets.right;
  }
  if (point.y < self.edgeInsets.top + size.height / 2) {
    point.y = self.edgeInsets.top + size.height / 2;
  }else if (point.y > screenSize.height - size.height / 2 - self.edgeInsets.bottom) {
    point.y = screenSize.height - size.height / 2 - self.edgeInsets.bottom;
  }
  return point;
}

- (CGRect)validFrameForCompactDisplayModeFrame:(CGRect)frame {
  CGPoint newCenter = [self validCenterPoint:CGPointMake(CGRectGetMidX(frame), CGRectGetMidY(frame))
                                    withSize:frame.size];
  frame.origin = CGPointMake(newCenter.x - frame.size.width / 2,
                             newCenter.y - frame.size.height / 2);
  return frame;
}

- (void)handleTap:(UIGestureRecognizer *)gestureRecognizer {
  if (self.displayMode == NVPIPDisplayModeCompact) {
    if (self.delegate != nil
        && [self.delegate respondsToSelector:@selector(pipViewController:willChangeToDisplayMode:)]) {
      [self.delegate pipViewController:self willChangeToDisplayMode:NVPIPDisplayModeExpanded];
    }
    [self setDisplayMode:NVPIPDisplayModeExpanded animated:YES];
  }
}

- (BOOL)shouldReceivePoint:(CGPoint)point {
  return CGRectContainsPoint(self.view.frame, point);
}

@end
