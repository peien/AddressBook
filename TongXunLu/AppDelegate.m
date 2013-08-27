//
//  AppDelegate.m
//  TongXunLu
//
//  Created by QuanMai on 13-3-8.
//  Copyright (c) 2013年 QuanMai. All rights reserved.
//

#import "AppDelegate.h"

#import "FirstViewController.h"
#import "ConfigViewController.h"
//#import "POAPinyin.h"
#import "TokenManager.h"
#import "AuthViewController.h"
#import "CfgManager.h"

#import "BaiduMobStat.h"
#import "Tab3DeptViewController.h"
#import "Department.h"
#import "Second2ViewController.h"
#import "NetClient+ToPath.h"
#import "SearchIndex.h"
#import "SHMUser.h"
#import "GestureLock.h"
#import "DrawPatternLockViewController.h"
#import "SHMUser.h"

@implementation AppDelegate
{
    BOOL hasCheckNew;
}



- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]] ;
    [self.window makeKeyAndVisible];
    
  //  [self initDBCreate];
    [self baiduMobStat];
    //[self generateSampleContacts];
    
    AuthViewController *auc = [[AuthViewController alloc] init] ;
    
    
    
    self.window.rootViewController = auc;
    //return YES;
    if ([TokenManager getToken] == nil || [[TokenManager getToken] isEqualToString:@""]) {
        //验证界面
        [auc displayAuthView];
        [[BaiduMobStat defaultStat] pageviewStartWithName:@"登录界面"];
    }else
    {
        //如果有token，则先从服务器端获取所有联系人
        [auc getAllContacts:[TokenManager getToken]];
    }

    return YES;
}

- (void)baiduMobStat
{
    BaiduMobStat* statTracker = [BaiduMobStat defaultStat];
    statTracker.enableExceptionLog = NO;
    statTracker.channelId = @"Address Book 0";
    //statTracker.enableExceptionLog = NO;
    statTracker.sessionResumeInterval = 60;
    [statTracker startWithAppId:@"65d1354eeb"];
}

-(void)initDBCreate
{
    NSString *bundlePath = [[NSBundle mainBundle]  pathForResource:@"tongxunludb" ofType:@"db" inDirectory:@""];
    NSString *documentsPath = [[NSHomeDirectory() stringByAppendingPathComponent:@"Documents"] stringByAppendingPathComponent:@"tongxunludb.db"];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:documentsPath]) {
        [fileManager copyItemAtPath:bundlePath toPath:documentsPath error:nil];
        DLog(@"copy bundlepath:%@ to document path%@",bundlePath,documentsPath);
    }
}

-(void)initTabs
{
       
    DLog(@"initTabs");
    UIViewController *viewController1 = [[FirstViewController alloc] init];
    UIViewController *viewController2 = [[Second2ViewController alloc] init];
   
    Tab3DeptViewController *viewController3_0 = [[Tab3DeptViewController alloc] init];
    viewController3_0.dept = [Department objectByKey:@"level" value:@"0" createIfNone:NO];
    ConfigViewController *viewController4 = [[ConfigViewController alloc] initWithStyle:UITableViewStyleGrouped];
    
    
    UINavigationController *CommonUsedNavigationController
    = [[UINavigationController alloc] initWithRootViewController:viewController1];
    CommonUsedNavigationController.tabBarItem.title = @"";

    UINavigationController *MyDepartmentNavigationController
    = [[UINavigationController alloc] initWithRootViewController:viewController2];
    MyDepartmentNavigationController.tabBarItem.title = @"";

    UINavigationController *AllUnitsNavigationController
    = [[UINavigationController alloc] initWithRootViewController:viewController3_0];
    AllUnitsNavigationController.tabBarItem.title = @"";

    UINavigationController *ConfigNavigationController
    = [[UINavigationController alloc] initWithRootViewController:viewController4];
    ConfigNavigationController.tabBarItem.title = @"";

    [self styleNavgaionBar:CommonUsedNavigationController];
    [self styleNavgaionBar:MyDepartmentNavigationController];
    [self styleNavgaionBar:AllUnitsNavigationController];
    [self styleNavgaionBar:ConfigNavigationController];
    
    self.tabBarController = [[txlTabBarController alloc] init];
    self.tabBarController.viewControllers = @[CommonUsedNavigationController, MyDepartmentNavigationController,AllUnitsNavigationController,ConfigNavigationController];
    self.window.rootViewController = self.tabBarController;
    
    [self checkNew];
    hasCheckNew = YES;
}

- (void)checkNew
{
    if (![SearchIndex sharedIndexs].orgDataVersionsStr) {
        return;
    }
    [[NetClient sharedClient] doPath:@"post" path:@"system/checkVersion" parameters:@{@"osType":iosStr,@"appVersion":[SearchIndex sharedIndexs].appVersion,@"orgDataVersions":[SearchIndex sharedIndexs].orgDataVersionsStr} success:^(NSMutableDictionary *dic) {
        
        [SHMUser sharedUser].downloadURL = dic[@"downloadURL"];
        [SHMUser sharedUser].lastAPP = dic[@"lastAPP"];
        [SHMUser sharedUser].lastData = dic[@"lastData"];
        [SHMUser sharedUser].forceUpdateAPP = dic[@"forceUpdateAPP"];
        [SHMUser sharedUser].forceUpdateData = dic[@"forceUpdateData"];
        [((ConfigViewController *)((UINavigationController *)self.tabBarController.childViewControllers[3]).childViewControllers[0]).tableView reloadData];
        if ([[SHMUser sharedUser].lastAPP intValue] == 0&&[SHMUser sharedUser].downloadURL) {
            [self.tabBarController addNew];
            
            if([NetClient sharedClient].r.currentReachabilityStatus == ReachableViaWiFi){
                if ([[SHMUser sharedUser] canShowAlert]) {
                    UIAlertViewBlock *alert = [[UIAlertViewBlock alloc] initWithTitle:@"更新提示" message:@"有新版本的app,现在更新吗?" cancelButtonTitle:@"不，以后"
                                                                          clickButton:^(NSInteger indexButton){
                                                                              if (indexButton == 0) {
                                                                                  
                                                                              }
                                                                              if (indexButton == 1) {
                                                                                  [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[SHMUser sharedUser].downloadURL]];
                                                                              }
                                                                          } otherButtonTitles:@"好"];
                    [alert show];
                    [SHMUser sharedUser].dateShowAlertUpApp = [NSDate dateWithTimeIntervalSinceNow:0];
                }          
                
                
            }else{
                [self.tabBarController addNew];
               
            }            
        }else if([[SHMUser sharedUser].lastData intValue] == 0){
            [self.tabBarController addNew];
            
        }
        
        
    } failure:^(NSMutableDictionary *dic) {
        
        if ([dic[@"state"] isEqualToNumber:[NSNumber numberWithInt:409]]||[dic[@"state"] isEqualToNumber:[NSNumber numberWithInt:410]]) {
            [[QAlertView sharedInstance] showAlertText:dic[@"note"] fadeTime:2];
            [CfgManager setConfig:@"updated" detail:@"0"];
            [[TokenManager sharedInstance] setToken:@""];
            [CfgManager setConfig:@"departmentID" detail:nil];
            AuthViewController *auc = [[AuthViewController alloc]init];
            [[SHMData sharedData] removeContext];
            [self.tabBarController presentModalViewController:auc animated:NO];
            [auc displayAuthView];
            return;
        }
        
        if ([dic[@"state"] isEqualToNumber:[NSNumber numberWithInt:304]]) {
            [SHMUser sharedUser].downloadURL = nil;
            [SHMUser sharedUser].lastAPP = [NSNumber numberWithInt:1];
            [SHMUser sharedUser].lastData = [NSNumber numberWithInt:1];
            [SHMUser sharedUser].forceUpdateAPP = [NSNumber numberWithInt:0];
            [SHMUser sharedUser].forceUpdateData = [NSNumber numberWithInt:0];
            [self.tabBarController removeNew];
            [((ConfigViewController *)((UINavigationController *)self.tabBarController.childViewControllers[3]).childViewControllers[0]).tableView reloadData];
        }
        if (([SHMUser sharedUser].lastAPP&&[[SHMUser sharedUser].lastAPP intValue] == 0)||([SHMUser sharedUser].lastData&&[[SHMUser sharedUser].lastData intValue] == 0)) {
            [self.tabBarController addNew];
        }
    } withToken:YES toJson:YES isNotForm:NO parameterEncoding:AFFormURLParameterEncoding];
}


-(void)styleNavgaionBar:(UINavigationController *)navigationController
{
    [navigationController.navigationBar setBackgroundImage:[UIImage imageNamed:@"navbar.png"] forBarMetrics:0];
}

//测试用
//-(void)generateSampleContacts
//{
//    //DLog(@"林长春 %@",[POAPinyin quickConvert:@"林长春"]);
//    NSArray *temp = [POAPinyin makePinYin:@"长"];
//    for (int i=0;i< [temp count];i++)
//        DLog(@"林长春 %@",[temp objectAtIndex:i]);
//}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    [GestureLock sharedLock].backDate = [NSDate new];
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    [[NetClient sharedClient] doPath:@"post" path:@"recordOpenApp" parameters:nil success:^(NSMutableDictionary *dic) {        
    } failure:^(NSMutableDictionary *dic) {        
    } withToken:YES toJson:NO isNotForm:YES parameterEncoding:AFFormURLParameterEncoding];
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    if ([GestureLock sharedLock].onLock && [[GestureLock sharedLock] needShowLock]) {
        
        DrawPatternLockViewController *dpViewConPro = [[DrawPatternLockViewController alloc]init];
        dpViewConPro.typeLock = typeLockGo;
        [self.tabBarController presentModalViewController:dpViewConPro animated:NO];
        
    }
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    if (hasCheckNew) {
        hasCheckNew = NO;
        return;
    }
    [self checkNew]; 
    
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

/*
// Optional UITabBarControllerDelegate method.
- (void)tabBarController:(UITabBarController *)tabBarController didSelectViewController:(UIViewController *)viewController
{
}
*/

/*
// Optional UITabBarControllerDelegate method.
- (void)tabBarController:(UITabBarController *)tabBarController didEndCustomizingViewControllers:(NSArray *)viewControllers changed:(BOOL)changed
{
}
*/

@end