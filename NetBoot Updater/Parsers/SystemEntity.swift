//
//  SystemEntity.swift
//  NetBoot Updater
//
//  Created by Keaton Burleson on 5/9/19.
//  Copyright © 2019 Keaton Burleson. All rights reserved.
//

import Foundation
import Cocoa

struct SystemEntity: Codable {
    var contentHint: String
    var devEntry: String
    var potentiallyMountable: Bool
    var mountPoint: String?

    var volumeName: String? {
        if let validMountPoint = mountPoint{
            return validMountPoint.components(separatedBy: "/").last!
        }
        return nil
    }

    private enum CodingKeys: String, CodingKey {
        case contentHint = "content-hint"
        case devEntry = "dev-entry"
        case potentiallyMountable = "potentially-mountable"
        case mountPoint = "mount-point"
    }
}
