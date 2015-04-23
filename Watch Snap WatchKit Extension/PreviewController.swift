//
//  InterfaceController.swift
//  Watch Snap WatchKit Extension
//
//  Created by Cameron Little on 4/22/15.
//  Copyright (c) 2015 Cameron Little. All rights reserved.
//

import WatchKit
import Foundation

// NOTE: I'm doing the delay on the watch to potentially display some ui countdown


class PreviewController: WKInterfaceController {
    @IBOutlet weak var image: WKInterfaceImage!
    @IBOutlet weak var label: WKInterfaceLabel!

    var ready = false
    var width: CGFloat = 0

    @IBAction func imageTap() {
        if ready {
            snapPhoto()
        }
    }
    @IBOutlet weak var timerElement: WKInterfaceTimer!

    @IBAction func snap10SecDelay() {
        if ready {
            delaySnapPhoto(10)
        }
    }
    @IBAction func snap2SecDelay() {
        if ready {
            delaySnapPhoto(2)
        }
    }

    var updateLoop: NSTimer?

    func delaySnapPhoto(delay: NSTimeInterval) {
        let target = NSDate().dateByAddingTimeInterval(delay)
        timerElement.setHidden(false)
        timerElement.setDate(target)
        timerElement.start()
        NSRunLoop.currentRunLoop().addTimer(NSTimer(fireDate: target, interval: 0, target: self, selector: "snapPhoto", userInfo: nil, repeats: false), forMode: NSDefaultRunLoopMode)
    }
    func snapPhoto() {
        self.updateLoop?.invalidate()
        let now = NSDate()
        let request: [NSObject: AnyObject] = [
            "type": "TakePhoto",
            "width": width
        ]
        if !WKInterfaceController.openParentApplication(request, reply: { (response: [NSObject : AnyObject]!, error: NSError!) -> Void in
            if error != nil || response == nil {
                println(error.usefulDescription)
                self.displayOpenApp()
            } else if let imageData = response["image"] as? NSData {
                self.pushControllerWithName("Display", context: imageData)
            } else {
                println("no image data")
                self.displayError()
            }
        }) {
            self.displayOpenApp()
        }
    }

    func updateImage() {
        let request: [NSObject: AnyObject] = [
            "type": "ImageUpdate",
            "width": width
        ]
        if !WKInterfaceController.openParentApplication(request, reply: { (response: [NSObject : AnyObject]!, error: NSError!) -> Void in
            if error != nil || response == nil {
                println(error.usefulDescription)
                self.displayError()
            } else if let message = response["error"] as? String {
                switch message {
                case "notactive":
                    self.displayOpenApp()
                case "failed":
                    self.displayError("Failed")
                default:
                    self.displayError()
                }
            } else if let imageData = response["image"] as? NSData {
                self.removeError()
                self.image.setImageData(imageData)
            } else {
                println("no image data")
                self.displayError()
            }
        }) {
            self.displayOpenApp()
        }
    }

    func displayOpenApp() {
        label.setText("Please open Watch Snap on your iPhone")
        label.setHidden(false)
        timerElement.setHidden(true)
        ready = false
    }

    func displayError(message: String) {
        label.setText(message)
        label.setHidden(false)
        image.setHidden(true)
        timerElement.setHidden(true)
        ready = false
    }

    func displayError() {
        label.setText("Error")
        label.setHidden(false)
        image.setHidden(true)
        timerElement.setHidden(true)
        ready = false
    }

    func removeError() {
        label.setHidden(true)
        image.setHidden(false)
        timerElement.setHidden(true)
        ready = true
    }

    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)

        // Configure interface objects here.
        updateImage()
        timerElement.setHidden(true)
        width = WKInterfaceDevice.currentDevice().screenBounds.width
        image.setHeight(width)
    }

    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()

        updateLoop = NSTimer(timeInterval: 1, target: self, selector: "updateImage", userInfo: nil, repeats: true)
        NSRunLoop.currentRunLoop().addTimer(updateLoop!, forMode: NSDefaultRunLoopMode)
    }

    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()

        updateLoop?.invalidate()
    }

}
