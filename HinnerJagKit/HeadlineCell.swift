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
    @IBOutlet weak var infoLabel: UILabel!
    @IBOutlet weak var closestStationButton: UIButton!
    @IBOutlet weak var stationTypeSegment: UISegmentedControl!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
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
    
    // MARK: - Info message
    public static var infoMessage: String?
    func changeInfoLabel(notification: NSNotification) {
        // Display "message" from notification userInfo
        if nil != notification.userInfo {
            if let newMessage = notification.userInfo!["message"] as? String {
                HeadlineCell.infoMessage = newMessage
            } else if let useRandom = notification.userInfo!["random"] as? Bool {
                if useRandom {
                    HeadlineCell.setRandomInfoMessage(true)
                }
            }
            // Show new infoMessage
            dispatch_async(dispatch_get_main_queue(), {
                self.infoLabel.text = HeadlineCell.infoMessage
            })
        }
    }
    
    public class func setRandomInfoMessage(force: Bool = false) {
        if false == force && nil != HeadlineCell.infoMessage {
            return
        }
        let list: [String] = [
            "Tips: Lägg till fler stationer via kartan",
            "Tips: Favoritmarkera busslinjer",
            "Tips: Byt station med ett klick",
            "Gillar du appen? Berätta för dina vänner :)"
        ]
        let randInt = arc4random_uniform(UInt32(list.count))
        let randMsg = list[Int(randInt)]
        HeadlineCell.infoMessage = randMsg
    }
    
    // MARK: - Activity indicator
    func toggleActivityIndicator(notification: NSNotification) {
        if let userInfo = notification.userInfo {
            if let showActivityIndicator = userInfo["show"] as? Bool {
                dispatch_async(dispatch_get_main_queue(), {
                    if showActivityIndicator {
                        self.activityIndicator.startAnimating()
                    } else {
                        self.activityIndicator.stopAnimating()
                    }
                })
            }
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
        closestStation: Site?,
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
                cell?.stationTypeSegment.insertSegmentWithTitle(segmentName, atIndex: i, animated: false)
                i += 1
            }
            // Show selected segment
            let currentTransportType = Utils.currentTransportType(departures!)
            cell?.stationTypeSegment.selectedSegmentIndex = (cell?.uniqueTransportTypes.indexOf(currentTransportType)!)!
        }
        // Change message of infoLabel, and listen for notification about new info
        NSNotificationCenter.defaultCenter().addObserver(cell!, selector: #selector(changeInfoLabel), name: Constants.notificationEventInfoMessage, object: nil)
        // Listen for notification to toggle activity indicator
        NSNotificationCenter.defaultCenter().addObserver(cell!, selector: #selector(toggleActivityIndicator), name: Constants.notificationEventActivityIndicator, object: nil)
        HeadlineCell.setRandomInfoMessage()
        cell?.infoLabel.text = HeadlineCell.infoMessage
        
        return cell! as HeadlineCell
    }
}