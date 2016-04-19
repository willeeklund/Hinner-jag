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
    var transportType: TransportType?
    var controller: HinnerJagTableViewController?
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    required public override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }
    
    @IBAction func tapStar(sender: AnyObject) {
        // TODO: Make this on a side queue to not block UI
        if nil != lineNumber {
            let nbrChanged = Line.toggleLine(lineNumber!)
            let toggleDirection: String
            // Update button image
            if Line.isLineActive(lineNumber!) {
                starButton.setImage(UIImage(named: "star_full"), forState: .Normal)
                toggleDirection = "Lade till"
            } else {
                starButton.setImage(UIImage(named: "star_empty"), forState: .Normal)
                toggleDirection = "Tog bort"
            }
            // Make controller create new mappings from departures and reload table
            controller?.createMappingFromFetchedDepartures()
            // Update HeadlineCell info label. Do it double to be safe.
            let newMessage = "\(toggleDirection) \(nbrChanged) busstationer på linje \(lineNumber!)"
            HeadlineCell.infoMessage = newMessage
            NSNotificationCenter.defaultCenter().postNotificationName(HeadlineCell.notificationEventInfoMessage, object: nil, userInfo: [
                "message": newMessage
            ])
        }
    }
    
    internal class func createCellForIndexPath(
        section: Int,
        controller: HinnerJagTableViewController,
        tableView: UITableView,
        mappingDict: Dictionary <Int, String>,
        departuresDict: Dictionary<String, [Departure]>
    ) -> TravelHeaderCell {
        let reuseId = "TravelHeaderCell"
        var cell = tableView.dequeueReusableCellWithIdentifier(reuseId) as? TravelHeaderCell
        if nil == cell {
            cell = TravelHeaderCell()
        }
        cell?.controller = controller
        if let sectionString = mappingDict[section] {
            let directionSuffix = Departure.createDirectionSuffix(sectionString, departuresDict: departuresDict)
            let (directionLabel, imageName, _) = Departure.createLabelAndImageNameFromSection(sectionString, departuresDict: departuresDict)
            // Find Line number
            (cell!.lineNumber, cell!.transportType) = Departure.getLineNumberAndTransportTypeFromSection(sectionString, departuresDict: departuresDict)
            // Set train image
            if nil != imageName {
                cell?.trainImage.image = UIImage(named: imageName!)
            }
            // Setup star button
            if nil != cell!.transportType && .Bus == cell!.transportType! {
                cell?.starButton.hidden = false
                if nil != cell!.lineNumber && Line.isLineActive(cell!.lineNumber!) {
                    cell?.starButton.setImage(UIImage(named: "star_full"), forState: .Normal)
                } else {
                    cell?.starButton.setImage(UIImage(named: "star_empty"), forState: .Normal)
                }
                cell?.starButton.addTarget(cell!, action: #selector(tapStar), forControlEvents: .TouchUpInside)
            } else {
                cell?.starButton.hidden = true
            }
            // Set header text
            cell?.headerLabel?.text = "\(directionLabel) \(directionSuffix)"
        } else {
            cell?.headerLabel?.text = ""
        }
        return cell! as TravelHeaderCell
    }
    
}
