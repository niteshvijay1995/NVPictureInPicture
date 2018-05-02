//
//  NVPictureInPicture.m
//  NVPictureInPicture
//
//  Created by Nitesh Vijay on 02/05/18.
//

#import "NVPictureInPicture.h"
#import "NVPIPWindow.h"
#import "NVPIPViewController.h"

@interface NVPictureInPicture() <NVPIPWindowDelegate>

@property (nonatomic) NVPIPWindow *window;
@property (nonatomic) NVPIPViewController *viewController;

@end

@implementation NVPictureInPicture

- (void)presentNVPIPViewController:(NVPIPViewController *)viewController {
  self.window = [[NVPIPWindow alloc] initWithFrame:[UIScreen mainScreen].bounds windowLevel:CGFLOAT_MAX];
  self.viewController = viewController;
  self.window.rootViewController = self.viewController;
  self.window.delegate = self;
  [self makeWindowVisible];
}

- (void)dismissPresentedViewControllerWithCompletion: (void (^ __nullable)(void))completion {
  self.window.delegate = nil;
  self.window = nil;
  self.viewController = nil;
  completion();
}

- (void)makeWindowVisible {
  UIWindow *keyWindow = [UIApplication sharedApplication].keyWindow;
  [self.window makeKeyAndVisible];
  if (keyWindow) {
    [keyWindow makeKeyWindow];
  }
}

#pragma mark - NVPIPWindowDelegate

- (BOOL)isEventPoint:(CGPoint)point {
  return [self.viewController shouldReceivePoint:point];
}

@end
