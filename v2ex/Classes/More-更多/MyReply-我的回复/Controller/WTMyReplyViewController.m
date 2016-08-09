//
//  WTMyReplyViewController.m
//  v2ex
//
//  Created by 无头骑士 GJ on 16/8/2.
//  Copyright © 2016年 无头骑士 GJ. All rights reserved.
//  我的回复控制器

#import "WTMyReplyViewController.h"
#import "WTLoginViewController.h"
#import "WTTopicDetailViewController.h"

#import "WTReplyCell.h"
#import "WTRefreshNormalHeader.h"
#import "WTRefreshAutoNormalFooter.h"

#import "WTReplyViewModel.h"
#import "WTAccountViewModel.h"

#import "UITableView+FDTemplateLayoutCell.h"
#import <DZNEmptyDataSet/UIScrollView+EmptyDataSet.h>


@interface WTMyReplyViewController () <DZNEmptyDataSetSource, DZNEmptyDataSetDelegate>

@property (nonatomic, strong) WTReplyViewModel *replyVM;

@end

NSString * const WTReplyCellIdentifier = @"WTReplyCellIdentifier";

@implementation WTMyReplyViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // 设置View
    [self setupView];
    
    self.replyVM = [WTReplyViewModel new];
    
    // 2、登陆过
    if ([[WTAccountViewModel shareInstance] isLogin])
    {
        // 2、开始下拉刷新
        [self.tableView.mj_header beginRefreshing];
    }
}

// 设置View
- (void)setupView
{
    
    self.title = @"我的回复";
    
    // tableView
    {
        // 自动计算行高
        self.tableView.rowHeight = UITableViewAutomaticDimension;
        self.tableView.estimatedRowHeight = 128.5;
        
        self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        [self.tableView registerNib: [UINib nibWithNibName: NSStringFromClass([WTReplyCell class]) bundle: nil] forCellReuseIdentifier: WTReplyCellIdentifier];
        
        // 添加下拉刷新、上拉刷新
        self.tableView.mj_header = [WTRefreshNormalHeader headerWithRefreshingTarget: self refreshingAction: @selector(loadNewData)];
        self.tableView.mj_footer = [WTRefreshAutoNormalFooter footerWithRefreshingTarget: self refreshingAction: @selector(loadOldData)];
        
        // 空白tableView
        self.tableView.emptyDataSetSource = self;
        self.tableView.emptyDataSetDelegate = self;
    }

}

#pragma mark - 加载数据
#pragma mark 加载最新的数据
- (void)loadNewData
{
    self.replyVM.page = 1;

    [self.replyVM getReplyItemsWithUsername: [WTAccountViewModel shareInstance].account.usernameOrEmail success:^{
        
        [self.tableView reloadData];
        
        [self.tableView.mj_header endRefreshing];
        
    } failure:^(NSError *error) {
        [self.tableView.mj_header endRefreshing];
    }];
}

#pragma mark 加载旧的数据
- (void)loadOldData
{
    if (self.replyVM.isNextPage)
    {
        self.replyVM.page ++;
        
        [self.replyVM getReplyItemsWithUsername: [WTAccountViewModel shareInstance].account.usernameOrEmail success:^{
            
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

#pragma mark - UITableView DataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.replyVM.replyItems.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    WTReplyCell *cell = [tableView dequeueReusableCellWithIdentifier: WTReplyCellIdentifier];
    
    cell.replyItem = self.replyVM.replyItems[indexPath.row];
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [tableView fd_heightForCellWithIdentifier: WTReplyCellIdentifier cacheByIndexPath: indexPath configuration:^(WTReplyCell *cell) {
        cell.replyItem = self.replyVM.replyItems[indexPath.row];
    }];
}

#pragma mark - UITableView Delegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    WTTopicDetailViewController *topicDetailVC = [WTTopicDetailViewController new];
    topicDetailVC.topicDetailUrl = self.replyVM.replyItems[indexPath.row].detailUrl;
    [self.navigationController pushViewController: topicDetailVC animated: YES];
}

#pragma mark - DZNEmptyDataSetDelegate
- (void)emptyDataSet:(UIScrollView *)scrollView didTapButton:(UIButton *)button
{
    [self presentViewController: [WTLoginViewController new] animated: YES completion: nil];
}

- (BOOL)emptyDataSetShouldDisplay:(UIScrollView *)scrollView
{
    if ([[WTAccountViewModel shareInstance] isLogin])
    {
        return false;
    }
    return true;
}
@end
