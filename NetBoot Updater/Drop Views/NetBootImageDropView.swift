//
//  NetBootImageDropView.swift
//  NetBoot Updater
//
//  Created by Keaton Burleson on 5/9/19.
//  Copyright © 2019 Keaton Burleson. All rights reserved.
//

import Foundation
import Cocoa

class NetBootImageDropView: NSImageView {
    var delegate: NetBootImageDropViewDelegate? = nil
    
    var isReceivingDrag = false {
        didSet {
            needsDisplay = true
        }
    }
    
    override func awakeFromNib() {
        self.registerForDraggedTypes([NSPasteboard.PasteboardType.init(rawValue: kUTTypeURL as String)])
    }
    
    func shouldAllowDrag(_ draggingInfo: NSDraggingInfo) -> Bool {
        if let urls = draggingInfo.draggingPasteboard.readObjects(forClasses: [NSURL.self], options: nil) as? [URL], urls.count > 0,
            (urls.first { $0.pathExtension == "nbi" }) != nil{
            return true
        }
        return false
    }
    
    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        let allow = shouldAllowDrag(sender)
        isReceivingDrag = allow
        return allow ? .copy : NSDragOperation()
    }
    
    override func draggingExited(_ sender: NSDraggingInfo?) {
        isReceivingDrag = false
    }
    
    override func prepareForDragOperation(_ sender: NSDraggingInfo) -> Bool {
        let allow = shouldAllowDrag(sender)
        return allow
    }
    
    override func performDragOperation(_ draggingInfo: NSDraggingInfo) -> Bool {
        if let urls = draggingInfo.draggingPasteboard.readObjects(forClasses: [NSURL.self], options: nil) as? [URL], urls.count > 0 {
            
            delegate?.processNetBootImageURLs(urls)
            return true
        }
        return false
    }
}

protocol NetBootImageDropViewDelegate {
    func processNetBootImageURLs(_ urls: [URL])
}
