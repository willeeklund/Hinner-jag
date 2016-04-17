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
    var lineNumber: Int?
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    required public override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }
    
    @IBAction func tapStar(sender: AnyObject) {
        // TODO: Make this on a side queue to not block UI
        if nil != lineNumber {
            Line.toggleLine(lineNumber!)
            // Update button image
            if Line.isLineActive(lineNumber!) {
                starButton.setImage(UIImage(named: "star_full"), forState: .Normal)
            } else {
                starButton.setImage(UIImage(named: "star_empty"), forState: .Normal)
            }
        }
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
            // Find Line number
            cell?.lineNumber = Departure.getLineNumberFromSection(sectionString, departuresDict: departuresDict)
            // Set train image
            if nil != imageName {
                cell?.trainImage.image = UIImage(named: imageName!)
            }
            // Setup star
            if
                nil != cell
                && nil != cell!.lineNumber
                && Line.isLineActive(cell!.lineNumber!)
            {
                cell?.starButton.setImage(UIImage(named: "star_full"), forState: .Normal)
            } else {
                cell?.starButton.setImage(UIImage(named: "star_empty"), forState: .Normal)
            }
            cell?.starButton.addTarget(cell!, action: #selector(tapStar), forControlEvents: .TouchUpInside)
            // Set header text
            cell?.headerLabel?.text = "\(directionLabel) \(directionSuffix)"
        } else {
            cell?.headerLabel?.text = ""
        }
        return cell! as TravelHeaderCell
    }
    
}
