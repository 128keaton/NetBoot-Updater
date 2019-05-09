//
//  LoadingViewController.swift
//  NetBoot Updater
//
//  Created by Keaton Burleson on 5/9/19.
//  Copyright © 2019 Keaton Burleson. All rights reserved.
//

import Foundation
import Cocoa

class LoadingViewController: NSViewController {
    @IBOutlet weak var loadingIndicator: NSProgressIndicator!
    @IBOutlet weak var loadingText: NSTextField!
    
    public var loadingTextValue = "Ejecting disk images"
    
    override func viewDidLoad() {
        loadingIndicator.startAnimation(self)
        loadingText.stringValue = loadingTextValue
    }
}
