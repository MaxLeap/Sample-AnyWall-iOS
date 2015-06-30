//
//  LoginViewController.h
//  Anywall
//
//  Created by  on 8/1/14.
//  Copyright (c) 2013 leap app service. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LoginViewController : UIViewController <UITextFieldDelegate>

@property (nonatomic, strong) IBOutlet UIBarButtonItem *doneButton;

@property (nonatomic, strong) IBOutlet UITextField *usernameField;
@property (nonatomic, strong) IBOutlet UITextField *passwordField;

- (IBAction)cancel:(id)sender;
- (IBAction)done:(id)sender;

@end
