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
    // MARK: - Properties
    @IBOutlet weak var trainImageButton: UIButton!
    @IBOutlet weak var headerButton: UIButton!
    @IBOutlet weak var starButton: UIButton!

    var lineNumber: Int?
    var transportType: TransportType?
    var controller: HinnerJagTableViewController?
    
    // MARK: - Init
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    required public override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }
    
    // MARK: - Interact with table cell
    @IBAction func tapImageOrHeader(sender: AnyObject) {
        if nil != lineNumber && nil != transportType {
            let chosenStopAreaTypeCode = transportType!.stopAreaTypeCode()
            // Check if we are in TodayExtension
            if nil != controller?.extensionContext {
                // Launch app and show map with only stations along this line
                let query = "line=\(lineNumber!)&stopAreaTypeCode=\(chosenStopAreaTypeCode)"
                if let hinnerJagUrl = NSURL(string: "hinner-jag://map?\(query)") {
                    controller?.extensionContext?.openURL(hinnerJagUrl, completionHandler: nil)
                }
            } else {
                let selectedDict: Dictionary<String, AnyObject> = [
                    "lineNumber": lineNumber!,
                    "stopAreaTypeCode": chosenStopAreaTypeCode
                ]
                controller?.performSegueWithIdentifier("Show Map", sender: selectedDict)
            }
        }
    }
    
    @IBAction func tapStar(sender: AnyObject) {
        // TODO: Make this on a side queue to not block UI
        let stopAreaTypeCode = transportType?.stopAreaTypeCode()
        if nil != lineNumber {
            let nbrChanged = Line.toggleLine(lineNumber!, withStopAreaTypeCode: stopAreaTypeCode)
            let toggleDirection: String
            // Update button image
            if Line.isLineActive(lineNumber!, withStopAreaTypeCode: stopAreaTypeCode) {
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
            NSNotificationCenter.defaultCenter().postNotificationName(Constants.notificationEventInfoMessage, object: nil, userInfo: [
                "message": newMessage
            ])
        }
    }
    
    // MARK: - Create cell instance
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
                cell?.trainImageButton.setImage(UIImage(named: imageName!), forState: .Normal)
                cell?.trainImageButton.addTarget(cell!, action: #selector(tapImageOrHeader), forControlEvents: .TouchUpInside)
            }
            // Setup star button
            if nil != cell!.transportType && .Bus == cell!.transportType! {
                cell?.starButton.hidden = false
                if
                    nil != cell!.lineNumber
                    && Line.isLineActive(cell!.lineNumber!, withStopAreaTypeCode: cell!.transportType?.stopAreaTypeCode())
                {
                    cell?.starButton.setImage(UIImage(named: "star_full"), forState: .Normal)
                } else {
                    cell?.starButton.setImage(UIImage(named: "star_empty"), forState: .Normal)
                }
                cell?.starButton.addTarget(cell!, action: #selector(tapStar), forControlEvents: .TouchUpInside)
            } else {
                cell?.starButton.hidden = true
            }
            // Set header text
            cell?.headerButton.setTitle("\(directionLabel) \(directionSuffix)", forState: .Normal)
            cell?.headerButton.addTarget(cell!, action: #selector(tapImageOrHeader), forControlEvents: .TouchUpInside)
            if nil != controller.extensionContext {
                // In TodayViewController
                cell?.headerButton.tintColor = Constants.linkColor
            }
        } else {
            cell?.headerButton.setTitle("", forState: .Normal)
        }
        return cell! as TravelHeaderCell
    }
    
}
