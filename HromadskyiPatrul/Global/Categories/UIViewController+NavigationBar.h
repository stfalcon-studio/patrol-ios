/*
 Copyright (c) 2015 - 2016. Stepan Tanasiychuk
 This file is part of Gromadskyi Patrul is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by the Free Software Found ation, version 3 of the License, or any later version.
 If you would like to use any part of this project for commercial purposes, please contact us
 for negotiating licensing terms and getting permission for commercial use. Our email address: info@stfalcon.com
 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 GNU General Public License for more details.
 You should have received a copy of the GNU General Public License along with this program.
 If not, see http://www.gnu.org/licenses/.
 */
// https://github.com/stfalcon-studio/patrol-android/blob/master/app/build.gradle
//
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

- (UIView *)customizeStatusBar;

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
