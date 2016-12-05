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

	var soundFileURL:URL!
	var audioRecorder:AVAudioRecorder!
	var audioPlayer : AVAudioPlayer!

	let audioSession = AVAudioSession.sharedInstance()
	let searchController = UISearchController(searchResultsController: nil)
	let recordSettings:[String : AnyObject] = [
		AVFormatIDKey: NSNumber(value: kAudioFormatAppleLossless as UInt32),
		AVEncoderAudioQualityKey : AVAudioQuality.max.rawValue as AnyObject,
		AVEncoderBitRateKey : 320000 as AnyObject,
		AVNumberOfChannelsKey: 2 as AnyObject,
		AVSampleRateKey : 44100.0 as AnyObject
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
		refreshControl.addTarget(self, action: #selector(ViewController.refresh(_:)), for: .valueChanged)
		IBtblViewContactList.addSubview(refreshControl)
	}
	
	func refresh(_ refreshControl: UIRefreshControl) {
		
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
		switch CNContactStore.authorizationStatus(for: .contacts) {
			
		case .authorized:
			fetchContacts()
			
		case .notDetermined:
			contactStore.requestAccess(for: .contacts){succeeded, err in
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
			CNContactFormatter.descriptorForRequiredKeys(for: .fullName),
			CNContactEmailAddressesKey,
			CNContactPhoneNumbersKey,
			CNContactImageDataKey] as [Any]
		
		// Get all the containers
		var allContainers: [CNContainer] = []
		do {
			allContainers = try contactStore.containers(matching: nil)
		} catch {
			print("Error fetching containers")
		}
		
		
		// Iterate all containers and append their contacts to our results array
		for container in allContainers {
			let fetchPredicate = CNContact.predicateForContactsInContainer(withIdentifier: container.identifier)
			
			do {
				let containerResults = try contactStore.unifiedContacts(matching: fetchPredicate, keysToFetch: keysToFetch as! [CNKeyDescriptor])
				arrContacts.append(contentsOf: containerResults)
			} catch {
				print("Error fetching results for container")
			}
		}
		
		IBtblViewContactList.reloadData()
		
	}
	
	func filterContentForSearchText(_ searchText: String) {
		arrFilteredContacts = arrContacts.filter { contact in
			return (contact.givenName.lowercased().contains(searchText.lowercased()) ||
				contact.familyName.lowercased().contains(searchText.lowercased()))
		}
		
		IBtblViewContactList.reloadData()
	}

	
	//MARK:- Audio related methods -
	func getSoundURLForIndex(_ index : Int) -> URL {
		
		let dirPaths =
			NSSearchPathForDirectoriesInDomains(.documentDirectory,
			                                    .userDomainMask, true)
		let docsDir = dirPaths[0]
		let soundFilePath = docsDir + "/sound\(index).m4a"
		return URL(fileURLWithPath: soundFilePath)
		
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
	
	func recordWithPermission(_ setup:Bool) {
		let session:AVAudioSession = AVAudioSession.sharedInstance()
		// ios 8 and later
		if (session.responds(to: #selector(AVAudioSession.requestRecordPermission(_:)))) {
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
	
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
	  if searchController.isActive && searchController.searchBar.text != "" {
		return arrFilteredContacts.count
	  }
	  return arrContacts.count
	}
	
	func tableView(_ tableView: UITableView, cellForRowAtIndexPath indexPath: IndexPath) -> UITableViewCell {
		let cell : ContactListTableViewCell = tableView.dequeueReusableCell(withIdentifier: "ContactListTableViewCellID", for: indexPath) as! ContactListTableViewCell
		let currentContact : CNContact!
		if searchController.isActive && searchController.searchBar.text != "" {
			currentContact = arrFilteredContacts[(indexPath as NSIndexPath).row]
		} else {
			currentContact = arrContacts[(indexPath as NSIndexPath).row]
		}
		
		cell.contactListTableViewCellDelegate = self
		
		//AVAudio related code
		
		do {
			try audioSession.setCategory(AVAudioSessionCategoryPlayAndRecord)
			try audioRecorder = AVAudioRecorder(url: getSoundURLForIndex((indexPath as NSIndexPath).row),
			                                    settings: recordSettings)
			cell.audioRecorder = audioRecorder
			
		}
		catch {
		}
		
		cell.IBlblName.text = "\(currentContact.givenName) \(currentContact.familyName)"
		
		if (currentContact.isKeyAvailable(CNContactPhoneNumbersKey)) {
			for phoneNumber:CNLabeledValue in currentContact.phoneNumbers {
				let primaryPhoneNumber = phoneNumber.value 
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

	func updateSearchResults(for searchController: UISearchController) {
		filterContentForSearchText(searchController.searchBar.text!)
	}
	
	//MARK:- ContactListTableViewCellProtocol -
	
	func onRecordStop(_ activeRecorder: AVAudioRecorder?) {
		activeRecorder?.stop()
		let audioSession = AVAudioSession.sharedInstance()
		
		do {
			try audioSession.setActive(false)
		} catch {
		}

	}
	
	func onRecordStart(_ activeRecorder: AVAudioRecorder?) {
		recordWithPermission(false)
		activeRecorder?.prepareToRecord()
		if activeRecorder?.isRecording == false {
			let audioSession = AVAudioSession.sharedInstance()
			do {
				try audioSession.setActive(true)
				activeRecorder?.record()
			} catch {
			}
		}
	}

	func onPlayStart(_ activeRecorder: AVAudioRecorder?) {
		if (activeRecorder != nil && activeRecorder?.isRecording == false){
		AudioPlayerManager.audioPlayerSharedManager.playContent(activeRecorder!.url)
		}
	}
	
	func onPlayStop(_ activeRecorder: AVAudioRecorder?) {
		if (activeRecorder != nil && activeRecorder?.isRecording == false){
		AudioPlayerManager.audioPlayerSharedManager.stopContent(activeRecorder!.url)
		}
	}
	
	//MARK:- iOS delegate methods -
	
	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}
}
