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
                      withActionEnabled:(BOOL)leftButtonEnabled
                 andRightBarButtonImage:(UIImage *)imageRightBarButton
                      withActionEnabled:(BOOL)rightButtonEnabled;

- (void)customizeNavigationBarWithTitle:(NSString *)title
                  andLeftBarButtonImage:(UIImage *)imageLeftBarButton
                      withActionEnabled:(BOOL)leftButtonEnabled
                  andRightBarButtonText:(NSString *)textRightBarButton
                      withActionEnabled:(BOOL)rightButtonEnabled;

- (void)customizeNavigationBarWithTitle:(NSString *)title
                   andLeftBarButtonText:(NSString *)textLeftBarButton
                      withActionEnabled:(BOOL)leftButtonEnabled
                 andRightBarButtonImage:(UIImage *)imageRightBarButton
                      withActionEnabled:(BOOL)rightButtonEnabled;

- (void)handlerLeftBarButtonTap:(UIBarButtonItem *)sender;
- (void)handlerRightBarButtonTap:(UIBarButtonItem *)sender;

@end
