//
//  BWWalkThroughVideoViewController.swift
//  Hinner jag
//
//  Created by Wilhelm Eklund on 25/04/16.
//  Copyright © 2016 Wilhelm Eklund. All rights reserved.
//

import Foundation
import MediaPlayer
import HinnerJagKit

class BWWalkThroughVideoViewController: BWWalkthroughPageViewController {
    
    var moviePlayer: MPMoviePlayerController!
    var timerForWatching: Timer?
    
    deinit {
        timerForWatching?.invalidate()
        moviePlayer.stop()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        gaSetup()
        if let path = Bundle.main.path(forResource: "screen_intro", ofType:"mp4") {
            let url = URL(fileURLWithPath: path)
            self.moviePlayer = MPMoviePlayerController(contentURL: url)
            if let player = self.moviePlayer {
                let deltaY = CGFloat(60)
                player.view.frame = CGRect(x: 0, y: deltaY, width: self.view.frame.size.width, height: self.view.frame.size.height - deltaY * 2)
                player.view.sizeToFit()
                player.scalingMode = .aspectFit
                player.controlStyle = .embedded
                player.backgroundView.backgroundColor = UIColor.white
                player.movieSourceType = .file
                player.repeatMode = MPMovieRepeatMode.none
                self.view.addSubview(player.view)
            } else {
                print("Could not create MediaPlayer")
            }
        } else {
            print("Could not load file 'screen_intro_1.mp4'")
        }
    }
    
    func playMovie() {
        if let player = self.moviePlayer {
            player.play()
            // If user still see this view after 25 sec,
            // track event because they viewed the whole video
            timerForWatching = Timer.schedule(delay: 25) { [weak self] (timer) in
                if self != nil {
                    print("User did watch entire intro video")
                    self!.trackEvent("Walkthrough", action: "watched", label: "entire video", value: (self!.checkFirstTimeSeenEntireVideo() ? 1 : 0))
                }
            }
        }
    }
    
    func checkFirstTimeSeenEntireVideo() -> Bool {
        let walkthroughKey = "hasSeenEntireVideo2"
        if !UserDefaults.standard.bool(forKey: walkthroughKey) {
            UserDefaults.standard.set(true, forKey: walkthroughKey)
            UserDefaults.standard.synchronize()
            return true
        }
        return false
    }
}
