//
//  ApplicationInfo.swift
//  NetBoot Updater
//
//  Created by Keaton Burleson on 5/9/19.
//  Copyright © 2019 Keaton Burleson. All rights reserved.
//

import Foundation
import Cocoa

class ApplicationInfo: Codable, CustomStringConvertible {
    var name: String
    var iconFile: String
    var bundleIdentifier: String
    var version: String
    var bundleURL: URL? = nil

    var description: String {
        return "\(name) - \(version)"
    }
    
    var isValid: Bool {
        return name != ""
    }

    func addBundleURL(_ newBundleURL: URL) {
        self.bundleURL = newBundleURL
    }

    init(bundleURL: URL) {
        let infoPlistURL = bundleURL.appendingPathComponent("Contents").appendingPathComponent("Info.plist")
        
        self.bundleURL = bundleURL
        self.name = ""
        self.iconFile = ""
        self.bundleIdentifier = ""
        self.version = ""
        
        if infoPlistURL.filestatus == .isFile {
            do {
                let propertyListData = try Data(contentsOf: infoPlistURL)
                let newApplication = try PropertyListDecoder().decode(ApplicationInfo.self, from: propertyListData)
                self.name = newApplication.name
                self.iconFile = newApplication.iconFile
                self.bundleIdentifier = newApplication.bundleIdentifier
                self.version = newApplication.version
            } catch {
                fatalError("Unable to parse property list: \(error)")
            }
        }
    }
    

    private enum CodingKeys: String, CodingKey {
        case name = "CFBundleName"
        case bundleIdentifier = "CFBundleIdentifier"
        case iconFile = "CFBundleIconFile"
        case version = "CFBundleShortVersionString"
    }
}
