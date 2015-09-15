//
//  ShowColorsViewController.swift
//  StadiumShow
//
//  Created by Matias Gualino on 7/9/15.
//  Copyright (c) 2015 StadiumShow. All rights reserved.
//

import UIKit
import GoogleMobileAds

class ShowColorsViewController: UIViewController {

	@IBOutlet var colorView: UIView!
	@IBOutlet var bannerView: GADBannerView!
	var colors : [UIColor]?
	var delay : Double = 1.0
	var index = 0
	
	init(colors: [UIColor], delay: Double) {
		super.init(nibName: "ShowColorsViewController", bundle: nil)
		self.automaticallyAdjustsScrollViewInsets = false
		self.colors = colors
		self.delay = delay
	}
	
	required init(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
    override func viewDidLoad() {
        super.viewDidLoad()

		self.navigationController?.interactivePopGestureRecognizer.enabled = false
		
		bannerView.adUnitID = "ca-app-pub-3940256099942544/6300978111"
		bannerView.rootViewController = self
		bannerView.loadRequest(GADRequest())
		
		NSTimer.scheduledTimerWithTimeInterval(self.delay, target: self, selector: Selector("showColors"), userInfo: nil, repeats: true)
    }

	func showColors() {
		let indexColor = index % colors!.count
		self.colorView.backgroundColor = colors![indexColor]
		self.view.backgroundColor = colors![indexColor]
		index = index + 1
	}

}
