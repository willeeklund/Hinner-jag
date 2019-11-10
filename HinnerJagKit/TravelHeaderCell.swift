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

open class TravelHeaderCell: UITableViewCell
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
    
    required public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }
    
    // MARK: - Interact with table cell
    @IBAction func tapImageOrHeader(_ sender: AnyObject) {
        if nil != lineNumber && nil != transportType {
            let chosenStopAreaTypeCode = transportType!.stopAreaTypeCode()
            let query = "line=\(lineNumber!)&stopAreaTypeCode=\(chosenStopAreaTypeCode)"
            // Check if we are in TodayExtension
            if nil != controller?.extensionContext {
                // Launch app and show map with only stations along this line
                if let hinnerJagUrl = URL(string: "hinner-jag://map?\(query)") {
                    controller?.extensionContext?.open(hinnerJagUrl, completionHandler: nil)
                    controller?.trackEvent("Show line sites", action: "TodayWidget: callOpenUrl", label: hinnerJagUrl.absoluteString, value: nil)
                }
            } else {
                let selectedDict: Dictionary<String, AnyObject> = [
                    "lineNumber": lineNumber! as AnyObject,
                    "stopAreaTypeCode": chosenStopAreaTypeCode as AnyObject
                ]
                controller?.performSegue(withIdentifier: "Show Map", sender: selectedDict)
                controller?.trackEvent("Show line sites", action: "Show Map", label: query, value: nil)
            }
        }
    }
    
    @IBAction func tapStar(_ sender: AnyObject) {
        // TODO: Make this on a side queue to not block UI
        let stopAreaTypeCode = transportType?.stopAreaTypeCode()
        if nil != lineNumber {
            let nbrChanged = Line.toggleLine(lineNumber!, withStopAreaTypeCode: stopAreaTypeCode)
            let toggleDirection: String
            // Update button image
            if Line.isLineActive(lineNumber!, withStopAreaTypeCode: stopAreaTypeCode) {
                starButton.setImage(UIImage(named: "star_full"), for: UIControl.State())
                toggleDirection = "Lade till"
            } else {
                starButton.setImage(UIImage(named: "star_empty"), for: UIControl.State())
                toggleDirection = "Tog bort"
            }
            // Make controller create new mappings from departures and reload table
            controller?.createMappingFromFetchedDepartures()
            // Update HeadlineCell info label. Do it double to be safe.
            let newMessage = "\(toggleDirection) \(nbrChanged) busstationer på linje \(lineNumber!)"
            HeadlineCell.infoMessage = newMessage
            NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.notificationEventInfoMessage), object: nil, userInfo: [
                "message": newMessage
            ])
        }
    }
    
    // MARK: - Create cell instance
    internal class func createCellForIndexPath(
        _ section: Int,
        controller: HinnerJagTableViewController,
        tableView: UITableView,
        mappingDict: Dictionary <Int, String>,
        departuresDict: Dictionary<String, [Departure]>
    ) -> TravelHeaderCell {
        let reuseId = "TravelHeaderCell"
        var cell = tableView.dequeueReusableCell(withIdentifier: reuseId) as? TravelHeaderCell
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
                cell?.trainImageButton.setImage(UIImage(named: imageName!), for: UIControl.State())
                cell?.trainImageButton.addTarget(cell!, action: #selector(tapImageOrHeader), for: .touchUpInside)
            }
            // Setup star button
            if nil != cell!.transportType && .Bus == cell!.transportType! {
                cell?.starButton.isHidden = false
                if
                    nil != cell!.lineNumber
                    && Line.isLineActive(cell!.lineNumber!, withStopAreaTypeCode: cell!.transportType?.stopAreaTypeCode())
                {
                    cell?.starButton.setImage(UIImage(named: "star_full"), for: UIControl.State())
                } else {
                    cell?.starButton.setImage(UIImage(named: "star_empty"), for: UIControl.State())
                }
                cell?.starButton.addTarget(cell!, action: #selector(tapStar), for: .touchUpInside)
            } else {
                cell?.starButton.isHidden = true
            }
            // Set header text
            cell?.headerButton.setTitle("\(directionLabel) \(directionSuffix)", for: UIControl.State())
            cell?.headerButton.addTarget(cell!, action: #selector(tapImageOrHeader), for: .touchUpInside)
            if nil != controller.extensionContext {
                // In TodayViewController
                cell?.headerButton.tintColor = Constants.linkColor
            }
        } else {
            cell?.headerButton.setTitle("", for: UIControl.State())
        }
        return cell! as TravelHeaderCell
    }
    
}
