//: Playground - noun: a place where people can play

import UIKit
import MapKit

let sites = [
    "Slussen",
    "T-centralen",
    "Alvik"
]

var str = "central"

let mainView = UIView(frame: CGRectMake(0, 0, 300, 200))

let topY = CGFloat(60)
for (index, siteTitle) in sites.enumerate() {
    let button = UIButton(frame: CGRectMake(0, topY + CGFloat(index * 30), 100, 30))
    button.setTitle(siteTitle, forState: .Normal)
    button.setTitleColor(UIColor.redColor(), forState: .Normal)
    button.backgroundColor = UIColor(red: 255.0, green: 255.0, blue: 255.0, alpha: 0.7)
    button.setTitleColor(UIColor.blueColor(), forState: .Normal)
    mainView.addSubview(button)
}

mainView
