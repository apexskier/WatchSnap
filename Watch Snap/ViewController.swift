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
import AssetsLibrary

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
    private var cameraPreviewWrapper: UIView?
    private var imageOutput: AVCaptureStillImageOutput?

    func die(error: NSError?) {
        var message = "Error: \(error?.usefulDescription)"
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

    override func viewDidAppear(animated: Bool) {
        
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
        cameraSession!.sessionPreset = AVCaptureSessionPresetPhoto

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

            if !cameraSession!.canAddInput(cameraInput) {
                return NSError(domain: "Can't add camera input", code: 1, userInfo: nil)
            }
            cameraSession!.addInput(cameraInput)

            // set visual camera preview up
            cameraPreviewLayer = AVCaptureVideoPreviewLayer.layerWithSession(cameraSession) as? AVCaptureVideoPreviewLayer
            cameraPreviewLayer?.videoGravity = AVLayerVideoGravityResizeAspectFill
            cameraPreviewWrapper = UIView()
            cameraPreviewWrapper?.frame = mainView.bounds
            cameraPreviewLayer?.frame = cameraPreviewWrapper!.bounds
            cameraPreviewWrapper?.layer.addSublayer(cameraPreviewLayer!)
            mainView.insertSubview(cameraPreviewWrapper!, atIndex: 0)

            // get connection to capture pictures from
            imageOutput = AVCaptureStillImageOutput()
            cameraSession!.addOutput(imageOutput)

            // start the preview up
            cameraSession!.startRunning()
            return nil
        }
        return NSError(domain: "Couldn't setup camera", code: 1, userInfo: nil)
    }

    func getImageData() {
        captureImage { (imageData: NSData) -> Void in
            NSNotificationCenter.defaultCenter().postNotificationName("imageData", object: imageData)
        }
    }

    func takePhoto() {
        //cameraSession?.sessionPreset = AVCaptureSessionPresetPhoto
        let orientation: ALAssetOrientation = { () -> ALAssetOrientation in
            switch UIDevice.currentDevice().orientation {
            case .LandscapeLeft:
                return .Up
            case .LandscapeRight:
                return .Down
            default:
                return .Right
            }
        }()
        captureImage { (imageData: NSData) -> Void in
            if let image = UIImage(data: imageData) {
                let library = ALAssetsLibrary()
                library.writeImageToSavedPhotosAlbum(image.CGImage, orientation: orientation, completionBlock: { (url: NSURL!, error: NSError!) -> Void in
                    if error != nil {
                        NSNotificationCenter.defaultCenter().postNotificationName("imageData", object: imageData)
                    } else {
                        NSNotificationCenter.defaultCenter().postNotificationName("imageData", object: nil)
                    }
                })
            } else {
                NSNotificationCenter.defaultCenter().postNotificationName("imageData", object: nil)
            }
            //self.cameraSession?.sessionPreset = AVCaptureSessionPresetHigh
            //self.cameraPreviewLayer?.connection.videoOrientation = .Portrait
        }
    }

    func captureImage(handler: ((NSData) -> Void)) {
        let camera = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo)
        if let connection = self.imageOutput?.connectionWithMediaType(AVMediaTypeVideo) {
            imageOutput?.captureStillImageAsynchronouslyFromConnection(connection, completionHandler: { (sampleBuffer: CMSampleBuffer!, error: NSError!) -> Void in
                self.cameraSession?.stopRunning()
                if error != nil {
                    self.die(error)
                } else {
                    let imageData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(sampleBuffer)
                    handler(imageData)
                }
                self.cameraSession?.startRunning()
            })
        } else {
            //NSNotificationCenter.defaultCenter().postNotificationName("imageData", object: nil)
            handler(NSData())
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func willAnimateRotationToInterfaceOrientation(toInterfaceOrientation: UIInterfaceOrientation, duration: NSTimeInterval) {
        switch toInterfaceOrientation {
        case .LandscapeRight:
            cameraPreviewWrapper?.transform = CGAffineTransformMakeRotation(CGFloat(-M_PI/2))
        case .LandscapeLeft:
            cameraPreviewWrapper?.transform = CGAffineTransformMakeRotation(CGFloat(M_PI/2))
        default:
            cameraPreviewWrapper?.transform = CGAffineTransformMakeRotation(0)
        }
        cameraPreviewWrapper?.frame = mainView.bounds
    }

    @IBAction func tap(sender: AnyObject) {
        takePhoto()
    }

}
