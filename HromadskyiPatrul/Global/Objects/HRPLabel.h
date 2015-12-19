//
//  HRPLabel.h
//  HromadskyiPatrul
//
//  Created by msm72 on 19.12.15.
//  Copyright © 2015 Monastyrskiy Sergey. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface HRPLabel : UILabel

@property (assign, nonatomic) BOOL isLabelFlashing;

- (void)startFlashing;

@end
