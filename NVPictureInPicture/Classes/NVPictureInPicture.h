//
//  NVPictureInPicture.h
//  NVPictureInPicture
//
//  Created by Nitesh Vijay on 02/05/18.
//

#import <Foundation/Foundation.h>

@class NVPIPViewController;

@interface NVPictureInPicture : NSObject

- (void)presentNVPIPViewController:(NVPIPViewController *)viewController;

- (void)dismissPresentedViewControllerWithCompletion: (void (^ __nullable)(void))completion;

@end
