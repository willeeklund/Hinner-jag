//
//  BWWalkThroughVideoViewController.swift
//  Hinner jag
//
//  Created by Wilhelm Eklund on 25/04/16.
//  Copyright © 2016 Wilhelm Eklund. All rights reserved.
//

import Foundation
import MediaPlayer

class BWWalkThroughVideoViewController: BWWalkthroughPageViewController {
    
    var moviePlayer: MPMoviePlayerController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let path = NSBundle.mainBundle().pathForResource("screen_intro_2", ofType:"mp4") {
            let url = NSURL.fileURLWithPath(path)
            self.moviePlayer = MPMoviePlayerController(contentURL: url)
            if let player = self.moviePlayer {
                let deltaY = CGFloat(60)
                player.view.frame = CGRect(x: 0, y: deltaY, width: self.view.frame.size.width, height: self.view.frame.size.height - deltaY * 2)
                player.view.sizeToFit()
                player.scalingMode = .AspectFit
                player.controlStyle = .Embedded
                player.backgroundView.backgroundColor = UIColor.whiteColor()
                player.movieSourceType = .File
                player.repeatMode = MPMovieRepeatMode.None
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
        }
    }
    
}
