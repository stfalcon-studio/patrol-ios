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
                      withActionEnabled:(BOOL)leftButtonEnabled
                 andRightBarButtonImage:(UIImage *)imageRightBarButton
                      withActionEnabled:(BOOL)rightButtonEnabled {
    // Set NavigationBar Style
    [self showNavigationBar];

    // Set Title text
    [self.navigationItem setTitle:title];
    
    // Set Left BarButton image
    [self customizeLeftBarButtonWithImage:imageLeftBarButton withActionEnabled:leftButtonEnabled];

    // Set Right BarButton image
    [self customizeRightBarButtonWithImage:imageRightBarButton withActionEnabled:rightButtonEnabled];
}

- (void)customizeNavigationBarWithTitle:(NSString *)title
                  andLeftBarButtonImage:(UIImage *)imageLeftBarButton
                      withActionEnabled:(BOOL)leftButtonEnabled
                  andRightBarButtonText:(NSString *)textRightBarButton
                      withActionEnabled:(BOOL)rightButtonEnabled {
    // Set NavigationBar Style
    [self showNavigationBar];
    
    // Set Title text
    [self.navigationItem setTitle:title];
    
    // Set Left BarButton image
    [self customizeLeftBarButtonWithImage:imageLeftBarButton withActionEnabled:leftButtonEnabled];
    
    // Set Right BarButton image
    [self customizeRightBarButtonWithText:textRightBarButton withActionEnabled:rightButtonEnabled];
}

- (void)customizeNavigationBarWithTitle:(NSString *)title
                   andLeftBarButtonText:(NSString *)textLeftBarButton
                      withActionEnabled:(BOOL)leftButtonEnabled
                 andRightBarButtonImage:(UIImage *)imageRightBarButton
                      withActionEnabled:(BOOL)rightButtonEnabled {
    // Set NavigationBar Style
    [self showNavigationBar];
    
    // Set Title text
    [self.navigationItem setTitle:title];
    
    // Set Left BarButton image
    [self customizeLeftBarButtonWithText:textLeftBarButton withActionEnabled:leftButtonEnabled];
    
    // Set Right BarButton image
    [self customizeRightBarButtonWithImage:imageRightBarButton withActionEnabled:rightButtonEnabled];
}

- (void)customizeLeftBarButtonWithImage:(UIImage *)image withActionEnabled:(BOOL)enabled {
    UIButton *button    =   [[UIButton alloc] initWithFrame:CGRectMake(0.f, 0.f, 10.f, 44.f)];
    
    [button setImage:image forState:UIControlStateNormal];
    
    [button addTarget:self
               action:@selector(handlerLeftBarButtonTap:) forControlEvents:UIControlEventTouchUpInside];
    
    [button setUserInteractionEnabled:enabled];
    [self.navigationItem setLeftBarButtonItem:[[UIBarButtonItem alloc] initWithCustomView:button]];
}

- (void)customizeRightBarButtonWithImage:(UIImage *)image withActionEnabled:(BOOL)enabled {
    UIButton *button    =   [[UIButton alloc] initWithFrame:CGRectMake(0.f, 0.f, 20.f, 44.f)];
        
    [button setImage:image forState:UIControlStateNormal];
    
    [button addTarget:self
               action:@selector(handlerRightBarButtonTap:) forControlEvents:UIControlEventTouchUpInside];
        
    [button setUserInteractionEnabled:enabled];
    [self.navigationItem setRightBarButtonItem:[[UIBarButtonItem alloc] initWithCustomView:button]];
}

- (void)customizeLeftBarButtonWithText:(NSString *)text withActionEnabled:(BOOL)enabled {
    UILabel *label      =   [[UILabel alloc] init];
    label.font          =   [UIFont systemFontOfSize:14.f weight:UIFontWeightUltraLight];
    label.text          =   text;
    [label sizeToFit];
    
    UIButton *button    =   [[UIButton alloc] initWithFrame:CGRectMake(0.f, 0.f, CGRectGetWidth(label.frame) + 50.f, 44.f)];

    [button setTitle:text forState:UIControlStateNormal];
    [button setContentHorizontalAlignment:UIControlContentHorizontalAlignmentLeft];
    
    [button addTarget:self
               action:@selector(handlerRightBarButtonTap:) forControlEvents:UIControlEventTouchUpInside];
    
    [button.titleLabel sizeToFit];

    [button setUserInteractionEnabled:enabled];
    [self.navigationItem setLeftBarButtonItem:[[UIBarButtonItem alloc] initWithCustomView:button]];
}

- (void)customizeRightBarButtonWithText:(NSString *)text withActionEnabled:(BOOL)enabled {
    UIButton *button    =   [[UIButton alloc] initWithFrame:CGRectMake(0.f, 0.f, 20.f, 44.f)];
    
    [button setTitle:text forState:UIControlStateNormal];
    
    [button addTarget:self
               action:@selector(handlerRightBarButtonTap:) forControlEvents:UIControlEventTouchUpInside];
    
    [button setUserInteractionEnabled:enabled];
    [button.titleLabel sizeToFit];
    [self.navigationItem setRightBarButtonItem:[[UIBarButtonItem alloc] initWithCustomView:button]];
}

@end
