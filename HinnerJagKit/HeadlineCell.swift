//
//  HeadlineCell.swift
//  Hinner jag
//
//  Created by Wilhelm Eklund on 29/03/15.
//  Copyright (c) 2015 Wilhelm Eklund. All rights reserved.
//

import Foundation
import UIKit
import HinnerJagKit

class HeadlineCell: UITableViewCell
{
    var controller: HinnerJagTableViewController?
    @IBOutlet weak var headerLabel: UILabel!
    @IBOutlet weak var closestStationButton: UIButton!
    
    @IBAction func changeSelectedStation(sender: UIButton) {
        if nil != self.controller {
            self.controller!.changeChosenStation()
        }
    }
    
    override init() {
        super.init()
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }
}