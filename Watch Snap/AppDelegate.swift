//
//  AppDelegate.swift
//  Watch Snap
//
//  Created by Cameron Little on 4/22/15.
//  Copyright (c) 2015 Cameron Little. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Override point for customization after application launch.

        //application.registerUserNotificationSettings(UIUserNotificationSettings(forTypes: .Alert, categories: nil))
        return true
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }

    func application(application: UIApplication, handleWatchKitExtensionRequest userInfo: [NSObject : AnyObject]?, reply: (([NSObject : AnyObject]!) -> Void)!) {
        if application.applicationState != .Active {
            reply(["error": "notactive"])
            return
        }
        if let requestType = userInfo?["type"] as? String {
            // set up a one time wait for the viewcontroller to notify with the image data
            var observer: NSObjectProtocol? = nil
            observer = NSNotificationCenter.defaultCenter().addObserverForName("imageData", object: nil, queue: nil, usingBlock: { (notification: NSNotification!) in
                if let fulldata = notification.object as? NSData {
                    let size = CGSize(width: 312, height: 390)
                    let fullimage = UIImage(data: fulldata)
                    UIGraphicsBeginImageContext(size)
                    fullimage?.drawInRect(CGRect(x: 0, y: 0, width: size.width, height: size.height))
                    let newimage = UIGraphicsGetImageFromCurrentImageContext()
                    UIGraphicsEndImageContext()

                    reply(["image": UIImageJPEGRepresentation(newimage, 90)])
                } else {
                    reply(["error": "failed"])
                }
                NSNotificationCenter.defaultCenter().removeObserver(observer!)
            })

            let view = window?.rootViewController as! ViewController

            switch requestType {
            case "ImageUpdate":
                view.getImageData()
            case "TakePhoto":
                view.takePhoto()
            default:
                fatalError("Unknown request type")
            }
        } else {
            fatalError("No request type")
        }
    }
}