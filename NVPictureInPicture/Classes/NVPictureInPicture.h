//
//  NVPictureInPicture.h
//  NVPictureInPicture
//
//  Created by Nitesh Vijay on 02/05/18.
//

#import <Foundation/Foundation.h>

@class NVPictureInPictureViewController;

@interface NVPictureInPicture : NSObject

/*!
 @method    presentNVPictureInPictureViewController:
 @param     pictureInPictureViewController
 The Picture in Picture view controller.
 @abstract  Present NVPictureInPictureViewController on key window.
 */
- (void)presentNVPictureInPictureViewController:(NVPictureInPictureViewController *)pictureInPictureViewController;

/*!
 @method    dismissPresentedViewControllerWithCompletion:
 @param     completion
 Completion block called on succcessful dismiss.
 @abstract  Dismiss NVPictureInPictureViewController.
 */
- (void)dismissPresentedViewControllerWithCompletion: (void (^ __nullable)(void))completion;

@end
