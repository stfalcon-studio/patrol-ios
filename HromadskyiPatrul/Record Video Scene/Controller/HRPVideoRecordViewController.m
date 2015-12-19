//
//  HRPVideoRecordViewController.m
//  HromadskyiPatrul
//
//  Created by msm72 on 19.12.15.
//  Copyright © 2015 Monastyrskiy Sergey. All rights reserved.
//

#import "HRPVideoRecordViewController.h"
#import "HRPCollectionViewController.h"


@interface HRPVideoRecordViewController ()

@end


@implementation HRPVideoRecordViewController

#pragma mark - Constructors -
- (void)viewDidLoad {
    [super viewDidLoad];

}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self customizeNavigationBarWithTitle:NSLocalizedString(@"Record a Video", nil)
                    andLeftBarButtonImage:[UIImage new]
                   andRightBarButtonImage:[UIImage imageNamed:@"icon-action-close"]];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];

}


#pragma mark - Actions -
- (void)handlerRightBarButtonTap:(UIBarButtonItem *)sender {
    // Stop Video Record Session
    
    // Transition to Collection Scene
    HRPCollectionViewController *collectionVC   =   [self.storyboard instantiateViewControllerWithIdentifier:@"CollectionVC"];
    
    // Prepare DataSource
    
    [self.navigationController pushViewController:collectionVC animated:YES];
}

@end
