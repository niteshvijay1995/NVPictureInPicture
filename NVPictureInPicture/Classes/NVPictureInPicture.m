//
//  NVPictureInPicture.m
//  NVPictureInPicture
//
//  Created by Nitesh Vijay on 02/05/18.
//

#import "NVPictureInPicture.h"
#import "NVPictureInPictureViewController.h"

@interface NVPictureInPicture()

@property (nonatomic) NVPictureInPictureViewController *pictureInPictureViewController;

@end

@implementation NVPictureInPicture

- (void)presentNVPictureInPictureViewController:(NVPictureInPictureViewController *)pictureInPictureViewController {
  if (self.pictureInPictureViewController != nil) {
    [self dismissPresentedViewControllerWithCompletion:nil];
  }
  self.pictureInPictureViewController = pictureInPictureViewController;
  [UIApplication.sharedApplication.keyWindow addSubview:self.pictureInPictureViewController.view];
  [UIApplication.sharedApplication.keyWindow.rootViewController addChildViewController:self.pictureInPictureViewController];
}

- (void)dismissPresentedViewControllerWithCompletion: (void (^ __nullable)(void))completion {
  [self.pictureInPictureViewController.view removeFromSuperview];
  self.pictureInPictureViewController = nil;
  if (completion != NULL) {
    completion();
  }
}

- (void)dealloc {
  [self dismissPresentedViewControllerWithCompletion:nil];
}

@end
