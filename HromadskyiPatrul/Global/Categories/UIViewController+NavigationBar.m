//
//  UIViewController+NavigationBar.m
//  HromadskyiPatrul
//
//  Created by msm72 on 19.12.15.
//  Copyright © 2015 Monastyrskiy Sergey. All rights reserved.
//

#import "UIViewController+NavigationBar.h"
#import "UIColor+HexColor.h"


@implementation UIViewController (NavigationBar)

#pragma mark - Actions -
- (void)handlerLeftBarButtonTap:(UIBarButtonItem *)sender {
    // Override action in the class
}

- (void)handlerRightBarButtonTap:(UIBarButtonItem *)sender {
    // Override action in the class
}


#pragma mark - Methods -
- (void)hideNavigationBar {
    [self.navigationController setNavigationBarHidden:YES];
}

- (void)showNavigationBar {
    // Set NavigationBar Style
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    
    [self.navigationController.navigationBar setBarStyle:UIBarStyleBlack];
    [self.navigationController.navigationBar setBarTintColor:[UIColor whiteColor]];
    [self.navigationController.navigationBar setBarTintColor:[UIColor colorWithHexString:@"0477BD" alpha:1.f]];
    [self.navigationController.navigationBar setTranslucent:YES];
}

- (void)customizeNavigationBarWithTitle:(NSString *)title
                  andLeftBarButtonImage:(UIImage *)imageLeftBarButton
                 andRightBarButtonImage:(UIImage *)imageRightBarButton {
    // Set NavigationBar Style
    [self showNavigationBar];

    // Set Title text
    [self.navigationItem setTitle:title];
    
    // Set Left BarButton image
    [self customizeLeftBarButtonWithImage:imageLeftBarButton];

    // Set Right BarButton image
    [self customizeRightBarButtonWithImage:imageRightBarButton];
}

- (void)customizeNavigationBarWithTitle:(NSString *)title
                  andLeftBarButtonImage:(UIImage *)imageLeftBarButton
                  andRightBarButtonText:(NSString *)textRightBarButton {
    // Set NavigationBar Style
    [self showNavigationBar];
    
    // Set Title text
    [self.navigationItem setTitle:title];
    
    // Set Left BarButton image
    [self customizeLeftBarButtonWithImage:imageLeftBarButton];
    
    // Set Right BarButton image
    [self customizeRightBarButtonWithText:textRightBarButton];
}

- (void)customizeLeftBarButtonWithImage:(UIImage *)image {
    UIButton *button    =   [[UIButton alloc] initWithFrame:CGRectMake(0.f, 33.f, 20.f, 12.f)];
    
    [button setImage:image forState:UIControlStateNormal];
    
    [button addTarget:self
               action:@selector(handlerLeftBarButtonTap:) forControlEvents:UIControlEventTouchUpInside];
    
    [button setUserInteractionEnabled:(image) ? YES : NO];
    [self.navigationItem setLeftBarButtonItem:[[UIBarButtonItem alloc] initWithCustomView:button]];
}

- (void)customizeRightBarButtonWithImage:(UIImage *)image {
    UIButton *button    =   [[UIButton alloc] initWithFrame:CGRectMake(0.f, 33.f, 20.f, 12.f)];
        
    [button setImage:image forState:UIControlStateNormal];
    
    [button addTarget:self
               action:@selector(handlerRightBarButtonTap:) forControlEvents:UIControlEventTouchUpInside];
        
    [button setUserInteractionEnabled:(image) ? YES : NO];
    [self.navigationItem setRightBarButtonItem:[[UIBarButtonItem alloc] initWithCustomView:button]];
}

- (void)customizeRightBarButtonWithText:(NSString *)text {
    UIButton *button    =   [[UIButton alloc] initWithFrame:CGRectMake(0.f, 33.f, 20.f, 12.f)];
    
    [button setTitle:text forState:UIControlStateNormal];
    
    [button addTarget:self
               action:@selector(handlerRightBarButtonTap:) forControlEvents:UIControlEventTouchUpInside];
    
    [button setUserInteractionEnabled:(text) ? YES : NO];
    [self.navigationItem setRightBarButtonItem:[[UIBarButtonItem alloc] initWithCustomView:button]];
}

@end
