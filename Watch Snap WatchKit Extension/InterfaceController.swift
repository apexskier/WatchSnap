//
//  InterfaceController.swift
//  Watch Snap WatchKit Extension
//
//  Created by Cameron Little on 4/22/15.
//  Copyright (c) 2015 Cameron Little. All rights reserved.
//

import WatchKit
import Foundation


class InterfaceController: WKInterfaceController {
    @IBOutlet weak var image: WKInterfaceImage!
    @IBOutlet weak var label: WKInterfaceLabel!

    @IBAction func snap0SecDelay() {
        snapPhoto(0)
    }
    @IBAction func snap2SecDelay() {
        snapPhoto(2)
    }

    func snapPhoto(delay: Int) {
        let request: [NSObject: AnyObject] = [
            "type": "TakePhoto",
            "delay": delay
        ]
        if !WKInterfaceController.openParentApplication(request, reply: { (response: [NSObject : AnyObject]!, error: NSError!) -> Void in
            if error != nil {
                println(error.usefulDescription)
                self.label.setHidden(false)
                return
            }
            if response == nil {
                self.label.setHidden(false)
                return
            }
            if let imageData = response["image"] as? NSData {
                self.image.setImageData(imageData)
                self.label.setHidden(true)
            } else {
                println("no image data")
                self.label.setHidden(false)
            }
        }) {
            println("Something went wrong")
            label.setHidden(false)
        }
    }

    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)

        // Configure interface objects here.

        updateImage()
    }

    func updateImage() {
        label.setHidden(true)
        let request: [NSObject: AnyObject] = ["type": "ImageUpdate"]
        if !WKInterfaceController.openParentApplication(request, reply: { (response: [NSObject : AnyObject]!, error: NSError!) -> Void in
            if error != nil {
                println(error.usefulDescription)
                self.label.setHidden(false)
            }
            if let imageData = response["image"] as? NSData {
                self.image.setImageData(imageData)
                self.label.setHidden(false)
            } else {
                println("no image data")
                self.label.setHidden(false)
            }
        }) {
            println("Something went wrong")
            label.setHidden(false)
        }
    }

    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
    }

    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }

}
