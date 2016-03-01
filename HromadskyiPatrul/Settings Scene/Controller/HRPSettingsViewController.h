//
//  HRPSettingsViewController.h
//  HromadskyiPatrul
//
//  Created by msm72 on 21.08.15.
//  Copyright (c) 2015 Monastyrskiy Sergey. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void(^didChangeAutoUploadItem)(id item);


@interface HRPSettingsViewController : UITableViewController

@property (nonatomic, copy) didChangeAutoUploadItem didChangeAutoUploadItem;
- (void)setDidChangeAutoUploadItem:(didChangeAutoUploadItem)didChangeAutoUploadItem;

@end
