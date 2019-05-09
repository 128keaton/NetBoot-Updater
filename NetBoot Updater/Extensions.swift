//
//  Extensions.swift
//  NetBoot Updater
//
//  Created by Keaton Burleson on 5/9/19.
//  Copyright © 2019 Keaton Burleson. All rights reserved.
//

import Foundation
extension URL {
    enum Filestatus {
        case isFile
        case isDir
        case isNot
    }

    var filestatus: Filestatus {
        get {
            let filestatus: Filestatus
            var isDir: ObjCBool = false
            if FileManager.default.fileExists(atPath: self.path, isDirectory: &isDir) {
                if isDir.boolValue {
                    // file exists and is a directory
                    filestatus = .isDir
                }
                    else {
                        // file exists and is not a directory
                        filestatus = .isFile
                }
            }
                else {
                    // file does not exist
                    filestatus = .isNot
            }
            return filestatus
        }
    }
    
    /// Absolute path of file from URL
    var absolutePath: String {
        return self.absoluteString.replacingOccurrences(of: "file://", with: "").replacingOccurrences(of: "%20", with: " ")
    }
}
