//
//  NVPictureInPictureViewController.m
//  NVPictureInPicture
//
//  Created by Nitesh Vijay on 10/05/18.
//

#import "NVPictureInPictureViewController.h"

#define NVAssertMainThread NSAssert([NSThread isMainThread], @"[NVPictureInPicture] NVPictureInPicture should be called from main thread only.")

static const CGFloat PresentationAnimationDuration = 0.5f;
static const CGFloat PresentationAnimationVelocity = 0.5f;

@interface NVPictureInPictureViewController ()

@end

@implementation NVPictureInPictureViewController

- (void)loadView {
  self.pictureInPictureView = [[NVPictureInPictureView alloc] initWithFrame:UIScreen.mainScreen.applicationFrame];
  self.view = self.pictureInPictureView;
}

#pragma mark Rotation Handler

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
  [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
    if (self.pictureInPictureView.isPictureInPictureActive) {
      [self.pictureInPictureView handleRotationToSize:size];
    }
  } completion:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
    [self.pictureInPictureView reload];
  }];
}

# pragma mark Presentor

- (void)presentPictureInPictureViewControllerOnWindow:(UIWindow *)window animated:(BOOL)animated completion:(void (^ _Nullable)(void))completion {
  NVAssertMainThread;
  [UIApplication.sharedApplication sendAction:@selector(resignFirstResponder) to:nil from:nil forEvent:nil];
  CGPoint center = window.center;
  center.y += window.bounds.size.height;
  self.pictureInPictureView.center = center;
  [window addSubview:self.view];
  void(^animationBlock)(void) = ^{
    self.pictureInPictureView.center = window.center;
  };
  void(^completionBlock)(void) = ^{
    [window.rootViewController addChildViewController:self];
    if (completion != NULL) {
      completion();
    }
  };
  if (animated) {
    [UIView animateWithDuration:PresentationAnimationDuration
                          delay:0.0f
         usingSpringWithDamping:1.0f
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
    CGPoint center = self.pictureInPictureView.superview.center;
    center.y += self.pictureInPictureView.superview.bounds.size.height;
    self.pictureInPictureView.center = center;
  };
  void(^completionBlock)(void) = ^{
    [weakSelf.pictureInPictureView removeFromSuperview];
    [weakSelf viewDidDisappear:YES];
    [weakSelf removeFromParentViewController];
    if (completion != NULL) {
      completion();
    }
  };
  if (animated) {
    [UIView animateWithDuration:PresentationAnimationDuration
                          delay:0.0f
         usingSpringWithDamping:1.0f
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
