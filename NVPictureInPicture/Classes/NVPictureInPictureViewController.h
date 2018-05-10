//
//  NVPictureInPictureViewController.h
//  NVPictureInPicture
//
//  Created by Nitesh Vijay on 10/05/18.
//

#import <UIKit/UIKit.h>

@protocol NVPictureInPictureViewControllerDelegate;

@interface NVPictureInPictureViewController : UIViewController

@property (nonatomic, weak) id<NVPictureInPictureViewControllerDelegate> delegate;

@property(nonatomic, readonly, getter=isPictureInPictureActive) BOOL pictureInPictureActive;

- (void)reload;

- (void)startPictureInPicture;

- (void)stopPictureInPicture;

- (UIEdgeInsets)pictureInPictureEdgeInsets;

- (CGSize)pictureInPictureSize;

- (void)movePictureInPictureWithOffset:(CGPoint)offset animated:(BOOL)animated;

@end

@protocol NVPictureInPictureViewControllerDelegate <NSObject>

@optional

- (void)pictureInPictureViewControllerWillStartPictureInPicture:(NVPictureInPictureViewController *)pictureInPictureViewController;

- (void)pictureInPictureViewControllerDidStartPictureInPicture:(NVPictureInPictureViewController *)pictureInPictureViewController;

- (void)pictureInPictureViewControllerWillStopPictureInPicture:(NVPictureInPictureViewController *)pictureInPictureViewController;

- (void)pictureInPictureViewControllerDidStopPictureInPicture:(NVPictureInPictureViewController *)pictureInPictureViewController;

@end
