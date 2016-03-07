//
//  TLConversationViewController.m
//  TLChat
//
//  Created by 李伯坤 on 16/1/23.
//  Copyright © 2016年 李伯坤. All rights reserved.
//

#import "TLConversationViewController.h"
#import "TLFriendSearchViewController.h"
#import "TLChatViewController.h"
#import "TLConversationCell.h"
#import "TLSearchController.h"
#import "TLFriendHelper.h"
#import <UIImageView+WebCache.h>
#import <AFNetworking.h>

#define     HEIGHT_CONVERSATION_CELL        65.0f

@interface TLConversationViewController () <UISearchBarDelegate>

@property (nonatomic, strong) UIImageView *scrollTopView;

@property (nonatomic, strong) NSMutableArray *data;

@property (nonatomic, strong) TLSearchController *searchController;
@property (nonatomic, strong) TLFriendSearchViewController *searchVC;

@end

@implementation TLConversationViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.navigationItem setTitle:@"微信"];
    
    [self p_initUI];        // 初始化界面UI
    
    [self.tableView registerClass:[TLConversationCell class] forCellReuseIdentifier:@"TLConversationCell"];
    
    //TODO: Do not work
    UITapGestureRecognizer *tapGes = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doubleClick)];
    [tapGes setNumberOfTapsRequired:2];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(networkStatusChange:) name:AFNetworkingReachabilityDidChangeNotification object:nil];
    
    [self initTestData];
}

- (void) doubleClick
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Double Click Tab Bar" message:nil delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
    [alert show];
}

#pragma mark - Delegate -
//MARK: UITableViewDataSource
- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.data.count;
}

- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    TLConversation *conversation = [self.data objectAtIndex:indexPath.row];
    TLConversationCell *cell = [tableView dequeueReusableCellWithIdentifier:@"TLConversationCell"];
    [cell setConversation:conversation];
    
    [cell setTopLineStyle:indexPath.row == 0 ? TLCellLineStyleFill : TLCellLineStyleNone];
    [cell setBottomLineStyle:indexPath.row == self.data.count - 1 ? TLCellLineStyleFill : TLCellLineStyleDefault];
    
    return cell;
}

//MARK: UITableViewDelegate
- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return HEIGHT_CONVERSATION_CELL;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    
    TLChatViewController *chatVC = [TLChatViewController sharedChatVC];
    
    TLConversation *conversation = [self.data objectAtIndex:indexPath.row];
    if (conversation.convType == TLConversationTypePersonal) {
        TLUser *user = [[TLFriendHelper sharedFriendHelper] getFriendInfoByUserID:conversation.userID];
        if (user == nil) {
            [UIAlertView alertWithTitle:@"错误" message:@"您不存在此好友"];
            return;
        }
        [chatVC setUser:user];
    }
    else {
        [chatVC setUser:nil];
    }
    [self setHidesBottomBarWhenPushed:YES];
    [self.navigationController pushViewController:chatVC animated:YES];
    [self setHidesBottomBarWhenPushed:NO];
    
    // 标为已读
    [(TLConversationCell *)[self.tableView cellForRowAtIndexPath:indexPath] markAsRead];
}

- (NSArray *) tableView:(UITableView *)tableView editActionsForRowAtIndexPath:(NSIndexPath *)indexPath
{
    TLConversation *conversation = [self.data objectAtIndex:indexPath.row];
    __weak typeof(self) weakSelf = self;
    UITableViewRowAction *delAction = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleDefault
                                                                         title:@"删除"
                                                                       handler:^(UITableViewRowAction *action, NSIndexPath *indexPath)
    {
        [weakSelf.data removeObjectAtIndex:indexPath.row];
        [weakSelf.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        if (self.data.count > 0 && indexPath.row == self.data.count) {
            NSIndexPath *lastIndexPath = [NSIndexPath indexPathForRow:indexPath.row - 1 inSection:indexPath.section];
            TLConversationCell *cell = [self.tableView cellForRowAtIndexPath:lastIndexPath];
            [cell setBottomLineStyle:TLCellLineStyleFill];
        }
    }];
    UITableViewRowAction *moreAction = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleDefault
                                                                          title:conversation.isRead ? @"标为未读" : @"标为已读"
                                                                        handler:^(UITableViewRowAction *action, NSIndexPath *indexPath)
    {
        TLConversationCell *cell = [tableView cellForRowAtIndexPath:indexPath];
        conversation.isRead ? [cell markAsUnread] : [cell markAsRead];
        [tableView setEditing:NO animated:YES];
    }];
    moreAction.backgroundColor = [UIColor colorCellMoreButton];
    return @[delAction, moreAction];
}

- (CGFloat) tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return 0.5;
}

//MARK: UISearchBarDelegate
- (void) searchBarTextDidBeginEditing:(UISearchBar *)searchBar
{
    [self.searchVC setFriendsData:[TLFriendHelper sharedFriendHelper].friendsData];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:YES];
}

- (void) searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    [self.tabBarController.tabBar setHidden:YES];
}

- (void) searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    [self.tabBarController.tabBar setHidden:NO];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent animated:YES];
}

- (void) searchBarBookmarkButtonClicked:(UISearchBar *)searchBar
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"语音搜索按钮" message:nil delegate:nil cancelButtonTitle:@"确定" otherButtonTitles: nil];
    [alert show];
}

#pragma mark - Event Response
- (void) rightBarButtonDown:(UIBarButtonItem *)sender
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Right Bar Button Down!" message:nil delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
    [alert show];
}

- (void) networkStatusChange:(NSNotification *)noti
{
    AFNetworkReachabilityStatus status = [noti.userInfo[@"AFNetworkingReachabilityNotificationStatusItem"] longValue];
    switch (status) {
        case AFNetworkReachabilityStatusReachableViaWiFi:
        case AFNetworkReachabilityStatusReachableViaWWAN:
        case AFNetworkReachabilityStatusUnknown:
            self.navigationItem.title = @"微信";
            break;
        case AFNetworkReachabilityStatusNotReachable:
            self.navigationItem.title = @"微信(未连接)";
            break;
        default:
            break;
    }
}

#pragma mark - Private Methods -
- (void) p_initUI
{
    [self.tableView setBackgroundColor:[UIColor whiteColor]];
    [self.tableView setTableHeaderView:self.searchController.searchBar];
    
    [self.tableView addSubview:self.scrollTopView];
    [self.scrollTopView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.mas_equalTo(self.tableView);
        make.bottom.mas_equalTo(self.tableView.mas_top).mas_offset(-35);
    }];
    
    UIBarButtonItem *rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"nav_add"] style:UIBarButtonItemStyleDone target:self action:@selector(rightBarButtonDown:)];
    [self.navigationItem setRightBarButtonItem:rightBarButtonItem];
}

- (void) initTestData
{
    NSArray *jsonData = @[@{
                              @"userID":@"u1007",
                              @"username":@"莫小贝",
                              @"messageDetail":@"帅哥你好啊!",
                              @"avatarURL":@"http://tx.haiqq.com/uploads/allimg/150323/1513261b8-0.jpg",
                              },
                          @{
                              @"userID":@"g001",
                              @"username":@"刘亦菲、IU、汤唯、刘诗诗、杨幂、Baby",
                              @"messageDetail":@"凤姐：什么鬼，我为什么会在这个群组里面？?",
                              @"avatarURL":@"http://img4.duitang.com/uploads/item/201510/16/20151016113134_TZye4.thumb.224_0.jpeg",
                              }
                          ];
    self.data = [TLConversation mj_objectArrayWithKeyValuesArray:jsonData];
    TLConversation *conv = self.data[1];
    conv.remindType = TLMessageRemindTypeClosed;
    conv.convType = TLConversationTypePublic;
    conv.date = [NSDate date];
    
    [self.data[0] setDate:[NSDate date]];
}

#pragma mark - Getter -
- (TLSearchController *) searchController
{
    if (_searchController == nil) {
        _searchController = [[TLSearchController alloc] initWithSearchResultsController:self.searchVC];
        [_searchController setSearchResultsUpdater:self.searchVC];
        [_searchController.searchBar setPlaceholder:@"搜索"];
        [_searchController.searchBar setDelegate:self];
        [_searchController setShowVoiceButton:YES];
    }
    return _searchController;
}

- (TLFriendSearchViewController *) searchVC
{
    if (_searchVC == nil) {
        _searchVC = [[TLFriendSearchViewController alloc] init];
    }
    return _searchVC;
}

- (UIImageView *)scrollTopView
{
    if (_scrollTopView == nil) {
        _scrollTopView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"conv_wechat_icon"]];
    }
    return _scrollTopView;
}

@end
