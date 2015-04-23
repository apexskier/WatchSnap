//
//  DisplayController.swift
//  Watch Snap
//
//  Created by Cameron Little on 4/22/15.
//  Copyright (c) 2015 Cameron Little. All rights reserved.
//

import WatchKit
import Foundation


class DisplayController: WKInterfaceController {
    @IBOutlet weak var image: WKInterfaceImage!

    @IBAction func backTap() {
        popToRootController()
    }

    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)

        // Configure interface objects here.
        if let imageData = context as? NSData {
            image.setImageData(imageData)
        }
        let width = WKInterfaceDevice.currentDevice().screenBounds.width
        image.setHeight(width)
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