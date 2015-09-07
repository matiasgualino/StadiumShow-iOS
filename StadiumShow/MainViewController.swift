//
//  MainViewController.swift
//  StadiumShow
//
//  Created by Matias Gualino on 26/8/15.
//  Copyright (c) 2015 StadiumShow. All rights reserved.
//

import UIKit
import AVFoundation
import AVKit
import GoogleMobileAds

class MainViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, FlashlightDelegate, WEPopoverControllerDelegate, ColorViewControllerDelegate {

	var AVSession : AVCaptureSession?
	
	@IBOutlet weak private var tableView : UITableView!
	@IBOutlet weak private var delaySegmented : UISegmentedControl!
	@IBOutlet var bannerView: GADBannerView!
	
	let sections:Array<AnyObject> = ["MODOS DE USO", "COLORES SELECCIONADOS"]
	
	var selectedColors : [UIColor]?
	
	var delay : Double = 1.0
	var flashlightON = false
	var device : AVCaptureDevice!
	var running = false
	var timer : NSTimer?
	
	var wePopoverController : WEPopoverController?
	
	init() {
		super.init(nibName: "MainViewController", bundle: nil)
		self.automaticallyAdjustsScrollViewInsets = false
	}
	
	required init(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
    override func viewDidLoad() {
        super.viewDidLoad()
		
		// Do any additional setup after loading the view, typically from a nib.
		println("Google Mobile Ads SDK version: " + GADRequest.sdkVersion())
		bannerView.adUnitID = "ca-app-pub-3940256099942544/6300978111"
		bannerView.rootViewController = self
		bannerView.loadRequest(GADRequest())
		
		setRightButtonInit()
		
		selectedColors = []
		
		self.tableView.delegate = self
		self.tableView.dataSource = self
		self.tableView.bounces = true
		self.tableView.autoresizingMask = UIViewAutoresizing.FlexibleHeight
		self.tableView.userInteractionEnabled = true
		self.tableView.autoresizesSubviews = true
		
		self.tableView.registerNib(UINib(nibName: "FlashlightTableViewCell", bundle: nil), forCellReuseIdentifier: "FlashlightTableViewCell")
		
		self.tableView.setEditing(true , animated: true)
		
		self.delaySegmented.selectedSegmentIndex = 0
		self.delaySegmented.addTarget(self, action: "delayChanged", forControlEvents: .ValueChanged)
    }
	
	func setRightButtonInit() {
		var btnContinue = UIBarButtonItem(title: "Iniciar", style: UIBarButtonItemStyle.Plain, target: self, action: Selector("initializeShow"))
		btnContinue.enabled = true
		btnContinue.tintColor = UIColor.blueColor()
		self.navigationItem.rightBarButtonItem = btnContinue
		if flashlightON || (self.selectedColors != nil && self.selectedColors!.count > 0) {
			self.navigationItem.rightBarButtonItem?.enabled = true
		} else {
			self.navigationItem.rightBarButtonItem?.enabled = false
		}
	}
	
	func setRightButtonFinish() {
		var btnContinue = UIBarButtonItem(title: "Finalizar", style: UIBarButtonItemStyle.Plain, target: self, action: Selector("finishShow"))
		btnContinue.enabled = true
		btnContinue.tintColor = UIColor.blueColor()
		self.navigationItem.rightBarButtonItem = btnContinue
	}
	
	func delayChanged() {
		let pot = 0.5 * Double(self.delaySegmented.selectedSegmentIndex)
		self.delay = pow(2.7183, -pot)
		println(self.delay)
	}
	
	func initializeShow() {
		if self.flashlightON {
			device = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo)
			if device.torchMode == AVCaptureTorchMode.Off {
				setRightButtonFinish()
				timer?.invalidate()
				timer = NSTimer.scheduledTimerWithTimeInterval(self.delay, target: self, selector: Selector("changeFlash"), userInfo: nil, repeats: true)
			} else {
				/*			AVSession?.stopRunning()
				AVSession = nil*/
			}
		} else {
			self.navigationController?.pushViewController(ShowColorsViewController(colors: selectedColors!, delay: self.delay), animated: true)
		}
	}
	
	func finishShow() {
		setRightButtonInit()
		timer?.invalidate()
		self.running = false
		self.AVSession!.stopRunning()
	}
	
	func numberOfSectionsInTableView(tableView: UITableView) -> Int {
		if !self.flashlightON {
			return 2
		} else {
			return 1
		}
	}
	
	func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		if section == 0 {
			if self.flashlightON {
				return 1
			} else {
				return 2
			}
		} else {
			return selectedColors!.count
		}
	}
	
	func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
		if indexPath.section == 1 {
			return true
		}
		return false
	}
	
	func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
		if(editingStyle == UITableViewCellEditingStyle.Delete){
			selectedColors?.removeAtIndex(indexPath.row)
			if selectedColors == nil || selectedColors?.count == 0 {
				self.navigationItem.rightBarButtonItem?.enabled = false
			}
			self.tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Fade)
		}
	}
	
	func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		if indexPath.section == 0 {
			var flashlightCell = (self.tableView.dequeueReusableCellWithIdentifier("FlashlightTableViewCell") as? FlashlightTableViewCell)!
			flashlightCell.flashlightDelegate = self
			if flashlightON {
				return flashlightCell
			} else {
				if indexPath.row == 0 {
					return flashlightCell
				} else if indexPath.row == 1 {
					var cell = UITableViewCell(style: UITableViewCellStyle.Default, reuseIdentifier: "SelectColor")
					cell.textLabel?.text = "Seleccionar colores"
					cell.accessoryType = UITableViewCellAccessoryType.DisclosureIndicator
					return cell
				}
			}
		} else {
			var cell = UITableViewCell(style: UITableViewCellStyle.Default, reuseIdentifier: "SelectedColor")
			cell.backgroundColor = selectedColors![indexPath.row]
			cell.accessoryType = UITableViewCellAccessoryType.DisclosureIndicator
			return cell
		}
		return UITableViewCell()
	}
	
	func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
		if indexPath.section == 0 && indexPath.row == 1 {
			if self.wePopoverController == nil {
				var contentViewController : ColorViewController = ColorViewController()
				contentViewController.delegate = self
				self.wePopoverController = WEPopoverController(contentViewController: contentViewController)
				self.wePopoverController!.delegate = self
				self.wePopoverController!.passthroughViews = NSArray(objects: self.navigationController!.navigationBar) as [AnyObject]
				
				self.wePopoverController?.presentPopoverFromRect(CGRectMake((self.view.frame.size.width / 2.0) - 50, 144, 100, 100), inView: self.view, permittedArrowDirections: (UIPopoverArrowDirection.Up|UIPopoverArrowDirection.Down), animated: true)
			} else {
				self.wePopoverController?.dismissPopoverAnimated(true)
				self.wePopoverController = nil;
			}
		}
		self.tableView.deselectRowAtIndexPath(indexPath, animated: true)
	}
	
	func tableView(tableView: UITableView,
		sectionForSectionIndexTitle title: String,
		atIndex index: Int) -> Int{
			return index
	}
	
	func tableView(tableView: UITableView,
		titleForHeaderInSection section: Int) -> String?{
			return self.sections[section] as? String
	}
	
	func notifyFlashlight(active: Bool) {
		self.flashlightON = active
		if active || (self.selectedColors != nil && self.selectedColors!.count > 0) {
			self.navigationItem.rightBarButtonItem?.enabled = true
		} else {
			self.navigationItem.rightBarButtonItem?.enabled = false
		}
		self.tableView.reloadData()
	}
	
	func createSessionFlashLight() {
		var session : AVCaptureSession = AVCaptureSession()
		var input : AVCaptureDeviceInput? = AVCaptureDeviceInput.deviceInputWithDevice(device, error: nil) as? AVCaptureDeviceInput
		session.addInput(input)
		
		var output : AVCaptureVideoDataOutput = AVCaptureVideoDataOutput()
		session.addOutput(output)
		
		session.beginConfiguration()
		device.lockForConfiguration(nil)
		
		device.torchMode = AVCaptureTorchMode.On
		device.flashMode = AVCaptureFlashMode.On
		
		device.unlockForConfiguration()
		session.commitConfiguration()
		
		session.startRunning()
		
		AVSession = session
	}

	func changeFlash() {
		if self.running {
			self.running = false
			self.AVSession!.stopRunning()
		} else {
			createSessionFlashLight()
			self.running = true
		}
	}
	
	func colorPopoverControllerDidSelectColor(hexColor: String!) {
		self.navigationItem.rightBarButtonItem?.enabled = true
		self.selectedColors?.append(GzColors.colorFromHex(hexColor))
		self.wePopoverController!.dismissPopoverAnimated(true)
		self.wePopoverController = nil
		self.tableView.reloadData()
	}
	
	func popoverControllerDidDismissPopover(popoverController: WEPopoverController!) {
		self.wePopoverController = nil
	}
	
	func popoverControllerShouldDismissPopover(popoverController: WEPopoverController!) -> Bool {
		return true
	}
	
}
