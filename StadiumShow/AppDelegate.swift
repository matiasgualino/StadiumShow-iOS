//
//  AppDelegate.swift
//  StadiumShow
//
//  Created by Matias Gualino on 26/8/15.
//  Copyright (c) 2015 StadiumShow. All rights reserved.
//

import UIKit
import CoreData

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

	var window: UIWindow?


	func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
		self.window = UIWindow(frame: UIScreen.mainScreen().bounds)
		
		let navController : UINavigationController = UINavigationController(rootViewController: MainViewController())
		navController.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName: UIColor.whiteColor()]
		navController.navigationBar.tintColor = UIColor.whiteColor()
		self.window?.rootViewController = navController
		
		self.window?.makeKeyAndVisible()
		return true
	}

}

