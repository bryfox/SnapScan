//
//  ScanResultViewController.swift
//  SnapScan
//
//  Created by Bryan Fox on 6/5/17.
//  Copyright © 2017 Bryan Fox. All rights reserved.
//

import UIKit
import RealmSwift

class ScanResultViewController: UIViewController {

    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var debugLabel: UILabel!

    let fileManager: DefaultFileManager = DefaultFileManager.init()
    let itemsPerRow = 2
    var notificationToken: NotificationToken?
    // Could optionally have retrying here, though a crash is preferable for now.
    // See https://realm.io/docs/swift/2.8.0/api/Classes/Realm/Error.html
    var scanResults: Results<ScanResult> = try! ScanResult.all() // swiftlint:disable:this force_try

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        collectionView.dataSource = self
        collectionView.delegate = self

        notificationToken = scanResults.addNotificationBlock { [weak self] (change: RealmCollectionChange<Results<ScanResult>>) in
            guard let collectionView = self?.collectionView else { return }

            switch change {
            case .initial:
                collectionView.reloadData()
            case .update(_, let deletions, let insertions, let modifications):
                func toIndexPath(index: Int) -> IndexPath {
                    return IndexPath.init(row: index, section: 0)
                }
                collectionView.performBatchUpdates({
                    collectionView.insertItems(at: insertions.map(toIndexPath))
                    collectionView.deleteItems(at: deletions.map(toIndexPath))
                    collectionView.reloadItems(at: modifications.map(toIndexPath))
                }, completion: nil)
                break
            case .error:
                DLog("Error")
            }
        }
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        collectionView.reloadData()
    }
}

// MARK: -

private typealias ScanManager = ScanResultViewController
extension ScanManager {
    func renameScan(_ id: String, to name: String) {

    }

    func exportScan(_ id: String) {
        if let scan = ScanResult.get(id) {
            sharePdfFile(fileManager.userDocumentsURL(forSubdirectory: scan.pdfFile))
        }
    }

    func deleteScan(_ id: String) {
        confirmDeleteScan(id)
    }

    private func confirmDeleteScan(_ id: String) {
        func onConfirmed(_: UIAlertAction) {
            if !ScanResult.delete(id) {
                DLog("Delete failed")
            }
        }
        let okAction = UIAlertAction.init(title: NSLocalizedString("OK", comment:""),
                                          style: UIAlertActionStyle.default,
                                          handler: onConfirmed)

        confirm(NSLocalizedString("Really delete this scan?", comment: ""),
                title: NSLocalizedString("Confirm Deletion", comment: ""),
                confirmAction: okAction)
    }
}

// MARK: -

private typealias CollectionViewDelegate = ScanResultViewController
extension CollectionViewDelegate : UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {

    }

    func collectionView(_ collectionView: UICollectionView, shouldShowMenuForItemAt indexPath: IndexPath) -> Bool {
        customizeMenuItems()
        return true
    }

    func collectionView(_ collectionView: UICollectionView,
                        canPerformAction action: Selector,
                        forItemAt indexPath: IndexPath,
                        withSender sender: Any?) -> Bool {
        // required, despite docs. See ScanResultCell for menu actions
        return false
    }

    func collectionView(_ collectionView: UICollectionView,
                        performAction action: Selector,
                        forItemAt indexPath: IndexPath,
                        withSender sender: Any?) {
        // no-op, but required
    }

    func customizeMenuItems() {
        let menu = UIMenuController.shared
        let shareItem  = UIMenuItem.init(title: NSLocalizedString("Share PDF", comment: ""), action: #selector(ScanResultCell.exportPDF))
//        let renameItem = UIMenuItem.init(title: NSLocalizedString("Rename", comment: ""), action: #selector(ScanResultCell.rename))
        menu.menuItems = [shareItem] //, renameItem
    }

}

private typealias FlowLayoutDelegate = ScanResultViewController
extension FlowLayoutDelegate : UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        let frameWidth = collectionView.frame.width
        let cols = CGFloat(UIDeviceOrientationIsLandscape(UIDevice.current.orientation) ? itemsPerRow * 2 : itemsPerRow)
        let itemWidth = frameWidth / cols
        return CGSize(width: itemWidth, height: itemWidth)
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0.0
    }
}

private typealias CollectionViewDatasource = ScanResultViewController
extension CollectionViewDatasource : UICollectionViewDataSource {

    // Not needed, yet...
//    func indexPathOfScanId(_ id: String) -> IndexPath? {
//        let index = scanResults.index { (scan: ScanResult) -> Bool in scan.id == id }
//        return index == NSNotFound ? nil : IndexPath.init(row: index, section: 0)
//    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let scan: ScanResult = scanResults[indexPath.row]
        // swiftlint:disable:next force_cast
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ScanResultCell.ReuseIdentifier, for: indexPath) as! ScanResultCell

        cell.scanResultController = self
        cell.scanId = scan.id

        if scan.isScanning {
            cell.dateLabel.text = NSLocalizedString("scanning...", comment: "")
            cell.activityIndicator.startAnimating()
        } else {
            cell.dateLabel.text = prettyDate(scan.createdAt)
            cell.activityIndicator.stopAnimating()
        }

        if let imgPath = scan.previewImage {
            let file = fileManager.userDocumentsURL(forSubdirectory: imgPath).path
            cell.imageView.image = UIImage.init(contentsOfFile: file)
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
        debugLabel.text = "\(scanResults.count) results (\(fileManager.pdfCount()) PDFs)"
        return scanResults.count
    }

    private func prettyDate(_ date: Date) -> String {
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

private typealias IBActions = ScanResultViewController
extension IBActions {
    @IBAction func cameraButtonPressed(_ sender: Any) {
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.camera) {
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
        picker.delegate = self
        picker.sourceType = UIImagePickerControllerSourceType.camera
        picker.showsCameraControls = true
        picker.videoQuality = UIImagePickerControllerQualityType.typeHigh
        picker.cameraCaptureMode = UIImagePickerControllerCameraCaptureMode.photo
        // TODO: app setting for picker.cameraFlashMode?
        // XXX: for quicker debugging with low-res
                 picker.allowsEditing = true
        present(picker, animated: true, completion: nil)
    }
}

private typealias ImagePickerDelegate = ScanResultViewController
extension ImagePickerDelegate : UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    static let PreviewJpgCompressionLevel = 0.80

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {

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

        // TODO: scroll to top...
        picker.dismiss(animated: true, completion: nil)
        picker.delegate = nil
    }

    private func operationForPreview(image: UIImage, scanIdentifier: String) -> Operation {
        let previewOp: Operation = BlockOperation.init {
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

    private func operationForScanning(image: UIImage, scanIdentifier: String) -> Operation {
        let scanningOp: Operation = BlockOperation.init {
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

    private func savePreviewImage(_ image: UIImage, toScan scanResult: ScanResult) -> String? {
        // TODO: preview scaling
        let filename = (scanResult.id as NSString).appendingPathExtension("jpg")!
        let imgDir = fileManager.userDocumentsURL(forSubdirectory: fileManager.imageDirectoryName)!

        guard fileManager.createDirectory(at: imgDir) else {
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

private typealias Alerts = ScanResultViewController
extension Alerts {
    fileprivate func confirm(_ message: String, title: String, confirmAction: UIAlertAction) {
        let confirm = UIAlertController.init(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
        let cancelAction = UIAlertAction.init(title: NSLocalizedString("Cancel", comment:""),
                                             style: UIAlertActionStyle.cancel, handler: nil)
        confirm.addAction(confirmAction)
        confirm.addAction(cancelAction)
        present(confirm, animated: true)
    }
    fileprivate func alert(_ message: String, title: String = NSLocalizedString("Alert", comment: "Alert popup title")) {
        let alert = UIAlertController.init(title: title,
                                           message: message,
                                           preferredStyle: UIAlertControllerStyle.alert)
        let alertAction = UIAlertAction.init(title: NSLocalizedString("OK", comment:""),
                                             style: UIAlertActionStyle.default, handler: nil)
        alert.addAction(alertAction)
        present(alert, animated: true)
    }
}

private typealias ShareSheet = ScanResultViewController
extension ShareSheet {
    fileprivate func sharePdfFile(_ fileURL: URL) {
        let shareSheet = UIActivityViewController.init(activityItems: [fileURL], applicationActivities: nil)
        present(shareSheet, animated: true)
    }
}
