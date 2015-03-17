//
//  TravelHeaderCell.swift
//  Hinner jag?
//
//  Created by Wilhelm Eklund on 09/03/15.
//  Copyright (c) 2015 Wilhelm Eklund. All rights reserved.
//

import Foundation
import UIKit

class TravelHeaderCell: UITableViewCell
{
    
    @IBOutlet weak var trainImage: UIImageView!
    @IBOutlet weak var headerLabel: UILabel!
    var lineColor: UIColor = UIColor.greenColor()
    
    override init() {
        super.init()
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}
