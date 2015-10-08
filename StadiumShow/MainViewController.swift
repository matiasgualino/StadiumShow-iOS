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
	var showInitialized : Bool = false
	
	var wePopoverController : WEPopoverController?
	
	init() {
		super.init(nibName: "MainViewController", bundle: nil)
		self.automaticallyAdjustsScrollViewInsets = false
	}
	
	required init(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	override func viewDidAppear(animated: Bool) {
		self.view.backgroundColor = UIColor.whiteColor()
		self.navigationController?.navigationBar.barTintColor = UIColor.whiteColor()
	}
	
    override func viewDidLoad() {
        super.viewDidLoad()
		
		bannerView.adUnitID = "ca-app-pub-4401161763017089/4145738854"
		bannerView.rootViewController = self
		bannerView.loadRequest(GADRequest())
		
		setRightButtonInit()
		setSegments()
		
		device = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo)
		
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
		if flashlightON {
			self.navigationItem.rightBarButtonItem = nil
		} else {
			let btnContinue = UIBarButtonItem(title: "Iniciar", style: UIBarButtonItemStyle.Plain, target: self, action: Selector("initializeShow"))
			btnContinue.enabled = true
			btnContinue.tintColor = UIColor.blueColor()
			self.navigationItem.rightBarButtonItem = btnContinue
			if (self.selectedColors != nil && self.selectedColors!.count > 0) {
				self.navigationItem.rightBarButtonItem?.enabled = true
			} else {
				self.navigationItem.rightBarButtonItem?.enabled = false
			}
		}
	}
	
	func delayChanged() {
		let phi = flashlightON ? 1 : 0.5
		let pot = phi * Double(self.delaySegmented.selectedSegmentIndex)
		self.delay = pow(2.7183, -pot)
		if self.flashlightON {
			if self.delaySegmented.selectedSegmentIndex == 0 {
					timer?.invalidate()
					running = false
					changeFlash()
			} else {
				timer?.invalidate()
				timer = NSTimer.scheduledTimerWithTimeInterval(self.delay, target: self, selector: Selector("changeFlash"), userInfo: nil, repeats: true)
			}
		}
	}
	
	func initializeShow() {
		showInitialized = true
		self.navigationController?.pushViewController(ShowColorsViewController(colors: selectedColors!, delay: self.delay), animated: true)
	}
	
	func finishShow() {
		showInitialized = false
		setRightButtonInit()
		timer?.invalidate()
		self.running = false
		self.AVSession?.stopRunning()
		do {
			try device.lockForConfiguration()
			device.torchMode = AVCaptureTorchMode.Off
			device.unlockForConfiguration()
		} catch {
			
		}
		
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
			let flashlightCell = (self.tableView.dequeueReusableCellWithIdentifier("FlashlightTableViewCell") as? FlashlightTableViewCell)!
			flashlightCell.flashlightDelegate = self
			if flashlightON {
				return flashlightCell
			} else {
				if indexPath.row == 0 {
					return flashlightCell
				} else if indexPath.row == 1 {
					let cell = UITableViewCell(style: UITableViewCellStyle.Default, reuseIdentifier: "SelectColor")
					cell.textLabel?.text = "Seleccionar colores"
					cell.textLabel?.font = UIFont(name: "HelveticaNeue", size: 15.0)
					cell.accessoryType = UITableViewCellAccessoryType.DisclosureIndicator
					return cell
				}
			}
		} else {
			let cell = UITableViewCell(style: UITableViewCellStyle.Default, reuseIdentifier: "SelectedColor")
			cell.backgroundColor = selectedColors![indexPath.row]
			cell.accessoryType = UITableViewCellAccessoryType.DisclosureIndicator
			return cell
		}
		return UITableViewCell()
	}
	
	func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
		if indexPath.section == 0 && indexPath.row == 1 {
			if self.wePopoverController == nil {
				let contentViewController : ColorViewController = ColorViewController()
				contentViewController.delegate = self
				self.wePopoverController = WEPopoverController(contentViewController: contentViewController)
				self.wePopoverController!.delegate = self
				self.wePopoverController!.passthroughViews = NSArray(objects: self.navigationController!.navigationBar) as [AnyObject]
				
				self.wePopoverController?.presentPopoverFromRect(CGRectMake((self.view.frame.size.width / 2.0) - 50, 144, 100, 100), inView: self.view, permittedArrowDirections: [UIPopoverArrowDirection.Up, UIPopoverArrowDirection.Down], animated: true)
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
		setRightButtonInit()
		setSegments()
		self.delaySegmented.selectedSegmentIndex = 0
		delayChanged()
		if !flashlightON {
			finishShow()
		}
		
		
		/*
		if !flashlightON || (self.selectedColors != nil && self.selectedColors!.count > 0) {
			self.navigationItem.rightBarButtonItem?.enabled = false
			delayChanged()
			finishShow()
		} else {
			if self.delaySegmented.selectedSegmentIndex == 0 {
				self.delay = 0.0
			} else if self.delaySegmented.selectedSegmentIndex == 4 {
				self.delay = self.delay/50
			}
			self.navigationItem.rightBarButtonItem?.enabled = true
		}
*/
		self.tableView.reloadData()
	}
	
	func setSegments() {
		self.delaySegmented.removeAllSegments()
		if self.flashlightON {
			self.delaySegmented.removeAllSegments()
			self.delaySegmented.insertSegmentWithTitle("ON", atIndex: 0, animated: true)
			self.delaySegmented.insertSegmentWithTitle("1", atIndex: 1, animated: true)
			self.delaySegmented.insertSegmentWithTitle("2", atIndex: 2, animated: true)
			self.delaySegmented.insertSegmentWithTitle("3", atIndex: 3, animated: true)
			self.delaySegmented.insertSegmentWithTitle("4", atIndex: 4, animated: true)
		} else {
			self.delaySegmented.insertSegmentWithTitle("1", atIndex: 0, animated: true)
			self.delaySegmented.insertSegmentWithTitle("2", atIndex: 1, animated: true)
			self.delaySegmented.insertSegmentWithTitle("3", atIndex: 2, animated: true)
			self.delaySegmented.insertSegmentWithTitle("4", atIndex: 3, animated: true)
			self.delaySegmented.insertSegmentWithTitle("5", atIndex: 4, animated: true)
		}
	}
	
	func createSessionFlashLight() {
		do {
			let session : AVCaptureSession = AVCaptureSession()
			let input : AVCaptureDeviceInput = try AVCaptureDeviceInput(device: device)
			session.addInput(input)
			
			let output : AVCaptureVideoDataOutput = AVCaptureVideoDataOutput()
			session.addOutput(output)
			
			session.beginConfiguration()
			try device.lockForConfiguration()
			
			device.torchMode = AVCaptureTorchMode.On
			
			try device.setTorchModeOnWithLevel(1.0)
			
			device.unlockForConfiguration()
			session.commitConfiguration()
			
			session.startRunning()
			
			AVSession = session
		} catch {
			
		}
	}

	func changeFlash() {
		do {
			device = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo)
			if device.hasTorch {
				try device.lockForConfiguration()
				device.torchMode = self.running ? AVCaptureTorchMode.Off : AVCaptureTorchMode.On
				device.unlockForConfiguration()
			}
		} catch {
			
		}
		self.running = !self.running
		
		
		
/*		if self.running {
			self.running = false
			self.AVSession?.stopRunning()
		} else {
			createSessionFlashLight()
			self.running = true
		}*/
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
