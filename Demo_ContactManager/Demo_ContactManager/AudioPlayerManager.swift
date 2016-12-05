//
//  AudioPlayerManager.swift
//  Demo_ContactManager
//
//  Created by Bhavik on 16/06/16.
//
//

import UIKit
import AVFoundation

class AudioPlayerManager: NSObject {

	static let audioPlayerSharedManager = AudioPlayerManager()
	
	var audioPlayer : AVAudioPlayer!
	
	func playContent(_ urlToPlay : URL) {
		
		audioPlayer?.stop() //stop previous url if any
		
		do {
			try audioPlayer = AVAudioPlayer(contentsOf: urlToPlay)
			audioPlayer?.play()
		} catch {
			}
	}
	
	
	func stopContent(_ urlToStop : URL) {
		do {
			try audioPlayer = AVAudioPlayer(contentsOf: urlToStop)
			audioPlayer?.stop()
		} catch {
		}
	}
}
