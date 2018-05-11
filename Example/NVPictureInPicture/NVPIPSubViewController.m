//
//  NVPIPSubViewController.m
//  NVPictureInPicture_Example
//
//  Created by Nitesh Vijay on 03/05/18.
//  Copyright © 2018 niteshvijay1995. All rights reserved.
//

#import "NVPIPSubViewController.h"

@interface NVPIPSubViewController () <NVPictureInPictureViewControllerDelegate>

@property (weak, nonatomic) IBOutlet UIButton *closeButton;
@property (weak, nonatomic) IBOutlet UIButton *backButton;

@end

@implementation NVPIPSubViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  self.view.clipsToBounds = YES;
  self.delegate = self;
}

- (void)pictureInPictureViewControllerWillStartPictureInPicture:(NVPictureInPictureViewController *)pictureInPictureViewController {
  self.closeButton.alpha = 0;
  self.backButton.alpha = 0;
}

- (void)pictureInPictureViewControllerDidStopPictureInPicture:(NVPictureInPictureViewController *)pictureInPictureViewController {
  self.closeButton.alpha = 1;
  self.backButton.alpha = 1;
}

- (IBAction)back:(id)sender {
  self.closeButton.alpha = 0;
  self.backButton.alpha = 0;
  [self startPictureInPicture];
}

- (IBAction)close:(id)sender {
  self.closeBlock();
}
@end
