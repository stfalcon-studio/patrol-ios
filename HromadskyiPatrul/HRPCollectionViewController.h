//
//  HRPCollectionViewController.h
//  HromadskyiPatrul
//
//  Created by msm72 on 21.08.15.
//  Copyright (c) 2015 Monastyrskiy Sergey. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HRPBaseViewController.h"


@interface HRPCollectionViewController : HRPBaseViewController

@property (strong, nonatomic) IBOutlet UIBarButtonItem *userNameBarButton;

- (void)prepareDataSource;

@end
