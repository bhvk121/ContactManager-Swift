//
//  ContactListTableViewCell.swift
//  Demo_ContactManager
//
//  Created by Bhavik on 10/06/16.
//
//

import UIKit
import AVFoundation

protocol  ContactListTableViewCellProtocol {
	func onRecordStart(_ activeRecorder : AVAudioRecorder?)
	func onRecordStop(_ activeRecorder : AVAudioRecorder?)
	func onPlayStart(_ activeRecorder : AVAudioRecorder?)
	func onPlayStop(_ activeRecorder : AVAudioRecorder?)
}

class ContactListTableViewCell: UITableViewCell {
	
	@IBOutlet var IBViewProfilePic: CustomProfileView!
	@IBOutlet var IBlblPhoneNumber: UILabel!
	@IBOutlet var IBlblName: UILabel!
	
	var contactListTableViewCellDelegate : ContactListTableViewCellProtocol?
	var audioPlayer : AVAudioPlayer?
	var audioRecorder : AVAudioRecorder?
	
	override func awakeFromNib() {
		
	}
	
	//MARK:- IBActions -
	
	@IBAction func IBbtnRecordTap(_ sender: UIButton) {
		sender.isSelected = !sender.isSelected
		sender.isSelected ? startRecording() : stopRecording()
	}
	
	@IBAction func IBbtnPlayTap(_ sender: UIButton) {
		sender.isSelected = !sender.isSelected
		sender.isSelected ? startPlaying() : stopPlaying()
		
	}
	
	//MARK:- Custom methods -
	
	func stopPlaying() {
		contactListTableViewCellDelegate?.onPlayStop(audioRecorder)
	}
	
	func startPlaying() {
		contactListTableViewCellDelegate?.onPlayStart(audioRecorder)
	}

	func startRecording() {
		contactListTableViewCellDelegate?.onRecordStart(audioRecorder)
	}
	
	func stopRecording() {
		contactListTableViewCellDelegate?.onRecordStop(audioRecorder)
	}
	
	
}
