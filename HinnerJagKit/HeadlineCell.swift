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

class HeadlineCell: UITableViewCell
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
    
    @IBAction func stationTypeSegmentChanged(sender: UISegmentedControl) {
        if nil != self.controller {
            self.controller!.setPreferedTravelType(StationType(rawValue: sender.selectedSegmentIndex)!)
        }
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }
    
    internal class func createCellForTableView(
        tableView: UITableView,
        controller: HinnerJagTableViewController,
        closestStation: Station?,
        location: CLLocation?,
        shouldShowStationTypeSegment: Bool,
        shownStationType: StationType
    ) -> HeadlineCell? {
        let reuseId = "HeadlineCell"
        var cell = tableView.dequeueReusableCellWithIdentifier(reuseId) as? HeadlineCell
        if nil == cell {
            cell = HeadlineCell()
        }
        // Text on button
        let closestStationLabel = Utils.getLabelTextForClosestStation(closestStation, ownLocation: location)
        cell?.closestStationButton.setTitle(closestStationLabel, forState: .Normal)
        // Segment control for travel type
        cell?.stationTypeSegment.hidden = !shouldShowStationTypeSegment
        cell?.stationTypeSegment.selectedSegmentIndex = shownStationType.rawValue
    
        cell?.controller = controller
        return cell! as HeadlineCell
    }
}