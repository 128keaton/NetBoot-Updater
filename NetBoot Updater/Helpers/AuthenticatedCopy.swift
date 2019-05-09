//
//  AuthenticatedCopy.swift
//  NetBoot Updater
//
//  Created by Keaton Burleson on 5/9/19.
//  Copyright © 2019 Keaton Burleson. All rights reserved.
//

import Foundation
import Cocoa
import STPrivilegedTask

class AuthenticatedCopy {
    static func copyApplicationToNetBootImage(applicationAtURL applicationURL: URL, netBootDiskImage diskImage: SystemEntity, completion: @escaping (Bool, String) -> ()) {
        guard let mountPoint = diskImage.mountPoint else { return completion(false, "Disk image not mounted") }
        let applicationsFolderOnNetBootImageURL = URL(fileURLWithPath: mountPoint).appendingPathComponent("Applications")

        if applicationsFolderOnNetBootImageURL.filestatus == .isNot {
            showErrorAlert(errorMessage: " '\(mountPoint)/Applications/' directory does not exist!")
        }

        if applicationURL.pathExtension != "app" {
            showErrorAlert(errorMessage: "You cannot copy '\(applicationURL.absolutePath)' because it is not an application")
        }


        let applicationDestinationURL = applicationsFolderOnNetBootImageURL.appendingPathComponent(applicationURL.pathComponents.last!)

        if applicationDestinationURL.filestatus == .isNot {
            do {
                try FileManager.default.copyItem(at: applicationURL, to: applicationDestinationURL)
            } catch {
                completion(false, "Could not copy \(applicationURL) to \(applicationDestinationURL): \(error)")
            }
        } else {
            do {
                try FileManager.default.removeItem(at: applicationDestinationURL)
                try FileManager.default.copyItem(at: applicationURL, to: applicationDestinationURL)
            } catch {
                completion(false, "Could not remove or copy \(applicationDestinationURL) with \(applicationURL): \(error)")
            }
        }

        completion(true, "Successfully copied \(applicationURL.absolutePath) to \(applicationDestinationURL.absolutePath)")
    }
    
    private static func showErrorAlert(errorMessage: String) {
        NotificationCenter.default.post(name: AppDelegate.showErrorNotification, object: errorMessage)
    }
}
