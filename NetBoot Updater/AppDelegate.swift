//
//  AppDelegate.swift
//  NetBoot Updater
//
//  Created by Keaton Burleson on 5/9/19.
//  Copyright © 2019 Keaton Burleson. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    private var currentSheet: NSWindow? = nil
    private var applicationWindow: NSWindow? = nil

    static let showErrorNotification = Notification.Name(rawValue: "showErrorAlert")
    static let showInfoNotification = Notification.Name(rawValue: "showInfoAlert")

    static let showLoadingNotification = Notification.Name(rawValue: "showLoadingWindow")
    static let hideLoadingNotification = Notification.Name(rawValue: "hideLoadingWindow")

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        NotificationCenter.default.addObserver(self, selector: #selector(showLoadingController(_:)), name: AppDelegate.showLoadingNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(hideLoadingController), name: AppDelegate.hideLoadingNotification, object: nil)
    }

    func ejectDisks() {
        if let currentDisk = DiskUtil.currentDisk {
            showLoadingController(withMessage: "Ejecting Disk Images...")
            DiskUtil.ejectDMG(currentDisk) { (didEject) in
                if (didEject) {
                    self.hideLoadingController()
                    NSApp.terminate(self)
                }
            }
        }
    }

    @objc func showLoadingController(_ notification: Notification) {
        if let message = notification.object as? String {
            showLoadingController(withMessage: message)
        }
    }

    @objc func hideLoadingController() {
        if let mainWindow = applicationWindow,
            let loadingWindow = currentSheet {
            mainWindow.endSheet(loadingWindow)
        }
    }

    func showLoadingController(withMessage message: String) {
        let storyBoard = NSStoryboard(name: "Main", bundle: nil)

        if let loadingWindowController = storyBoard.instantiateController(withIdentifier: "loadingWindowController") as? NSWindowController {
            if let mainWindow = NSApplication.shared.mainWindow,
                let loadingWindow = loadingWindowController.window,
                let loadingViewController = loadingWindow.contentViewController as? LoadingViewController {

                loadingViewController.loadingTextValue = message
                currentSheet = loadingWindow
                applicationWindow = mainWindow
                mainWindow.beginSheet(loadingWindow, completionHandler: nil)
            }
        }
    }

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        if DiskUtil.currentDisk != nil {
            ejectDisks()
            return .terminateCancel
        }
        return .terminateNow
    }
}

