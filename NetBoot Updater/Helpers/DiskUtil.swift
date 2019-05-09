//
//  DiskUtil.swift
//  NetBoot Updater
//
//  Created by Keaton Burleson on 5/9/19.
//  Copyright © 2019 Keaton Burleson. All rights reserved.
//

import Foundation
import Cocoa
import STPrivilegedTask

class DiskUtil {
    private static var lastMountedDiskImageURL: URL? = nil
    private (set) public static var lastUnmountedDiskURL: URL? = nil
    private (set) public static var currentDisk: SystemEntity? = nil


    static func renameDiskImage(atURL url: URL) -> URL? {
        let diskImagePath = url.absolutePath
        var newDiskImagePath: String? = nil

        if url.pathExtension == "dmg" {
            newDiskImagePath = diskImagePath.replacingOccurrences(of: ".dmg", with: ".sparseimage")
        } else if url.pathExtension == "sparseimage" {
            newDiskImagePath = diskImagePath.replacingOccurrences(of: ".sparseimage", with: ".dmg")
        }

        if let newDiskImagePath = newDiskImagePath {
            let renameTask = STPrivilegedTask(launchPath: "/bin/mv", arguments: [diskImagePath, newDiskImagePath])
            let taskStatus: OSStatus = renameTask!.launch()
            if taskStatus == errAuthorizationSuccess {
                return URL(fileURLWithPath: newDiskImagePath)
            } else {
                showErrorAlert(errorMessage: "Could not rename disk image/sparse image at path '\(newDiskImagePath)', you cannot perform this action without authorization!")
            }
        } else {
            showErrorAlert(errorMessage: "Could not rename disk image/sparse image at path '\(diskImagePath)', it isn't a disk image or a sparse image.")
        }

        return nil
    }

    static func mountDMG(atURL url: URL) -> SystemEntity? {
        var temporaryURL: URL? = nil

        if url.pathExtension != "sparseimage" {
            temporaryURL = self.renameDiskImage(atURL: url)
        } else {
            temporaryURL = url
        }

        guard let renamedURL = temporaryURL else { return nil }

        lastMountedDiskImageURL = renamedURL

        let task = Process()
        let errorPipe = Pipe()
        let standardPipe = Pipe()

        task.standardError = errorPipe
        task.standardOutput = standardPipe

        task.launchPath = "/usr/bin/hdiutil"
        task.arguments = ["mount", "-plist", renamedURL.absolutePath]

        task.launch()
        task.waitUntilExit()

        let errorHandle = errorPipe.fileHandleForReading
        let errorData = errorHandle.readDataToEndOfFile()
        let taskErrorOutput = String(data: errorData, encoding: String.Encoding.utf8)

        let standardHandle = standardPipe.fileHandleForReading
        let standardData = standardHandle.readDataToEndOfFile()


        if(taskErrorOutput != nil && taskErrorOutput!.count > 0) {
            showErrorAlert(errorMessage: "Could not mount disk image/sparse image: \(taskErrorOutput ?? "No error?")")
            return nil
        }

        do {
            let diskImageInfo = try PropertyListDecoder().decode(DiskImageInfo.self, from: standardData)
            
            if let mountedDiskImage = diskImageInfo.mountedDiskImage {
                self.currentDisk = mountedDiskImage
            }
            
            return diskImageInfo.mountedDiskImage
        } catch {
            fatalError("Could not parse disk image info from task output: \(error)")
        }
    }

    static func ejectDMG(_ dmg: SystemEntity, completionHandler: @escaping (Bool) -> ()) {
        if let mountPoint = dmg.mountPoint {
            let task = Process()
            let errorPipe = Pipe()
            let standardPipe = Pipe()

            task.standardError = errorPipe
            task.standardOutput = standardPipe

            task.launchPath = "/usr/sbin/diskutil"
            task.arguments = ["eject", mountPoint]

            task.launch()
            task.waitUntilExit()

            let errorHandle = errorPipe.fileHandleForReading
            let errorData = errorHandle.readDataToEndOfFile()
            let taskErrorOutput = String(data: errorData, encoding: String.Encoding.utf8)

            let standardHandle = standardPipe.fileHandleForReading
            let standardData = standardHandle.readDataToEndOfFile()
            let standardTaskOutput = String(data: standardData, encoding: String.Encoding.utf8)

            if(taskErrorOutput != nil && taskErrorOutput!.count > 0) {
                showErrorAlert(errorMessage: "Could not eject disk image/sparse image: \(taskErrorOutput ?? "No error?")")
                completionHandler(false)
            }

            if let urlToRename = lastMountedDiskImageURL {
                currentDisk = nil
                lastUnmountedDiskURL = self.renameDiskImage(atURL: urlToRename)
            }

            completionHandler((standardTaskOutput?.contains("ejected"))!)
        }
       completionHandler(false)
    }

    private static func showErrorAlert(errorMessage: String) {
        NotificationCenter.default.post(name: AppDelegate.showErrorNotification, object: errorMessage)
    }
}
