//
//  WTUserNotificationViewController.m
//  v2ex
//
//  Created by 无头骑士 GJ on 16/7/25.
//  Copyright © 2016年 无头骑士 GJ. All rights reserved.
//  通知控制器

#import "WTUserNotificationViewController.h"
#import "WTLoginViewController.h"
#import "WTTopicDetailViewController.h"

#import "WTNoLoginView.h"
#import "WTNoDataView.h"
#import "WTNotificationCell.h"
#import "WTRefreshNormalHeader.h"
#import "WTRefreshAutoNormalFooter.h"
#import "UIViewController+Extension.h"

#import "WTConst.h"
#import "NetworkTool.h"
#import "WTTopicViewModel.h"
#import "WTAccountViewModel.h"
#import "WTNotificationViewModel.h"

#import "UITableView+FDTemplateLayoutCell.h"
#import <DZNEmptyDataSet/UIScrollView+EmptyDataSet.h>

static NSString * const ID = @"notificationCell";

@interface WTUserNotificationViewController () <DZNEmptyDataSetSource, DZNEmptyDataSetDelegate, WTNotificationCellDelegate>
/** 回复消息ViewModel */
@property (nonatomic, strong) WTNotificationViewModel          *notificationVM;
/** 请求地址 */
@property (nonatomic, strong) NSString                         *urlString;
/** 页数*/
@property (nonatomic, assign) NSInteger                        page;

@property (nonatomic, assign) WTTableViewType                  tableViewType;


@property (weak, nonatomic) IBOutlet UITableView               *tableView;

@end

@implementation WTUserNotificationViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    
    self.titleLabel.text = @"提醒";
    
    [self navViewWithTitle: @"提醒" hideBack: YES];
    
    self.tableView.tableFooterView = [UIView new];
    
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    
    // iOS8 以后 self-sizing
    self.tableView.estimatedRowHeight = 96;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    
    // 注册cell
    [self.tableView registerNib: [UINib nibWithNibName: NSStringFromClass([WTNotificationCell class]) bundle: nil] forCellReuseIdentifier: ID];
    
    self.notificationVM = [WTNotificationViewModel new];
    
    // 1、添加下拉刷新、上拉刷新
    self.tableView.mj_header = [WTRefreshNormalHeader headerWithRefreshingTarget: self refreshingAction: @selector(loadNewData)];
    self.tableView.mj_footer = [WTRefreshAutoNormalFooter footerWithRefreshingTarget: self refreshingAction: @selector(loadOldData)];
    
    
    self.tableView.emptyDataSetSource = self;
    self.tableView.emptyDataSetDelegate = self;
    
    [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(loadData) name: WTLoginStateChangeNotification object: nil];
    
    [self loadData];
}

- (void)loadData
{
    
    // 2、登陆过
    if ([[WTAccountViewModel shareInstance] isLogin])
    {
        // 2、开始下拉刷新
        [self.tableView.mj_header beginRefreshing];
        
    }
    else
    {
        self.tableViewType = WTTableViewTypeLogout;
        [self.notificationVM.notificationItems removeAllObjects];
        [self.tableView reloadData];
    }
}

#pragma mark - 加载数据
#pragma mark 加载最新的数据
- (void)loadNewData
{
    
    self.notificationVM.page = 1;
    
    [self.notificationVM getUserNotificationsSuccess:^{
        
        if (self.notificationVM.notificationItems.count == 0)
            self.tableViewType = WTTableViewTypeNoData;
        else
            self.tableViewType = WTTableViewTypeNormal;
        
        [self.tableView reloadData];
        
        [self.tableView.mj_header endRefreshing];
        
    } failure:^(NSError *error) {
        [self.tableView.mj_header endRefreshing];
    }];
}

#pragma mark 加载旧的数据
- (void)loadOldData
{
    if (self.notificationVM.isNextPage)
    {
        self.notificationVM.page ++;
        
        [self.notificationVM getUserNotificationsSuccess:^{
            
            [self.tableView reloadData];
            
            [self.tableView.mj_footer endRefreshing];
            
        } failure:^(NSError *error) {
            [self.tableView.mj_footer endRefreshing];
        }];
    }
    else
    {
        [self.tableView.mj_footer endRefreshing];
    }
}

#pragma mark - 事件
- (void)goToLoginVC
{
    WTLoginViewController *loginVC = [WTLoginViewController new];
    [self presentViewController: loginVC animated: YES completion: nil];
}

#pragma mark - Table view data source
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.notificationVM.notificationItems.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    WTNotificationCell *cell = [tableView dequeueReusableCellWithIdentifier: ID];
    
    cell.noticationItem = self.notificationVM.notificationItems[indexPath.row];
    
    cell.delegate = self;
    
    return cell;
}

#pragma mark - Table view data source
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    WTTopicDetailViewController *topicDetailVC = [WTTopicDetailViewController topicDetailViewController];
    WTNotificationItem *notificationItem = self.notificationVM.notificationItems[indexPath.row];
    topicDetailVC.topicDetailUrl = notificationItem.detailUrl;
    topicDetailVC.topicTitle = notificationItem.title;
    [self.navigationController pushViewController: topicDetailVC animated: YES];
}

#pragma mark - WTNotificationCellDelegate
- (void)notificationCell:(WTNotificationCell *)notificationCell didClickWithNoticationItem:(WTNotificationItem *)noticationItem
{
    __weak typeof(self) weakSelf = self;
    // 删除通知
    [self.notificationVM deleteNotificationByNoticationItem: noticationItem success:^{
        
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow: [weakSelf.notificationVM.notificationItems indexOfObject: noticationItem] inSection: 0];
        
        [weakSelf.notificationVM.notificationItems removeObject: noticationItem];
        [weakSelf.tableView deleteRowsAtIndexPaths: @[indexPath] withRowAnimation: UITableViewRowAnimationMiddle];
        
//        if (weakSelf.notificationVM.notificationItems.count == 0)
//        {
//            [weakSelf.tableView reloadData];
//        }
        
    } failure:^(NSError *error) {
        
    }];
}


#pragma mark - DZNEmptyDataSetSource
- (NSAttributedString *)titleForEmptyDataSet:(UIScrollView *)scrollView
{
    NSMutableDictionary *attributes = [NSMutableDictionary new];
    NSString *text = nil;
    if (self.tableViewType == WTTableViewTypeNoData)
    {
        text = @"还没有收到通知";
        [attributes setObject: [UIColor colorWithHexString: @"#BDBDBD"] forKey: NSForegroundColorAttributeName];
        return [[NSAttributedString alloc] initWithString: text attributes:attributes];
    }
    
    return nil;
}

- (UIImage *)imageForEmptyDataSet:(UIScrollView *)scrollView
{
        return [UIImage imageNamed:@"no_notification"];
}

- (NSAttributedString *)buttonTitleForEmptyDataSet:(UIScrollView *)scrollView forState:(UIControlState)state
{
    NSMutableDictionary *attributes = [NSMutableDictionary new];
    [attributes setObject: WTSelectedColor forKey: NSForegroundColorAttributeName];
    [attributes setObject: [UIFont systemFontOfSize: 18 weight: UIFontWeightMedium] forKey: NSFontAttributeName];
    return [[NSAttributedString alloc] initWithString: @"登陆" attributes:attributes];
}


- (BOOL)emptyDataSetShouldAllowTouch:(UIScrollView *)scrollView
{
    return YES;
}

- (void)emptyDataSet:(UIScrollView *)scrollView didTapButton:(UIButton *)button
{
    WTLoginViewController *loginVC = [WTLoginViewController new];
    __weak typeof(self) weakSelf = self;
    loginVC.loginSuccessBlock = ^{
        [weakSelf loadNewData];
    };
    [[UIViewController topVC] presentViewController: loginVC animated: YES completion: nil];
}

#pragma mark - Lazy

@end
