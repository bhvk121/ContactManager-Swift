//
//  ViewController.swift
//  Demo_ContactManager
//
//  Created by Bhavik on 10/06/16.
//
//

import UIKit
import Contacts

class ViewController: UIViewController, UISearchResultsUpdating {
	
	@IBOutlet var IBtblViewContactList: UITableView!
	
	let searchController = UISearchController(searchResultsController: nil)
	
	lazy var arrContacts = [CNContact]()
	lazy var arrFilteredContacts = [CNContact]()

	lazy var contactStore = CNContactStore()

	override func viewDidLoad() {
		super.viewDidLoad()
		checkforContactPermission()
		setSearchController()
		setRefreshControl()
	}
	
	
	//MARK:- Custom Methods -
	
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
	
	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}
}