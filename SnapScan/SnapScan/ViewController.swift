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

    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var debugLabel: UILabel!

    let fileManager:DefaultFileManager = DefaultFileManager.init()
    let itemsPerRow = 2
    var notificationToken: NotificationToken?
    var scanResults:Results<ScanResult> = try! ScanResult.all()

    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.dataSource = self
        collectionView.delegate = self

        // TODO: facade?
        let realm = try! Realm()
        notificationToken = realm.addNotificationBlock { [unowned self] note, realm in
            self.collectionView.reloadData()
        }
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        collectionView.reloadData()
    }
}

// MARK: -

private typealias FlowLayoutDelegate = ViewController
extension FlowLayoutDelegate : UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let frameWidth = collectionView.frame.width
        let cols = CGFloat(UIDeviceOrientationIsLandscape(UIDevice.current.orientation) ? itemsPerRow * 2 : itemsPerRow)
        let itemWidth = frameWidth / cols
        return CGSize(width: itemWidth, height: itemWidth)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0.0
    }
}

private typealias CollectionViewDatasource = ViewController
extension CollectionViewDatasource : UICollectionViewDataSource {

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ScanResultCell.ReuseIdentifier, for: indexPath) as! ScanResultCell
        let scan:ScanResult = scanResults[indexPath.row]

        if scan.isScanning {
            cell.dateLabel.text = NSLocalizedString("scanning...", comment: "")
            cell.activityIndicator.startAnimating()
        } else {
            cell.dateLabel.text = prettyDate(scan.createdAt)
            cell.activityIndicator.stopAnimating()
        }

        if let imgPath = scan.previewImage {
            cell.imageView.image = UIImage.init(contentsOfFile: fileManager.userDocumentsURL(forSubdirectory: imgPath).path)
        }
        // TODO: else placeholder

        if let scanId = scan.id as String? {
            cell.nameLabel.text = scanId
        } else {
            cell.nameLabel.text = "..."
        }

        return cell
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        debugLabel.text = "\(scanResults.count) results"
        return scanResults.count
    }

    private func prettyDate(_ date:Date) -> String {
        let translatorComment = ""
        switch -1 * date.timeIntervalSinceNow {
        case let t where t < 60:
            return NSLocalizedString("just added", comment: translatorComment)
        case let t where t < 60 * 5:
            return NSLocalizedString("a few minutes ago", comment: translatorComment)
        case let t where t < 60 * 60:
            let format = NSLocalizedString("%d minute(s) ago", comment: translatorComment)
            return String.localizedStringWithFormat(format, Int(t.minutes))
        case let t where t < 60 * 60 * 24:
            let format = NSLocalizedString("%d hour(s) ago", comment: translatorComment)
            return String.localizedStringWithFormat(format, Int(t.hours))
        case let t where t < 60 * 60 * 24 * 100:
            let format = NSLocalizedString("%d day(s) ago", comment: translatorComment)
            return String(format: format, Int(t.days))
        default:
            if let longDate = DateFormatter.dateFormat(fromTemplate: "MM/dd/YY", options: 0, locale: Locale.current) {
                return longDate
            } else {
                return ""
            }
        }
    }

}

private typealias IBActions = ViewController
extension IBActions {
    @IBAction func buttonPressed(_ sender: Any) {
        if (UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.camera)) {
            launchCamera()
        } else {
            alert(NSLocalizedString("No camera available on this device", comment: ""))
        }
    }

    @IBAction func refreshPressed(_ sender: Any) {
        collectionView.reloadData()
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
                 picker.allowsEditing = true
        present(picker, animated: true, completion: nil)
    }
}

private typealias ImagePickerDelegate = ViewController
extension ImagePickerDelegate : UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    static let PreviewJpgCompressionLevel = 0.80

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        picker.dismiss(animated: true, completion: nil)

        // Can be very slow: image size + accuracy/engineMode are the two main vars.
        // TODO: add resizing (app setting?)
        // XXX: see allowsEditing above
                guard let img = info[UIImagePickerControllerEditedImage] as? UIImage else {
//        guard let img = info[UIImagePickerControllerOriginalImage] as? UIImage else {
                    alert(NSLocalizedString("Image not available", comment: ""))
            return
        }

        guard let scan = try? ScanResult.create() else {
            alert(NSLocalizedString("Scan cannot be created", comment: ""))
            return
        }

        let previewOp = operationForPreview(image: img, scanIdentifier: scan.id)
        let scanningOp = operationForScanning(image: img, scanIdentifier: scan.id)
        let backgroundQueue = OperationQueue.init()
        backgroundQueue.addOperations([previewOp, scanningOp], waitUntilFinished: false)
    }

    private func operationForPreview(image:UIImage, scanIdentifier:String) -> Operation {
        let previewOp:Operation = BlockOperation.init {
            if let scanCopy = ScanResult.get(scanIdentifier) {
                if let savedImagePath = self.savePreviewImage(image, toScan: scanCopy) {
                    scanCopy.previewImage = savedImagePath
                }
            } else {
                print("failed to fetch!")
            }
        }
        previewOp.qualityOfService = QualityOfService.userInitiated
        return previewOp
    }

    private func operationForScanning(image:UIImage, scanIdentifier:String) -> Operation {
        let scanningOp:Operation = BlockOperation.init {
            let scanner = PDFScanner.init()
            // TODO: Accuracy prefs
            guard let pdfFile = scanner.savePDF(forIdentifier: scanIdentifier, from: image, with: PDFScannerAccuracyLow) else {
                print("Scan failed!")
                return
            }
            if let scanCopy = ScanResult.get(scanIdentifier) {
                scanCopy.pdfFile = pdfFile
            } else {
                //retry
                print("failed to fetch!")
            }
        }
        scanningOp.qualityOfService = QualityOfService.userInitiated
        return scanningOp
    }

    private func savePreviewImage(_ image:UIImage, toScan scanResult:ScanResult) -> String? {
        // TODO: preview scaling
        let filename = (scanResult.id as NSString).appendingPathExtension("jpg")!
        let imgDir = fileManager.userDocumentsURL(forSubdirectory: fileManager.imageDirectoryName)!

        guard fileManager.createDirectory(atPathURL: imgDir) else {
            print("img directory unavailable")
            return nil
        }

        do {
            let jpgData = UIImageJPEGRepresentation(image, CGFloat(ImagePickerDelegate.PreviewJpgCompressionLevel))
            try jpgData?.write(to: imgDir.appendingPathComponent(filename))
        } catch {
            print("Error saving preview")
        }

        // return value will not contain the full path (only the subdir + filename)
        return (fileManager.imageDirectoryName as NSString).appendingPathComponent(filename)
    }
}

private typealias Alerts = ViewController
extension Alerts {
    func alert(_ message: String, title: String = NSLocalizedString("Alert", comment: "Alert popup title")) {
        let alert = UIAlertController.init(title: title,
                                           message: message,
                                           preferredStyle: UIAlertControllerStyle.alert)
        let alertAction = UIAlertAction.init(title: NSLocalizedString("OK", comment:""),
                                             style: UIAlertActionStyle.default, handler: nil)
        alert.addAction(alertAction)
        present(alert, animated: true)
    }
}

private typealias ShareSheet = ViewController
extension ShareSheet {
    func sharePdf(_ filePath: String) {
        let url:URL = URL.init(fileURLWithPath: filePath)
        let shareSheet = UIActivityViewController.init(activityItems: [url], applicationActivities: nil);
        present(shareSheet, animated: true)
    }
}
