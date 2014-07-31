//
//  JKRHomeVC.m
//  Randor
//
//  Created by Jack on 28/7/14.
//  Copyright (c) 2014 Xu Xinyuan. All rights reserved.
//

#import "JKRHomeVC.h"
#import "JKRTopic.h"
#import "TransformableTableViewCell.h"
#import "JTTableViewGestureRecognizer.h"
#import "UIColor+JTGestureBasedTableViewHelper.h"
#import <CoreMotion/CoreMotion.h>

@interface JKRHomeVC ()<JTTableViewGestureEditingRowDelegate, JTTableViewGestureMoveRowDelegate, UIAlertViewDelegate>
@property (nonatomic, strong) NSMutableArray *rows;
@property (nonatomic, strong) JTTableViewGestureRecognizer *tableViewRecognizer;
@property (nonatomic, strong) id grabbedObject;
@end

@implementation JKRHomeVC {
    NSMutableArray *topicArr;
    CMMotionManager *motionManager;
    NSInteger renameIndex;
}

#define ADDING_CELL @"Continue..."
#define DONE_CELL @"Done"
#define DUMMY_CELL @"Dummy"
#define COMMITING_CREATE_CELL_HEIGHT 60
#define NORMAL_CELL_FINISHING_HEIGHT 60
#define TINT_COLOR [UIColor colorWithRed:0.0 green:122.0/255.0 blue:1.0 alpha:1.0]

#pragma mark - View lifecycle

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    NSUserDefaults *currentDefaults = [NSUserDefaults standardUserDefaults];
    NSData *savedArray = [currentDefaults objectForKey:@"topicArray"];
    if (savedArray != nil)
    {
        NSArray *oldArray = [NSKeyedUnarchiver unarchiveObjectWithData:savedArray];
        if (oldArray != nil) {
            topicArr = [[NSMutableArray alloc] initWithArray:oldArray];
            
        } else {
            topicArr = [[NSMutableArray alloc] init];
        }
    } else {
        topicArr = [[NSMutableArray alloc] init];
        JKRTopic *hint1 = [[JKRTopic alloc] initWithName:@"Swipe to right to rename the topic"];
        JKRTopic *hint2 = [[JKRTopic alloc] initWithName:@"Swipe to left to delete the topic"];
        JKRTopic *hint3 = [[JKRTopic alloc] initWithName:@"Long hold to start reorder cell"];
        JKRTopic *hint4 = [[JKRTopic alloc] initWithName:@"shake to random and nod to reset"];
        [topicArr addObject:hint1];
        [topicArr addObject:hint2];
        [topicArr addObject:hint3];
        [topicArr addObject:hint4];
    }
    self.rows = [[NSMutableArray alloc] init];
    for (JKRTopic *tmpTopic in topicArr) {
        [self.rows addObject:tmpTopic.topicName];
    }
    // Setup your tableView.delegate and tableView.datasource,
    // then enable gesture recognition in one line.
    self.tableViewRecognizer = [self.tableView enableGestureTableViewWithDelegate:self];
    
//    self.tableView.frame = CGRectMake(0, 100, self.tableView.frame.size.width, self.tableView.frame.size.height);
    self.tableView.backgroundColor = [UIColor whiteColor];
    self.tableView.separatorStyle  = UITableViewCellSeparatorStyleNone;
    self.tableView.rowHeight = NORMAL_CELL_FINISHING_HEIGHT;
    UIBarButtonItem *barListBtn = [[UIBarButtonItem alloc] initWithBarButtonSystemItem: UIBarButtonSystemItemAdd target:self action:@selector(addNewTopic)];
    self.navigationItem.rightBarButtonItem = barListBtn;
    
    motionManager = [[CMMotionManager alloc] init];
    if([motionManager isGyroAvailable]){
        NSLog(@"Gryro is available.");
        
        if ([motionManager  isGyroActive] == NO){
            motionManager.accelerometerUpdateInterval =0.3;
            NSOperationQueue *queue = [[NSOperationQueue alloc] init];
            [motionManager startGyroUpdatesToQueue:queue
                                            withHandler:^(CMGyroData *gyroData, NSError *error) {
                                                if (gyroData.rotationRate.x>5.0f) {
                                                    // refresh by nodding
                                                    [self.rows removeAllObjects];
                                                    for (JKRTopic *tmpTopic in topicArr) {
                                                        [self.rows addObject:tmpTopic.topicName];
                                                    }
                                                    [self.tableView performSelectorOnMainThread:@selector(reloadData) withObject:nil
                                                                                  waitUntilDone:NO];
                                                }else if (gyroData.rotationRate.z>5.0f) {
                                                    // random by shaking
                                                    JKRTopic *randomResult = [topicArr objectAtIndex:(arc4random()%[topicArr count])];
                                                    [self.rows removeAllObjects];
                                                    [self.rows addObject:randomResult.topicName];
                                                    [self.tableView performSelectorOnMainThread:@selector(reloadData) withObject:nil
                                                                                  waitUntilDone:NO];
                                                }
                                            }];
        }
    }else {
        NSLog(@"Gyro is not available.");
    }

}

#pragma mark UITableViewDatasource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.rows count];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    NSObject *object = [self.rows objectAtIndex:indexPath.row];
    UIColor *backgroundColor = [TINT_COLOR colorWithHueOffset:0.12 * indexPath.row / [self tableView:tableView numberOfRowsInSection:indexPath.section]];
    if ([object isEqual:ADDING_CELL]) {
        NSString *cellIdentifier = nil;
        TransformableTableViewCell *cell = nil;
        
        // IndexPath.row == 0 is the case we wanted to pick the pullDown style
        if (indexPath.row == 0) {
            cellIdentifier = @"PullDownTableViewCell";
            cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
            
            if (cell == nil) {
                cell = [TransformableTableViewCell transformableTableViewCellWithStyle:TransformableTableViewCellStylePullDown
                                                                       reuseIdentifier:cellIdentifier];
                cell.textLabel.adjustsFontSizeToFitWidth = YES;
                cell.textLabel.textColor = [UIColor whiteColor];
                cell.textLabel.textAlignment = NSTextAlignmentCenter;
            }
            
            
            cell.finishedHeight = COMMITING_CREATE_CELL_HEIGHT;
            if (cell.frame.size.height > COMMITING_CREATE_CELL_HEIGHT * 2) {
                cell.imageView.image = [UIImage imageNamed:@"reload.png"];
                cell.tintColor = [UIColor blackColor];
                cell.textLabel.text = @"Return to list...";
            } else if (cell.frame.size.height > COMMITING_CREATE_CELL_HEIGHT) {
                cell.imageView.image = nil;
                // Setup tint color
                cell.tintColor = backgroundColor;
                cell.textLabel.text = @"Release to create cell...";
            } else {
                cell.imageView.image = nil;
                // Setup tint color
                cell.tintColor = backgroundColor;
                cell.textLabel.text = @"Continue Pulling...";
            }
            cell.contentView.backgroundColor = [UIColor clearColor];
            cell.detailTextLabel.text = @" ";
            return cell;
            
        } else {
            // Otherwise is the case we wanted to pick the pullDown style
            cellIdentifier = @"UnfoldingTableViewCell";
            cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
            
            if (cell == nil) {
                cell = [TransformableTableViewCell transformableTableViewCellWithStyle:TransformableTableViewCellStyleUnfolding
                                                                       reuseIdentifier:cellIdentifier];
                cell.textLabel.adjustsFontSizeToFitWidth = YES;
                cell.textLabel.textColor = [UIColor whiteColor];
                cell.textLabel.textAlignment = NSTextAlignmentCenter;
            }
            
            // Setup tint color
            cell.tintColor = backgroundColor;
            
            cell.finishedHeight = COMMITING_CREATE_CELL_HEIGHT;
            if (cell.frame.size.height > COMMITING_CREATE_CELL_HEIGHT) {
                cell.textLabel.text = @"Release to create cell...";
            } else {
                cell.textLabel.text = @"Continue Pinching...";
            }
            cell.contentView.backgroundColor = [UIColor clearColor];
            cell.detailTextLabel.text = @" ";
            return cell;
        }
        
    } else {
        
        static NSString *cellIdentifier = @"MyCell";
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
            cell.textLabel.adjustsFontSizeToFitWidth = YES;
            cell.textLabel.backgroundColor = [UIColor clearColor];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        
        cell.textLabel.text = [NSString stringWithFormat:@"%@", (NSString *)object];
        cell.detailTextLabel.text = @" ";
        if ([object isEqual:DONE_CELL]) {
            cell.textLabel.textColor = [UIColor grayColor];
            cell.contentView.backgroundColor = [UIColor darkGrayColor];
        } else if ([object isEqual:DUMMY_CELL]) {
            cell.textLabel.text = @"";
            cell.contentView.backgroundColor = [UIColor clearColor];
        } else {
            cell.textLabel.textColor = [UIColor whiteColor];
            cell.contentView.backgroundColor = backgroundColor;
        }
        return cell;
    }
    
}

#pragma mark UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return NORMAL_CELL_FINISHING_HEIGHT;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSLog(@"tableView:didSelectRowAtIndexPath: %@", indexPath);
}

#pragma mark JTTableViewGestureEditingRowDelegate

- (void)gestureRecognizer:(JTTableViewGestureRecognizer *)gestureRecognizer didEnterEditingState:(JTTableViewCellEditingState)state forRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    
    UIColor *backgroundColor = nil;
    switch (state) {
        case JTTableViewCellEditingStateMiddle:
            backgroundColor = [TINT_COLOR colorWithHueOffset:0.12 * indexPath.row / [self tableView:self.tableView numberOfRowsInSection:indexPath.section]];
            break;
        case JTTableViewCellEditingStateRight:
            backgroundColor = [UIColor greenColor];
            break;
        default:
            backgroundColor = [UIColor darkGrayColor];
            break;
    }
    cell.contentView.backgroundColor = backgroundColor;
    if ([cell isKindOfClass:[TransformableTableViewCell class]]) {
        ((TransformableTableViewCell *)cell).tintColor = backgroundColor;
    }
}

// This is needed to be implemented to let our delegate choose whether the panning gesture should work
- (BOOL)gestureRecognizer:(JTTableViewGestureRecognizer *)gestureRecognizer canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (void)gestureRecognizer:(JTTableViewGestureRecognizer *)gestureRecognizer commitEditingState:(JTTableViewCellEditingState)state forRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableView *tableView = gestureRecognizer.tableView;
    [tableView beginUpdates];
    if (state == JTTableViewCellEditingStateLeft) {
        // An example to discard the cell at JTTableViewCellEditingStateLeft
        [self.rows removeObjectAtIndex:indexPath.row];
        [topicArr removeObjectAtIndex:indexPath.row];
        [[NSUserDefaults standardUserDefaults] setObject:[NSKeyedArchiver archivedDataWithRootObject:topicArr] forKey:@"topicArray"];
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationLeft];
    } else if (state == JTTableViewCellEditingStateRight) {
        renameIndex = indexPath.row;
        UIAlertView *prompt = [[UIAlertView alloc] initWithTitle:
                               [NSString stringWithFormat:@"Rename \"%@\"",
                                [self.rows objectAtIndex:renameIndex]]
                                                         message:nil
                                                        delegate:self
                                               cancelButtonTitle:@"Cancel"
                                               otherButtonTitles:@"Rename it!", nil];
        prompt.alertViewStyle = UIAlertViewStylePlainTextInput;
        [prompt show];
        [tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationLeft];
    } else {
        // JTTableViewCellEditingStateMiddle shouldn't really happen in
        // - [JTTableViewGestureDelegate gestureRecognizer:commitEditingState:forRowAtIndexPath:]
    }
    [tableView endUpdates];
    
    // Row color needs update after datasource changes, reload it.
    [tableView performSelector:@selector(reloadVisibleRowsExceptIndexPath:) withObject:indexPath afterDelay:JTTableViewRowAnimationDuration];
}

#pragma mark JTTableViewGestureMoveRowDelegate

- (BOOL)gestureRecognizer:(JTTableViewGestureRecognizer *)gestureRecognizer canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (void)gestureRecognizer:(JTTableViewGestureRecognizer *)gestureRecognizer needsCreatePlaceholderForRowAtIndexPath:(NSIndexPath *)indexPath {
    self.grabbedObject = [self.rows objectAtIndex:indexPath.row];
    [self.rows replaceObjectAtIndex:indexPath.row withObject:DUMMY_CELL];
}

- (void)gestureRecognizer:(JTTableViewGestureRecognizer *)gestureRecognizer needsMoveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath {
    id object = [self.rows objectAtIndex:sourceIndexPath.row];
    [self.rows removeObjectAtIndex:sourceIndexPath.row];
    [self.rows insertObject:object atIndex:destinationIndexPath.row];
}

- (void)gestureRecognizer:(JTTableViewGestureRecognizer *)gestureRecognizer needsReplacePlaceholderForRowAtIndexPath:(NSIndexPath *)indexPath {
    [self.rows replaceObjectAtIndex:indexPath.row withObject:self.grabbedObject];
    self.grabbedObject = nil;
}
/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (void)addNewTopic
{
    UIAlertView *prompt = [[UIAlertView alloc] initWithTitle:@"Name of Topic"
                                                     message:nil
                                                    delegate:self
                                           cancelButtonTitle:@"Cancel"
                                           otherButtonTitles:@"Name it!", nil];
    prompt.alertViewStyle = UIAlertViewStylePlainTextInput;
    [prompt show];
}
#pragma mark UIAlertView delegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	NSString *title = [alertView buttonTitleAtIndex:buttonIndex];
	
	if([title isEqualToString:@"Name it!"])
	{
		UITextField *topicNameTF = [alertView textFieldAtIndex:0];
        JKRTopic *topic = [[JKRTopic alloc] initWithName:topicNameTF.text];
        [topicArr insertObject:topic atIndex:0];
		[self.rows insertObject:topicNameTF.text atIndex:0];
        
	}
    if([title isEqualToString:@"Rename it!"])
	{
		UITextField *topicNameTF = [alertView textFieldAtIndex:0];
        [[topicArr objectAtIndex:renameIndex] setTopicName:topicNameTF.text];
        [self.rows replaceObjectAtIndex:renameIndex withObject:topicNameTF.text];
	}
    
    [[NSUserDefaults standardUserDefaults] setObject:[NSKeyedArchiver archivedDataWithRootObject:topicArr] forKey:@"topicArray"];
    [self.tableView reloadData];
}
@end
