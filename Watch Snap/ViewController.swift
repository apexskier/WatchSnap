//
//  ViewController.swift
//  Watch Snap
//
//  Created by Cameron Little on 4/22/15.
//  Copyright (c) 2015 Cameron Little. All rights reserved.
//

import UIKit
import AVFoundation
import Photos

extension UIViewController {
    func alertError(message: String, handler: (() -> Void)) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .Alert)
        if (isViewLoaded() && view.window != nil) {
            presentViewController(alert, animated: true) {}
        } else {
            // recurse up window hierarchy
            if let parent = parentViewController {
                parent.alertError(message, handler: handler)
            } else {
                println(message)
                handler()
            }
        }
    }
}

class ViewController: UIViewController {
    @IBOutlet var mainView: UIView!

    private var appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate

    private var cameraSession: AVCaptureSession?
    private var cameraInput: AVCaptureDeviceInput?
    private var cameraPreviewLayer: AVCaptureVideoPreviewLayer?
    private var imageOutput: AVCaptureStillImageOutput?

    func die(error: NSError?) {
        var message = "A fatal error happened.\n\(error?.usefulDescription)"
        alertError(message) {}
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        if let error = setupCamera() {
            die(error)
        }
        setupPhotos()
    }

    func setupPhotos() {
        if PHPhotoLibrary.authorizationStatus() != .Authorized {
            PHPhotoLibrary.requestAuthorization() { (status: PHAuthorizationStatus) -> Void in
                switch status {
                case .Restricted:
                    self.alertError("Your device does not allow access to your photo library, so you cannot use this app.") {}
                case .Denied:
                    fallthrough
                case .NotDetermined:
                    self.alertError("You must allow acess to your photo library to use this app.") {}
                case .Authorized:
                    break
                }
            }
        }
    }

    func setupCamera() -> NSError? {
        var error: NSError?

        // Camera capture session
        cameraSession = AVCaptureSession()
        //cameraSession!.sessionPreset = AVCaptureSessionPresetPhoto

        // input device
        if let camera = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo) {
            // set camera configuration
            /*camera.lockForConfiguration(&error)
            if error != nil {
            self.die(error)
            }
            camera.unlockForConfiguration()*/

            cameraInput = AVCaptureDeviceInput.deviceInputWithDevice(camera, error: &error) as? AVCaptureDeviceInput
            if error != nil {
                return error
            }

            if !self.cameraSession!.canAddInput(cameraInput) {
                return NSError(domain: "Can't add camera input", code: 1, userInfo: nil)
            }
            self.cameraSession!.addInput(cameraInput)

            // set visual camera preview up
            cameraPreviewLayer = AVCaptureVideoPreviewLayer.layerWithSession(self.cameraSession) as? AVCaptureVideoPreviewLayer
            cameraPreviewLayer!.frame = self.mainView.bounds
            cameraPreviewLayer!.connection.videoScaleAndCropFactor = 1
            self.mainView.layer.insertSublayer(cameraPreviewLayer!, atIndex: 0)

            // get connection to capture pictures from
            imageOutput = AVCaptureStillImageOutput()
            cameraSession!.addOutput(imageOutput)

            // start the preview up
            cameraSession!.startRunning()
            return nil
        }
        return NSError(domain: "Couldn't setup camera", code: 1, userInfo: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func takePhoto() {
        let connection = self.imageOutput!.connectionWithMediaType(AVMediaTypeVideo)
        imageOutput!.captureStillImageAsynchronouslyFromConnection(connection, completionHandler: { (sampleBuffer: CMSampleBuffer!, error: NSError!) -> Void in
            self.cameraSession?.stopRunning()
            if error != nil {
                self.die(error)
            } else {
                let imageData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(sampleBuffer)
                if let image = UIImage(data: imageData) {
                    // cool! save to library
                }
            }
            self.cameraSession?.startRunning()
        })
    }
}

