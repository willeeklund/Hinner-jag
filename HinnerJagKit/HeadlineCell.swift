//
//  HeadlineCell.swift
//  Hinner jag
//
//  Created by Wilhelm Eklund on 29/03/15.
//  Copyright (c) 2015 Wilhelm Eklund. All rights reserved.
//

import Foundation
import UIKit
import MapKit
import HinnerJagKit

public class HeadlineCell: UITableViewCell
{
    var controller: HinnerJagTableViewController?
    @IBOutlet weak var headerLabel: UILabel!
    @IBOutlet weak var closestStationButton: UIButton!
    @IBOutlet weak var stationTypeSegment: UISegmentedControl!
    
    @IBAction func changeSelectedStation(sender: UIButton) {
        if nil != self.controller {
            self.controller!.changeChosenStation()
        }
    }
    
    var uniqueTransportTypes = [TransportType]()
    @IBAction func stationTypeSegmentChanged(sender: UISegmentedControl) {
        if nil != self.controller {
            self.controller!.setPreferredTransportType(self.uniqueTransportTypes[sender.selectedSegmentIndex])
        }
    }
    
    // MARK: - Init
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }
    
    public class func createCellForTableView(
        tableView: UITableView,
        controller: HinnerJagTableViewController,
        closestStation: Station?,
        location: CLLocation?,
        departures: [Departure]?
    ) -> HeadlineCell? {
        let reuseId = "HeadlineCell"
        var cell = tableView.dequeueReusableCellWithIdentifier(reuseId) as? HeadlineCell
        if nil == cell {
            cell = HeadlineCell()
        }
        cell?.controller = controller
        // Text on button
        let closestStationLabel = Utils.getLabelTextForClosestStation(closestStation, ownLocation: location)
        cell?.closestStationButton.setTitle(closestStationLabel, forState: .Normal)
        // Customize segmented control for travel types of the departures
        cell?.stationTypeSegment.hidden = (nil == departures)
        if nil != departures {
            cell?.uniqueTransportTypes = Utils.uniqueTransportTypesFromDepartures(departures!)
            if cell?.uniqueTransportTypes.count < 2 {
                cell?.stationTypeSegment.hidden = true
                return cell! as HeadlineCell
            }
            // Dynamic segment labels
            let namesList = cell?.uniqueTransportTypes.map() { type in Utils.transportTypeStringToName(type) }
            cell?.stationTypeSegment.removeAllSegments()
            var i = 0
            for segmentName in namesList! {
                cell?.stationTypeSegment.insertSegmentWithTitle(segmentName, atIndex: i++, animated: false)
            }
            // Show selected segment
            let currentTransportType = Utils.currentTransportType(departures!)
            cell?.stationTypeSegment.selectedSegmentIndex = (cell?.uniqueTransportTypes.indexOf(currentTransportType)!)!
        }
        return cell! as HeadlineCell
    }
}