//
//  NVPictureInPictureViewController.h
//  NVPictureInPicture
//
//  Created by Nitesh Vijay on 10/05/18.
//

#import <UIKit/UIKit.h>
#import <NVPictureInPictureView.h>

@protocol NVPictureInPictureViewControllerDelegate;

/*!
 @class    NVPictureInPictureViewController
 @abstract  NVPictureInPictureViewController is a subclass of UIViewController that can be used to present the contents floating on top of application. Subclass this class to create view controller supporting Picture in Picture. Picture in Picture can be activated either with a pan gesture or by calling -startPictureInPicture.
 @note     Picture in Picture is disabled by default. Call -enablePictureInPicture to enable it.
 */
@interface NVPictureInPictureViewController : UIViewController

@property (nonatomic) NVPictureInPictureView *pictureInPictureView;

/*!
 @method    presentPictureInPictureViewControllerOnWindow:animated:completion
 @param     window
 Window of the application where the view is to be added as subview.
 @method    animated
 Presented modally if animated is true.
 @param     completion
 The completion handler, if provided, will be invoked after the presented controller's viewDidAppear: callback is invoked.
 @abstract  Present NVPictureInPictureViewController
 @discussion  The view will be presented modally. The view controller will be added as a child of rootViewController of window
 */
- (void)presentPictureInPictureViewControllerOnWindow:(UIWindow *)window animated:(BOOL)animated completion:(void (^ _Nullable)(void))completion;

/*!
 @method    dismiss
 @param     animated
 Dismissed modally if animated is true.
 @param     completion
 The completion handler, if provided, will be invoked after the dismissed controller's viewDidDisappear: callback is invoked.
 @abstract  Dismiss NVPictureInPictureViewController
 @discussion  The view will be dismissed modally. The view and the controller will be removed from the parent.
 */
- (void)dismissPictureInPictureViewControllerAnimated:(BOOL)animated completion:(void (^ __nullable)(void))completion;

@end

/*!
 @protocol  NVPictureInPictureViewControllerDelegate
 @abstract  A protocol for delegates of NVPictureInPictureViewController.
 */
@protocol NVPictureInPictureViewControllerDelegate <NSObject>

@optional

/*!
 @method    pictureInPictureViewControllerWillStartPictureInPicture:
 @param    pictureInPictureViewController
 The Picture in Picture view controller.
 @abstract  Delegate can implement this method to be notified when Picture in Picture will start.
 */
- (void)pictureInPictureViewControllerWillStartPictureInPicture:(NVPictureInPictureViewController *)pictureInPictureViewController;

/*!
 @method    pictureInPictureViewControllerDidStartPictureInPicture:
 @param    pictureInPictureViewController
 The Picture in Picture controller.
 @abstract  Delegate can implement this method to be notified when Picture in Picture did start.
 */
- (void)pictureInPictureViewControllerDidStartPictureInPicture:(NVPictureInPictureViewController *)pictureInPictureViewController;

/*!
 @method    pictureInPictureViewControllerWillStopPictureInPicture:
 @param    pictureInPictureViewController
 The Picture in Picture controller.
 @abstract  Delegate can implement this method to be notified when Picture in Picture will stop.
 */
- (void)pictureInPictureViewControllerWillStopPictureInPicture:(NVPictureInPictureViewController *)pictureInPictureViewController;

/*!
 @method    pictureInPictureViewControllerDidStopPictureInPicture:
 @param    pictureInPictureViewController
 The Picture in Picture controller.
 @abstract  Delegate can implement this method to be notified when Picture in Picture did stop.
 */
- (void)pictureInPictureViewControllerDidStopPictureInPicture:(NVPictureInPictureViewController *)pictureInPictureViewController;

@end
