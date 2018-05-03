//
//  NVPIPViewController.m
//  NVPictureInPicture
//
//  Created by niteshvijay1995 on 05/02/2018.
//  Copyright (c) 2018 niteshvijay1995. All rights reserved.
//

#import "NVRootViewController.h"
#import <NVPictureInPicture/NVPictureInPicture.h>
#import <NVPictureInPicture/NVPIPViewController.h>

@interface NVRootViewController ()

@property (nonatomic) NVPictureInPicture *pictureInPicture;

@end

@implementation NVRootViewController

- (NVPictureInPicture *)pictureInPicture {
  if (_pictureInPicture == nil) {
    _pictureInPicture = [[NVPictureInPicture alloc] init];
  }
  return _pictureInPicture;
}

- (IBAction)handleTap:(UIButton *)sender {
  NVPIPViewController *viewController = [[NVPIPViewController alloc] init];
  viewController.view.backgroundColor = sender.backgroundColor;
  [self.pictureInPicture presentNVPIPViewController:viewController];
}


@end
