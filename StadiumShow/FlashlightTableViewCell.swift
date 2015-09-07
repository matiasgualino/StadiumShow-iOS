//
//  FlashlightTableViewCell.swift
//  StadiumShow
//
//  Created by Matias Gualino on 27/8/15.
//  Copyright (c) 2015 StadiumShow. All rights reserved.
//

import UIKit

public protocol FlashlightDelegate {
	func notifyFlashlight(active: Bool)
}

class FlashlightTableViewCell: UITableViewCell {
	@IBOutlet weak var lblTitle: UILabel!
	@IBOutlet weak var switchFlashlight: UISwitch!
	
	var flashlightDelegate : FlashlightDelegate?

    override func awakeFromNib() {
        super.awakeFromNib()
		lblTitle.text = "Flashlight"
		
		switchFlashlight.on = false
		
		switchFlashlight.addTarget(self, action: Selector("stateChanged"), forControlEvents: UIControlEvents.ValueChanged)
    }

	func stateChanged() {
		flashlightDelegate?.notifyFlashlight(switchFlashlight.on)
	}
	
}
