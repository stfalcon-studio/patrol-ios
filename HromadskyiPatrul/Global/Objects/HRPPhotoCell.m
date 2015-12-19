//
//  HRPPhotoCell.m
//  HromadskyiPatrul
//
//  Created by msm72 on 26.08.15.
//  Copyright (c) 2015 Monastyrskiy Sergey. All rights reserved.
//

#import "HRPPhotoCell.h"
#import "UIColor+HexColor.h"


@implementation HRPPhotoCell

#pragma mark - Actions -
- (IBAction)actionPhotoStateButtonTap:(UIButton *)sender {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"HRPPhotoCellStateButtonTap"
                                                        object:nil
                                                      userInfo:@{ @"cell" : self }];
}


#pragma mark - Methods -
- (void)showLoaderWithText:(NSString *)text andBackgroundColor:(CellBackgroundColorType)colorType {
    NSString *colorString   =   nil;
    
    switch (colorType) {
        case CellBackgroundColorTypeBlue:
            colorString     =   @"05A9F4";
            break;
            
        case CellBackgroundColorTypeBlack:
            colorString     =   @"000000";
            break;
    }
    
    _HUD                    =   [[MBProgressHUD alloc] initWithView:self];
    _HUD.labelText          =   text;
    _HUD.yOffset            =   0.f;
    _HUD.color              =   [UIColor colorWithHexString:colorString alpha:0.6f];
    
    [self addSubview:_HUD];
    [_HUD showWhileExecuting:@selector(sleepTask) onTarget:self withObject:nil animated:YES];
}

- (void)hideLoader {
    [MBProgressHUD hideAllHUDsForView:self animated:YES];
}

- (void)sleepTask {
    // Do something usefull in here instead of sleeping ...
    sleep(300);
}

@end
