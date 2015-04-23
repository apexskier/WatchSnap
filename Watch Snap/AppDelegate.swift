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
            var watchWidth: CGFloat = 300
            if let w = userInfo?["width"] as? CGFloat {
                if w > 0 {
                    watchWidth = w
                }
            }

            // set up a one time wait for the viewcontroller to notify with the image data
            var observer: NSObjectProtocol? = nil
            observer = NSNotificationCenter.defaultCenter().addObserverForName("imageData", object: nil, queue: nil, usingBlock: { (notification: NSNotification!) in
                if let fulldata = notification.object as? NSData {
                    if let fullimage = UIImage(data: fulldata) {
                        var sentimage = squareImageToSize(fullimage, watchWidth)
                        switch UIDevice.currentDevice().orientation {
                        case .LandscapeLeft:
                            sentimage = sentimage.imageRotatedByRadians(CGFloat(M_PI / 2))
                        case .LandscapeRight:
                            sentimage = sentimage.imageRotatedByRadians(CGFloat(-M_PI / 2))
                        default:
                            break
                        }
                        reply([
                            "image": UIImageJPEGRepresentation(sentimage, 90)
                        ])
                    } else {
                        reply(["error": "failed"])
                    }
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

func squareImageToSize(image: UIImage, newSize: CGFloat) -> UIImage {
    let squareSize = CGSize(width: newSize, height: newSize)

    var ratio: CGFloat
    var delta: CGFloat
    var offset: CGPoint

    //figure out if the picture is landscape or portrait, then
    //calculate scale factor and offset
    if (image.size.width > image.size.height) {
        ratio = newSize / image.size.width;
        delta = (ratio * image.size.width - ratio * image.size.height);
        offset = CGPointMake(delta/2, 0);
    } else {
        ratio = newSize / image.size.height;
        delta = (ratio * image.size.height - ratio * image.size.width);
        offset = CGPointMake(0, delta/2);
    }
    let clipRect = CGRect(x: -offset.x, y: -offset.y,
        width: (ratio * image.size.width) + delta,
        height: (ratio * image.size.height) + delta)

    if UIScreen.mainScreen().respondsToSelector("scale") {
        UIGraphicsBeginImageContextWithOptions(squareSize, true, 0)
    } else {
        // NOTE: This one will be faster, since it's less data.
        UIGraphicsBeginImageContext(squareSize)
    }

    UIRectClip(clipRect)
    image.drawInRect(clipRect)
    let newImage = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()

    return newImage
}

extension UIImage {
    public func imageRotatedByRadians(radians: CGFloat) -> UIImage {
        // calculate the size of the rotated view's containing box for our drawing space
        let rotatedViewBox = UIView(frame: CGRect(origin: CGPointZero, size: size))
        let t = CGAffineTransformMakeRotation(radians);
        rotatedViewBox.transform = t
        let rotatedSize = rotatedViewBox.frame.size

        // Create the bitmap context
        if UIScreen.mainScreen().respondsToSelector("scale") {
            UIGraphicsBeginImageContextWithOptions(rotatedSize, true, 0)
        } else {
            // NOTE: This one will be faster, since it's less data.
            UIGraphicsBeginImageContext(rotatedSize)
        }
        let bitmap = UIGraphicsGetCurrentContext()

        // Move the origin to the middle of the image so we will rotate and scale around the center.
        CGContextTranslateCTM(bitmap, rotatedSize.width / 2.0, rotatedSize.height / 2.0);

        //   // Rotate the image context
        CGContextRotateCTM(bitmap, radians);

        // Now, draw the rotated/scaled image into the context
        CGContextScaleCTM(bitmap, 1.0, -1.0)
        CGContextDrawImage(bitmap, CGRectMake(-size.width / 2, -size.height / 2, size.width, size.height), CGImage)

        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return newImage
    }
}