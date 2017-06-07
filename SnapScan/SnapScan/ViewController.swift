//
//  ViewController.swift
//  SnapScan
//
//  Created by Bryan Fox on 6/5/17.
//  Copyright © 2017 Bryan Fox. All rights reserved.
//

import UIKit
import RealmSwift

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

// MARK: -

private typealias IBActions = ViewController
extension IBActions {
    @IBAction func buttonPressed(_ sender: Any) {
        if (UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.camera)) {
            launchCamera()
        } else {
            alert("No camera available on this device")
        }
    }

    private func launchCamera() {
        let picker = UIImagePickerController.init()
        picker.delegate = self;
        picker.sourceType = UIImagePickerControllerSourceType.camera
        picker.showsCameraControls = true;
        picker.videoQuality = UIImagePickerControllerQualityType.typeHigh
        picker.cameraCaptureMode = UIImagePickerControllerCameraCaptureMode.photo
        // TODO: app setting for picker.cameraFlashMode?
        // XXX: for quicker debugging with low-res
        //         picker.allowsEditing = true
        present(picker, animated: true, completion: nil)
    }
}

private typealias ImagePickerDelegate = ViewController
extension ImagePickerDelegate : UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        picker.dismiss(animated: true, completion: nil)

        // Can be very slow: image size + accuracy/engineMode are the two main vars.
        // TODO: add resizing (app setting?)
        // TODO: log image size
        // XXX: see allowsEditing above
        //        guard let img = info[UIImagePickerControllerEditedImage] as? UIImage else {
        guard let img = info[UIImagePickerControllerOriginalImage] as? UIImage else {
            alert("Image not available")
            return
        }

        guard let pdfFile = PDFScanner.init().savePDF(from: img, with: PDFScannerAccuracyLow) else {
            alert("Scan failed!")
            return
        }

        print("filename: \(pdfFile)")

        let scan = ScanResult.create(pdfUrl: pdfFile, recognizedText: "")
        do {
            // TODO: Retries
            try scan.save()
        } catch is ScanResultError {
            alert("Could not save PDF")
        } catch {
            print("Unkown scanning error occured")
        }

        sharePdf(pdfFile)
    }

}

private typealias Alerts = ViewController
extension Alerts {
    func alert(_ message: String, title: String = "Alert") {
        let alert = UIAlertController.init(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
        let alertAction = UIAlertAction.init(title: "OK", style: UIAlertActionStyle.default, handler: nil)
        alert.addAction(alertAction)
        present(alert, animated: true)
    }
}

private typealias ShareSheet = ViewController
extension ShareSheet {
    func documentsDirectory() -> String? {
        let urls:[URL] = FileManager.default.urls(for: FileManager.SearchPathDirectory.documentDirectory,
                                                  in: FileManager.SearchPathDomainMask.userDomainMask)
        return urls.last?.absoluteString
    }

    func sharePdf(_ filePath: String) {
        let url:URL = URL.init(fileURLWithPath: filePath)
        let shareSheet = UIActivityViewController.init(activityItems: [url], applicationActivities: nil);
        present(shareSheet, animated: true)
    }

}
