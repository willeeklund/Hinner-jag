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

fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}


open class HeadlineCell: UITableViewCell
{
    var controller: HinnerJagTableViewController?
    @IBOutlet weak var headerLabel: UILabel!
    @IBOutlet weak var infoLabel: UILabel!
    @IBOutlet weak var closestStationButton: UIButton!
    @IBOutlet weak var stationTypeSegment: UISegmentedControl!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    @IBAction func changeSelectedStation(_ sender: UIButton) {
        if nil != self.controller {
            self.controller!.changeChosenStation()
        }
    }
    
    var uniqueTransportTypes = [TransportType]()
    @IBAction func stationTypeSegmentChanged(_ sender: UISegmentedControl) {
        if nil != self.controller {
            self.controller!.setPreferredTransportType(self.uniqueTransportTypes[sender.selectedSegmentIndex])
        }
    }
    
    // MARK: - Info message
    open static var infoMessage: String?
    @objc func changeInfoLabel(_ notification: Notification) {
        // Display "message" from notification userInfo
        if nil != (notification as NSNotification).userInfo {
            if let newMessage = (notification as NSNotification).userInfo!["message"] as? String {
                HeadlineCell.infoMessage = newMessage
            } else if let useRandom = (notification as NSNotification).userInfo!["random"] as? Bool {
                if useRandom {
                    HeadlineCell.setRandomInfoMessage(true)
                }
            }
            // Show new infoMessage
            DispatchQueue.main.async(execute: {
                self.infoLabel.text = HeadlineCell.infoMessage
            })
        }
    }
    
    open class func setRandomInfoMessage(_ force: Bool = false) {
        if false == force && nil != HeadlineCell.infoMessage {
            return
        }
        let list: [String] = [
            "Tips: Lägg till fler stationer via kartan",
            "Tips: Favoritmarkera busslinjer",
            "Tips: Byt station med ett klick",
            "Tips: Fritextsök station via kartan",
            "Tips: Klicka på stationens namn",
            "Tips: Klick på linjens namn för att se alla stationer"
        ]
        let randInt = arc4random_uniform(UInt32(list.count))
        let randMsg = list[Int(randInt)]
        HeadlineCell.infoMessage = randMsg
    }
    
    // MARK: - Activity indicator
    @objc func toggleActivityIndicator(_ notification: Notification) {
        if let userInfo = (notification as NSNotification).userInfo {
            if let showActivityIndicator = userInfo["show"] as? Bool {
                DispatchQueue.main.async(execute: {
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
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }
    
    open class func createCellForTableView(
        _ tableView: UITableView,
        controller: HinnerJagTableViewController,
        closestStation: Site?,
        location: CLLocation?,
        departures: [Departure]?
    ) -> HeadlineCell? {
        let reuseId = "HeadlineCell"
        var cell = tableView.dequeueReusableCell(withIdentifier: reuseId) as? HeadlineCell
        if nil == cell {
            cell = HeadlineCell()
        }
        cell?.controller = controller
        // Text on button
        let closestStationLabel = Utils.getLabelTextForClosestStation(closestStation, ownLocation: location)
        cell?.closestStationButton.setTitle(closestStationLabel, for: UIControl.State())
        // Customize segmented control for travel types of the departures
        cell?.stationTypeSegment.isHidden = (nil == departures)
        if nil != departures {
            cell?.uniqueTransportTypes = Utils.uniqueTransportTypesFromDepartures(departures!)
            if cell?.uniqueTransportTypes.count < 2 {
                cell?.stationTypeSegment.isHidden = true
                return cell! as HeadlineCell
            }
            // Dynamic segment labels
            let namesList = cell?.uniqueTransportTypes.map() { type in Utils.transportTypeStringToName(type) }
            cell?.stationTypeSegment.removeAllSegments()
            var i = 0
            for segmentName in namesList! {
                cell?.stationTypeSegment.insertSegment(withTitle: segmentName, at: i, animated: false)
                i += 1
            }
            // Show selected segment
            let currentTransportType = Utils.currentTransportType(departures!)
            cell?.stationTypeSegment.selectedSegmentIndex = (cell?.uniqueTransportTypes.index(of: currentTransportType)!)!
        }
        // Change message of infoLabel, and listen for notification about new info
        NotificationCenter.default.addObserver(cell!, selector: #selector(changeInfoLabel), name: NSNotification.Name(rawValue: Constants.notificationEventInfoMessage), object: nil)
        // Listen for notification to toggle activity indicator
        NotificationCenter.default.addObserver(cell!, selector: #selector(toggleActivityIndicator), name: NSNotification.Name(rawValue: Constants.notificationEventActivityIndicator), object: nil)
        HeadlineCell.setRandomInfoMessage()
        cell?.infoLabel.text = HeadlineCell.infoMessage
        
        return cell! as HeadlineCell
    }
}
