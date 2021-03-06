//
//  GlanceController.swift
//  HinnerJagWatchOS2 Extension
//
//  Created by Wilhelm Eklund on 27/08/15.
//  Copyright © 2015 Wilhelm Eklund. All rights reserved.
//

import WatchKit
import Foundation
import HinnerJagWatchKit

class GlanceController: InterfaceController {
    // Build up the text of labels
    func getGroupLabels(group: Int) -> (String, String) {
        var headerText = ""
        var detailsText = ""
        if let groupMapName = self.mappingDict[group] {
            if let groupList = self.departuresDict[groupMapName] {
                var counter = 0
                for departure in groupList {
                    if 0 == counter {
                        if departure.fromCentralDirection != nil {
                            if departure.fromCentralDirection! == departure.direction {
                                headerText = "Från T-centralen"
                            } else {
                                headerText = "Mot T-centralen"
                            }
                        } else {
                            headerText = "Mot bl.a. \(departure.destination)"
                        }
                    } else {
                        detailsText += ", "
                    }
                    detailsText += "\(departure.remainingTime)"
                    counter += 1
                }
            }
        } else {
            print("getGroupLabels(\(group)) was not found. This is mappingDict: \(mappingDict)")
        }
        return (headerText, detailsText)
    }
    
    // MARK: - Google Analytics
    override func setGAScreenName() {
        self.setScreenName("WatchAppGlanceController")
    }
    
    
    // MARK: - Override behaviour of what to show in the table
    override func calculateTypesOfRows() {
        self.typesOfRows = ["header", "details", "header", "details"]
    }
    
    override func fillTableWithContent() {
        let (header1, details1) = self.getGroupLabels(0)
        let (header2, details2) = self.getGroupLabels(1)
        
        // Set value on the labels
        if let headerRow = self.tableView.rowControllerAtIndex(0) as! TravelHeaderRow? {
            headerRow.headerLabel.setText(header1)
        }
        if let headerRow = self.tableView.rowControllerAtIndex(2) as! TravelHeaderRow? {
            headerRow.headerLabel.setText(header2)
        }
        if let detailsRow = self.tableView.rowControllerAtIndex(1) as! TravelDetailsRow? {
            detailsRow.remainingTimeLabel.setText(details1)
            detailsRow.destinationLabel.setText("")
        }
        if let detailsRow = self.tableView.rowControllerAtIndex(3) as! TravelDetailsRow? {
            detailsRow.remainingTimeLabel.setText(details2)
            detailsRow.destinationLabel.setText("")
        }
    }
}