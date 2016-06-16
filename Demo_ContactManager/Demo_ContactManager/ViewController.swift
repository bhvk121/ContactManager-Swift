//
//  ViewController.swift
//  Demo_ContactManager
//
//  Created by Bhavik on 10/06/16.
//
//

import UIKit
import AVFoundation
import Contacts

class ViewController: UIViewController, UISearchResultsUpdating, ContactListTableViewCellProtocol {
	
	@IBOutlet var IBtblViewContactList: UITableView!
	
	lazy var arrContacts = [CNContact]()
	lazy var arrFilteredContacts = [CNContact]()
	lazy var contactStore = CNContactStore()

	var soundFileURL:NSURL!
	var audioRecorder:AVAudioRecorder!
	var audioPlayer : AVAudioPlayer!

	let audioSession = AVAudioSession.sharedInstance()
	let searchController = UISearchController(searchResultsController: nil)
	let recordSettings:[String : AnyObject] = [
		AVFormatIDKey: NSNumber(unsignedInt:kAudioFormatAppleLossless),
		AVEncoderAudioQualityKey : AVAudioQuality.Max.rawValue,
		AVEncoderBitRateKey : 320000,
		AVNumberOfChannelsKey: 2,
		AVSampleRateKey : 44100.0
	]
	
	//MARK:- UIViewController Life Cycle -
	override func viewDidLoad() {
		super.viewDidLoad()
		checkforContactPermission()
		setSearchController()
		setRefreshControl()
	}
	
	//MARK:- Screen setup -

	func setRefreshControl() {
		let refreshControl = UIRefreshControl()
		refreshControl.addTarget(self, action: #selector(ViewController.refresh(_:)), forControlEvents: .ValueChanged)
		IBtblViewContactList.addSubview(refreshControl)
	}
	
	func refresh(refreshControl: UIRefreshControl) {
		
		checkforContactPermission()
		refreshControl.endRefreshing()
	}
	
	func setSearchController() {
		searchController.searchResultsUpdater = self
		searchController.dimsBackgroundDuringPresentation = false
		definesPresentationContext = false
		IBtblViewContactList.tableHeaderView = searchController.searchBar
	}

	//MARK:- Contact related methods -
	
	func checkforContactPermission() {
		switch CNContactStore.authorizationStatusForEntityType(.Contacts) {
			
		case .Authorized:
			fetchContacts()
			
		case .NotDetermined:
			contactStore.requestAccessForEntityType(.Contacts){succeeded, err in
				guard err == nil && succeeded else{
					return
				}
				self.fetchContacts()
			}
		default:
			print("Not handled")
		}
	}
	
	func fetchContacts() {
		
		//reset contact list
		arrContacts.removeAll()
		
		let keysToFetch = [
			CNContactFormatter.descriptorForRequiredKeysForStyle(.FullName),
			CNContactEmailAddressesKey,
			CNContactPhoneNumbersKey,
			CNContactImageDataKey]
		
		// Get all the containers
		var allContainers: [CNContainer] = []
		do {
			allContainers = try contactStore.containersMatchingPredicate(nil)
		} catch {
			print("Error fetching containers")
		}
		
		
		// Iterate all containers and append their contacts to our results array
		for container in allContainers {
			let fetchPredicate = CNContact.predicateForContactsInContainerWithIdentifier(container.identifier)
			
			do {
				let containerResults = try contactStore.unifiedContactsMatchingPredicate(fetchPredicate, keysToFetch: keysToFetch)
				arrContacts.appendContentsOf(containerResults)
			} catch {
				print("Error fetching results for container")
			}
		}
		
		IBtblViewContactList.reloadData()
		
	}
	
	func filterContentForSearchText(searchText: String) {
		arrFilteredContacts = arrContacts.filter { contact in
			return (contact.givenName.lowercaseString.containsString(searchText.lowercaseString) ||
				contact.familyName.lowercaseString.containsString(searchText.lowercaseString))
		}
		
		IBtblViewContactList.reloadData()
	}

	
	//MARK:- Audio related methods -
	func getSoundURLForIndex(index : Int) -> NSURL {
		
		let dirPaths =
			NSSearchPathForDirectoriesInDomains(.DocumentDirectory,
			                                    .UserDomainMask, true)
		let docsDir = dirPaths[0]
		let soundFilePath = docsDir + "/sound\(index).m4a"
		return NSURL(fileURLWithPath: soundFilePath)
		
	}
	
	func setSessionPlayAndRecord() {
		let session = AVAudioSession.sharedInstance()
		
		do {
			try session.setCategory(AVAudioSessionCategoryPlayAndRecord)
		
		} catch  {
			print("could not set session category")
		}
		
		do {
			try session.setActive(true)
		} catch  {
			print("could not make session active")
		}
	}
	
	func recordWithPermission(setup:Bool) {
		let session:AVAudioSession = AVAudioSession.sharedInstance()
		// ios 8 and later
		if (session.respondsToSelector(#selector(AVAudioSession.requestRecordPermission(_:)))) {
			AVAudioSession.sharedInstance().requestRecordPermission({(granted: Bool)-> Void in
				if granted {
					print("Permission to record granted")
					self.setSessionPlayAndRecord()
				} else {
					print("Permission to record not granted")
				}
			})
		} else {
			print("requestRecordPermission unrecognized")
		}
	}
	
	
	
	//MARK:- UITableView delegate -
	
	func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
	  if searchController.active && searchController.searchBar.text != "" {
		return arrFilteredContacts.count
	  }
	  return arrContacts.count
	}
	
	func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		let cell : ContactListTableViewCell = tableView.dequeueReusableCellWithIdentifier("ContactListTableViewCellID", forIndexPath: indexPath) as! ContactListTableViewCell
		let currentContact : CNContact!
		if searchController.active && searchController.searchBar.text != "" {
			currentContact = arrFilteredContacts[indexPath.row]
		} else {
			currentContact = arrContacts[indexPath.row]
		}
		
		cell.contactListTableViewCellDelegate = self
		
		//AVAudio related code
		
		do {
			try audioSession.setCategory(AVAudioSessionCategoryPlayAndRecord)
			try audioRecorder = AVAudioRecorder(URL: getSoundURLForIndex(indexPath.row),
			                                    settings: recordSettings)
			cell.audioRecorder = audioRecorder
			
		}
		catch {
		}
		
		cell.IBlblName.text = "\(currentContact.givenName) \(currentContact.familyName)"
		
		if (currentContact.isKeyAvailable(CNContactPhoneNumbersKey)) {
			for phoneNumber:CNLabeledValue in currentContact.phoneNumbers {
				let primaryPhoneNumber = phoneNumber.value as! CNPhoneNumber
				cell.IBlblPhoneNumber?.text = primaryPhoneNumber.stringValue
			}
		}
		
		// Set the contact image.
		let intialFirst = currentContact.givenName.characters.first
		let intialSecond = currentContact.familyName.characters.first
		
		
		if let imageData = currentContact.imageData {
			cell.IBViewProfilePic.setValueForProfile(true, imageData: imageData)
		} else {
			cell.IBViewProfilePic.setValueForProfile(true, nameInitials: "\(intialFirst ?? "N")\(intialSecond ?? "A")", fontSize: 32.0, imageData: nil)
		}
		return cell
	}
	

	
	
	//MARK:- UISearch Delegates -

	func updateSearchResultsForSearchController(searchController: UISearchController) {
		filterContentForSearchText(searchController.searchBar.text!)
	}
	
	//MARK:- ContactListTableViewCellProtocol -
	
	func onRecordStop(activeRecorder: AVAudioRecorder?) {
		activeRecorder?.stop()
		let audioSession = AVAudioSession.sharedInstance()
		
		do {
			try audioSession.setActive(false)
		} catch {
		}

	}
	
	func onRecordStart(activeRecorder: AVAudioRecorder?) {
		recordWithPermission(false)
		activeRecorder?.prepareToRecord()
		if activeRecorder?.recording == false {
			let audioSession = AVAudioSession.sharedInstance()
			do {
				try audioSession.setActive(true)
				activeRecorder?.record()
			} catch {
			}
		}
	}

	func onPlayStart(activeRecorder: AVAudioRecorder?) {
		if (activeRecorder != nil && activeRecorder?.recording == false){
		AudioPlayerManager.audioPlayerSharedManager.playContent(activeRecorder!.url)
		}
	}
	
	func onPlayStop(activeRecorder: AVAudioRecorder?) {
		if (activeRecorder != nil && activeRecorder?.recording == false){
		AudioPlayerManager.audioPlayerSharedManager.stopContent(activeRecorder!.url)
		}
	}
	
	//MARK:- iOS delegate methods -
	
	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}
}