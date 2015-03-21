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
    
    override init() {
        super.init()
    }
    
    required override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    required override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }
}
