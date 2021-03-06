//
//  NewUserViewController.m
//  Anywall
//
//  Created by  on 8/1/14.
//  Copyright (c) 2013 leap app service. All rights reserved.
//

#import "NewUserViewController.h"
#import <LAS/LAS.h>
#import "ActivityView.h"
#import "WallViewController.h"
#import "RootViewController.h"

@implementation NewUserViewController

#pragma mark - UIViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textInputChanged:) name:UITextFieldTextDidChangeNotification object:self.usernameField];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textInputChanged:) name:UITextFieldTextDidChangeNotification object:self.passwordField];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textInputChanged:) name:UITextFieldTextDidChangeNotification object:self.passwordAgainField];

	self.doneButton.enabled = NO;
}

- (void)viewWillAppear:(BOOL)animated {
	[self.usernameField becomeFirstResponder];
	[super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
	
	[self.view endEditing:NO];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UITextFieldTextDidChangeNotification object:self.usernameField];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UITextFieldTextDidChangeNotification object:self.passwordField];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UITextFieldTextDidChangeNotification object:self.passwordAgainField];
}


#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
	if (textField == self.usernameField) {
		[self.passwordField becomeFirstResponder];
	}
	if (textField == self.passwordField) {
		[self.passwordAgainField becomeFirstResponder];
	}
	if (textField == self.passwordAgainField) {
		[self.passwordAgainField resignFirstResponder];
		[self processFieldEntries];
	}

	return YES;
}

#pragma mark - ()

- (BOOL)shouldEnableDoneButton {
	BOOL enableDoneButton = NO;
	if (self.usernameField.text != nil &&
		self.usernameField.text.length > 0 &&
		self.passwordField.text != nil &&
		self.passwordField.text.length > 0 &&
		self.passwordAgainField.text != nil &&
		self.passwordAgainField.text.length > 0) {
		enableDoneButton = YES;
	}
	return enableDoneButton;
}

- (void)textInputChanged:(NSNotification *)note {
	self.doneButton.enabled = [self shouldEnableDoneButton];
}

- (IBAction)cancel:(id)sender {
	[self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)done:(id)sender {
	[self.usernameField resignFirstResponder];
	[self.passwordField resignFirstResponder];
	[self.passwordAgainField resignFirstResponder];
	[self processFieldEntries];
}

- (void)processFieldEntries {
	// Check that we have a non-zero username and passwords.
	// Compare password and passwordAgain for equality
	// Throw up a dialog that tells them what they did wrong if they did it wrong.

	NSString *username = self.usernameField.text;
	NSString *password = self.passwordField.text;
	NSString *passwordAgain = self.passwordAgainField.text;
	NSString *errorText = @"Please ";
	NSString *usernameBlankText = @"enter a username";
	NSString *passwordBlankText = @"enter a password";
	NSString *joinText = @", and ";
	NSString *passwordMismatchText = @"enter the same password twice";

	BOOL textError = NO;

	// Messaging nil will return 0, so these checks implicitly check for nil text.
	if (username.length == 0 || password.length == 0 || passwordAgain.length == 0) {
		textError = YES;

		// Set up the keyboard for the first field missing input:
		if (passwordAgain.length == 0) {
			[self.passwordAgainField becomeFirstResponder];
		}
		if (password.length == 0) {
			[self.passwordField becomeFirstResponder];
		}
		if (username.length == 0) {
			[self.usernameField becomeFirstResponder];
		}

		if (username.length == 0) {
			errorText = [errorText stringByAppendingString:usernameBlankText];
		}

		if (password.length == 0 || passwordAgain.length == 0) {
			if (username.length == 0) { // We need some joining text in the error:
				errorText = [errorText stringByAppendingString:joinText];
			}
			errorText = [errorText stringByAppendingString:passwordBlankText];
		}
	} else if ([password compare:passwordAgain] != NSOrderedSame) {
		// We have non-zero strings.
		// Check for equal password strings.
		textError = YES;
		errorText = [errorText stringByAppendingString:passwordMismatchText];
		[self.passwordField becomeFirstResponder];
	}

	if (textError) {
		UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:errorText message:nil delegate:self cancelButtonTitle:nil otherButtonTitles:@"Ok", nil];
		[alertView show];
		return;
	}

	// Everything looks good; try to log in.
	// Disable the done button for now.
	self.doneButton.enabled = NO;
	ActivityView *activityView = [[ActivityView alloc] initWithFrame:CGRectMake(0.f, 0.f, self.view.frame.size.width, self.view.frame.size.height)];
	UILabel *label = activityView.label;
	label.text = @"Signing You Up";
	label.font = [UIFont boldSystemFontOfSize:20.f];
	[activityView.activityIndicator startAnimating];
	[activityView layoutSubviews];

	[self.view addSubview:activityView];

	// Call into an object somewhere that has code for setting up a user.
	// The app delegate cares about this, but so do a lot of other objects.
	// For now, do this inline.

	LASUser *user = [LASUser user];
	user.username = username;
	user.password = password;
	[LASUserManager signUpInBackground:user block:^(BOOL succeeded, NSError *error) {
		if (error) {
			UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:[[error userInfo] objectForKey:@"error"] message:nil delegate:self cancelButtonTitle:nil otherButtonTitles:@"Ok", nil];
			[alertView show];
			self.doneButton.enabled = [self shouldEnableDoneButton];
			[activityView.activityIndicator stopAnimating];
			[activityView removeFromSuperview];
			// Bring the keyboard back up, because they'll probably need to change something.
			[self.usernameField becomeFirstResponder];
			return;
		}

		// Success!
		[activityView.activityIndicator stopAnimating];
		[activityView removeFromSuperview];
		
		[(RootViewController *)self.presentingViewController presentViewController];
		[self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
	}];
}

@end
