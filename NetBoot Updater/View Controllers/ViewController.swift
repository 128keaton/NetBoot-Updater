//
//  ViewController.swift
//  NetBoot Updater
//
//  Created by Keaton Burleson on 5/9/19.
//  Copyright © 2019 Keaton Burleson. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {
    @IBOutlet weak var applicationDropView: ApplicationDropView? = nil
    @IBOutlet weak var netBootImageDropView: NetBootImageDropView? = nil

    @IBOutlet weak var netBootImageLabel: NSTextField!
    @IBOutlet weak var applicationNameLabel: NSTextField!
    @IBOutlet weak var applicationVersionLabel: NSTextField!
    @IBOutlet weak var updateButton: NSButton!

    var currentApplication: ApplicationInfo? = nil {
        didSet {
            if let application = self.currentApplication {
                updateApplicationLabel(newName: application.name, newVersion: application.version)
                updateApplicationIconImageView(forApplicationAtURL: application.bundleURL, iconFileName: application.iconFile)
                if currentNetBootDiskImage != nil {
                    updateButton.isEnabled = true
                } else {
                    updateButton.isEnabled = false
                }
            } else {
                applicationNameLabel.textColor = NSColor.secondaryLabelColor
                applicationNameLabel.stringValue = "Drop .app"
                applicationVersionLabel.isHidden = true
                applicationDropView?.image = NSImage(named: "Utilities-Icon-Muted")!
                updateButton.isEnabled = false
            }
        }
    }

    var currentNetBootDiskImage: SystemEntity? = nil {
        didSet {
            if let netBootDiskImage = self.currentNetBootDiskImage,
                let volumeName = netBootDiskImage.volumeName {
                netBootImageDropView?.image = NSImage(named: "Developer-Folder-Icon")!
                netBootImageLabel.stringValue = volumeName
                netBootImageLabel.textColor = NSColor.labelColor
                netBootImageLabel.isHidden = false

                if currentApplication != nil {
                    updateButton.isEnabled = true
                } else {
                    updateButton.isEnabled = false
                }
            } else {
                netBootImageLabel.textColor = NSColor.secondaryLabelColor
                netBootImageLabel.stringValue = "Drop .nbi"
                netBootImageDropView?.image = NSImage(named: "Developer-Folder-Icon-Muted")!
                updateButton.isEnabled = false
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        applicationDropView?.delegate = self
        netBootImageDropView?.delegate = self

        applicationVersionLabel.isHidden = true
        updateButton.isEnabled = false

        netBootImageLabel.stringValue = "Drop .nbi"
        applicationNameLabel.stringValue = "Drop .app"

        let resetNetBootClickHandler = NSClickGestureRecognizer(target: self, action: #selector(resetNetBootImage))
        let resetApplicationHandler = NSClickGestureRecognizer(target: self, action: #selector(resetApplication))

        applicationNameLabel.addGestureRecognizer(resetApplicationHandler)
        netBootImageLabel.addGestureRecognizer(resetNetBootClickHandler)

        NotificationCenter.default.addObserver(self, selector: #selector(showErrorAlert(_:)), name: AppDelegate.showErrorNotification, object: nil)
    }

    func updateApplicationLabel(newName: String, newVersion: String) {
        if applicationVersionLabel.isHidden == true {
            applicationVersionLabel.isHidden = false
        }

        applicationNameLabel.textColor = NSColor.labelColor
        applicationNameLabel.stringValue = newName
        applicationVersionLabel.stringValue = "Version \(newVersion)"
    }

    func updateApplicationIconImageView(forApplicationAtURL: URL?, iconFileName: String) {
        if let fullApplicationPath = forApplicationAtURL {
            let resourcesFolderURL = fullApplicationPath.appendingPathComponent("Contents").appendingPathComponent("Resources")
            let iconURL = resourcesFolderURL.appendingPathComponent("\(iconFileName)\(iconFileName.contains(".icns") ? "" : ".icns")")
            if let iconImage = NSImage(contentsOfFile: iconURL.absolutePath) {
                applicationDropView?.image = iconImage
            } else {
                showErrorAlert(errorMessage: "Could not find \(iconFileName)(.icns) in \(resourcesFolderURL.absolutePath)")
            }
        }
    }

    @IBAction func updateApplicationsInNetBootdiskImage(sender: NSButton) {
        guard let application = self.currentApplication else { return }
        guard let applicationURL = application.bundleURL else { return }
        guard let netBootDiskImage = self.currentNetBootDiskImage else { return }

        NotificationCenter.default.post(name: AppDelegate.showLoadingNotification, object: "Updating NetBoot Image")

        AuthenticatedCopy.copyApplicationToNetBootImage(applicationAtURL: applicationURL, netBootDiskImage: netBootDiskImage, completion: { (didComplete, statusMessage) in
            NotificationCenter.default.post(name: AppDelegate.hideLoadingNotification, object: nil)
            if(didComplete) {
                self.showInfoAlert(infoMessage: statusMessage)
                self.resetNetBootImage()
            } else {
                self.showErrorAlert(errorMessage: statusMessage)
            }
        })
    }

    @objc func resetNetBootImage() {
        NotificationCenter.default.post(name: AppDelegate.showLoadingNotification, object: "Ejecting Disk Images...")
        DispatchQueue.main.async {
            if let diskImage = self.currentNetBootDiskImage {
                DiskUtil.ejectDMG(diskImage, completionHandler: { (didEject) in
                    NotificationCenter.default.post(name: AppDelegate.hideLoadingNotification, object: nil)
                    if didEject {
                        self.currentNetBootDiskImage = nil
                    }
                })
            }
        }
    }

    @objc func resetApplication() {
        self.currentApplication = nil
    }

    @objc func showErrorAlert(_ notification: Notification) {
        if let errorMessage = notification.object as? String {
            DispatchQueue.main.async {
                self.showErrorAlert(errorMessage: errorMessage)
            }
        }
    }

    func showErrorAlert(errorMessage: String) {
        let alertDialog = NSAlert()
        alertDialog.alertStyle = .critical
        alertDialog.messageText = "Error"
        alertDialog.informativeText = "\(errorMessage). \n Maybe try again?"
        alertDialog.runModal()
    }

    func showInfoAlert(infoMessage: String) {
        let alertDialog = NSAlert()
        alertDialog.alertStyle = .informational
        alertDialog.messageText = "Information"
        alertDialog.informativeText = infoMessage
        alertDialog.runModal()
    }
}

extension ViewController: ApplicationDropViewDelegate {
    func processApplicationURLs(_ urls: [URL]) {
        if let url = urls.first {
            let newApplication = ApplicationInfo(bundleURL: url)
            if newApplication.isValid {
                currentApplication = newApplication
            }
        }
    }
}

extension ViewController: NetBootImageDropViewDelegate {
    func processNetBootImageURLs(_ urls: [URL]) {
        if let url = urls.first {
            let netBootDMGURL = url.appendingPathComponent("NetBoot.dmg")
            let netBootSparseImageURL = url.appendingPathComponent("NetBoot.sparseimage")

            if netBootDMGURL.filestatus == .isFile {
                DispatchQueue.main.async {
                    self.currentNetBootDiskImage = DiskUtil.mountDMG(atURL: netBootDMGURL)
                }
            } else if netBootSparseImageURL.filestatus == .isFile {
                DispatchQueue.main.async {
                    self.currentNetBootDiskImage = DiskUtil.mountDMG(atURL: netBootSparseImageURL)
                }
            } else {
                showErrorAlert(errorMessage: "Could not find disk image or sparse image in \(url.absolutePath)")
            }
        }
    }
}
