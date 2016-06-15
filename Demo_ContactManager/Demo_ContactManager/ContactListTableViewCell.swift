//
//  ContactListTableViewCell.swift
//  Demo_ContactManager
//
//  Created by Bhavik on 10/06/16.
//
//

import UIKit
import AVFoundation


class ContactListTableViewCell: UITableViewCell {
	
	@IBOutlet var IBViewProfilePic: CustomProfileView!
	@IBOutlet var IBlblPhoneNumber: UILabel!
	@IBOutlet var IBlblName: UILabel!
	
	var audioPlayer : AVAudioPlayer?

	var audioRecorder : AVAudioRecorder? {
		didSet {
			audioRecorder?.prepareToRecord()
		}
	}
	
	//MARK:- IBActions -
	
	@IBAction func IBbtnRecordTap(sender: UIButton) {
		sender.selected = !sender.selected
		sender.selected ? startRecording() : stopRecording()
	}
	
	@IBAction func IBbtnPlayTap(sender: UIButton) {
		sender.selected = !sender.selected
		sender.selected ? startPlaying() : stopPlaying()
		
	}
	
	//MARK:- Custom methods -
	
	func stopPlaying() {
		
		if (audioRecorder != nil && audioRecorder?.recording == false){
			do {
				try audioPlayer = AVAudioPlayer(contentsOfURL: audioRecorder!.url)
					audioPlayer?.stop()
			} catch {
			}
		}
		
	}
	
	func startPlaying() {
		
		if (audioRecorder != nil && audioRecorder?.recording == false){
			do {
				try audioPlayer = AVAudioPlayer(contentsOfURL: audioRecorder!.url)
					audioPlayer?.play()
			} catch {
			}
		}
		
	}

	func startRecording() {
		
		if audioRecorder?.recording == false {
			let audioSession = AVAudioSession.sharedInstance()
			do {
				try audioSession.setActive(true)
				audioRecorder?.record()
			} catch {
			}
		}
		
		
	}
	
	func stopRecording() {
		
		audioRecorder?.stop()
		let audioSession = AVAudioSession.sharedInstance()
		
		do {
			try audioSession.setActive(false)
		} catch {
		}
		
	}
	
	
}
