//
//  NVPIPViewController.m
//  NVPictureInPicture
//
//  Created by niteshvijay1995 on 05/02/2018.
//  Copyright (c) 2018 niteshvijay1995. All rights reserved.
//

#import "NVRootViewController.h"
#import "NVPIPSubViewController.h"


@interface NVRootViewController ()

@end

@implementation NVRootViewController

- (IBAction)handleTap:(UIButton *)sender {
  [self.view endEditing:YES];
  NVPIPSubViewController *viewController = (NVPIPSubViewController *)[[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"NVPIPSubViewController"];
  viewController.view.backgroundColor = sender.backgroundColor;
  [viewController presentOnWindow:UIApplication.sharedApplication.keyWindow];
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
  [self.view endEditing:YES];
}

@end
