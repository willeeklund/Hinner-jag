//
//  TravelHeaderCell.swift
//  Hinner jag?
//
//  Created by Wilhelm Eklund on 09/03/15.
//  Copyright (c) 2015 Wilhelm Eklund. All rights reserved.
//

import Foundation
import UIKit
import HinnerJagKit

public class TravelHeaderCell: UITableViewCell
{
    
    @IBOutlet weak var trainImage: UIImageView!
    @IBOutlet weak var starButton: UIButton!
    @IBOutlet weak var headerLabel: UILabel!
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    required public override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }
    
    @IBAction func tapStar(sender: AnyObject) {
        print("We tapped a star")
        starButton.setImage(UIImage(named: "star_full"), forState: .Normal)
    }
    
    internal class func createCellForIndexPath(
        section: Int,
        tableView: UITableView,
        mappingDict: Dictionary <Int, String>,
        departuresDict: Dictionary<String, [Departure]>
    ) -> TravelHeaderCell {
        let reuseId = "TravelHeaderCell"
        var cell = tableView.dequeueReusableCellWithIdentifier(reuseId) as? TravelHeaderCell
        if nil == cell {
            cell = TravelHeaderCell()
        }
        if let sectionString = mappingDict[section] {
            let directionSuffix = Departure.createDirectionSuffix(sectionString, departuresDict: departuresDict)
            let (directionLabel, imageName, _) = Departure.createLabelAndImageNameFromSection(sectionString, departuresDict: departuresDict)
            // Set train image
            if nil != imageName {
                cell?.trainImage.image = UIImage(named: imageName!)
            }
            // Setup star
            cell?.starButton.setImage(UIImage(named: "star_empty"), forState: .Normal)
            cell?.starButton.addTarget(cell!, action: #selector(tapStar), forControlEvents: .TouchUpInside)
            cell?.starButton.hidden = true
            // Set header text
            cell?.headerLabel?.text = "\(directionLabel) \(directionSuffix)"
        } else {
            cell?.headerLabel?.text = ""
        }
        return cell! as TravelHeaderCell
    }
    
}
