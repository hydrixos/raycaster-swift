//
//  AppDelegate.swift
//  RaycasterDemo
//
//  Created by Friedrich Gräter on 10.11.16.
//  Copyright © 2018 Friedrich Ruynat. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
	var rayCasterWindow : MainWindow?;
	
	func applicationDidFinishLaunching(_ notification: Notification) {
		rayCasterWindow = MainWindow()
		rayCasterWindow?.showWindow(nil)
	}
}

