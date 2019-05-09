//
//  DiskImageInfo.swift
//  NetBoot Updater
//
//  Created by Keaton Burleson on 5/9/19.
//  Copyright © 2019 Keaton Burleson. All rights reserved.
//

import Foundation
import Cocoa

class DiskImageInfo: Codable {
    var systemEntities: [SystemEntity]
    
    var mountedDiskImage: SystemEntity? {
        return systemEntities.first { $0.mountPoint != nil }
    }
    
    private enum CodingKeys: String, CodingKey {
        case systemEntities = "system-entities"
    }
}
