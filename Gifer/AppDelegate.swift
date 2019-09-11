//
//  AppDelegate.swift
//  Gifer
//
//  Created by Frank Cheng on 2018/11/8.
//  Copyright © 2018 Frank Cheng. All rights reserved.
//

import UIKit
import Photos
import MonkeyKing
//import TwitterKit


enum UserDefaultKeys: String {
    case gifMaxDuration = "gifMaxDuration"
    case shareTimes
}

@UIApplicationMain
 class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        MonkeyKing.registerAccount(.weChat(appID: "wx842039e20182b59f", appKey: "735d250087f7f9ba0c3797595995e981", miniAppID: nil))
        // Override point for customization after application launch.
        initUserDefaults()
        
        #if DEBUG        
        let debugStoryboard =
//            AppStoryboard.Main
//            AppStoryboard.Album
            AppStoryboard.Edit
//            AppStoryboard.Sticker
//            AppStoryboard.Test
//            AppStoryboard.Frame
//            AppStoryboard.Camera

        let rootVC = debugStoryboard.instance.instantiateInitialViewController()
        window?.rootViewController = rootVC
        window?.makeKeyAndVisible()
        #else
        //Don't touch here
        let rootVC = AppStoryboard.Main.instance.instantiateViewController(withIdentifier: "root")
        window?.rootViewController = rootVC
        window?.makeKeyAndVisible()
        #endif
        
        return true
    }
    
    func initUserDefaults() {
        let defaults = UserDefaults.standard
        if defaults.object(forKey: UserDefaultKeys.gifMaxDuration.rawValue) == nil {
            defaults.set(8, forKey: UserDefaultKeys.gifMaxDuration.rawValue)
        }
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        if MonkeyKing.handleOpenURL(url) {
            return true
        }
        
        return false
    }
}
