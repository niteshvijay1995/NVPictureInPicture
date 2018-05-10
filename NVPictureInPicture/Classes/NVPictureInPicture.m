//
//  NVPictureInPicture.m
//  NVPictureInPicture
//
//  Created by Nitesh Vijay on 02/05/18.
//

#import "NVPictureInPicture.h"
#import "NVPictureInPictureViewController.h"

@interface NVPictureInPicture()

@property (nonatomic) NVPictureInPictureViewController *viewController;

@end

@implementation NVPictureInPicture

- (void)presentNVPIPViewController:(NVPictureInPictureViewController *)viewController {
  if (self.viewController != nil) {
    [self dismissPresentedViewControllerWithCompletion:nil];
  }
  self.viewController = viewController;
  [UIApplication.sharedApplication.keyWindow addSubview:self.viewController.view];
  [UIApplication.sharedApplication.keyWindow.rootViewController addChildViewController:self.viewController];
}

- (void)dismissPresentedViewControllerWithCompletion: (void (^ __nullable)(void))completion {
  [self.viewController.view removeFromSuperview];
  self.viewController = nil;
  if (completion != NULL) {
    completion();
  }
}

@end
