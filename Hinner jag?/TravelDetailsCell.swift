//
//  TravelDetailsCell.swift
//  Hinner jag?
//
//  Created by Wilhelm Eklund on 09/03/15.
//  Copyright (c) 2015 Wilhelm Eklund. All rights reserved.
//

import Foundation
import UIKit

class TravelDetailsCell: UITableViewCell
{
    
    @IBOutlet weak var remainingTimeLabel: UILabel!
    @IBOutlet weak var destinationLabel: UILabel!
    var lineColor: UIColor = UIColor.greenColor()
    
    override init() {
        super.init()
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}
