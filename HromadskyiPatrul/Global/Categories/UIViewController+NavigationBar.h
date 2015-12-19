//
//  UIViewController+NavigationBar.h
//  HromadskyiPatrul
//
//  Created by msm72 on 19.12.15.
//  Copyright © 2015 Monastyrskiy Sergey. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface UIViewController (NavigationBar)

- (void)hideNavigationBar;

- (void)customizeNavigationBarWithTitle:(NSString *)title
                  andLeftBarButtonImage:(UIImage *)imageLeftBarButton
                 andRightBarButtonImage:(UIImage *)imageRightBarButton;

- (void)customizeNavigationBarWithTitle:(NSString *)title
                  andLeftBarButtonImage:(UIImage *)imageLeftBarButton
                  andRightBarButtonText:(NSString *)textRightBarButton;

- (void)handlerLeftBarButtonTap:(UIBarButtonItem *)sender;
- (void)handlerRightBarButtonTap:(UIBarButtonItem *)sender;

@end
