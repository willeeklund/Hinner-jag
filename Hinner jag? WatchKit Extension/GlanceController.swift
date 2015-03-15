//
//  GlanceController.swift
//  Hinner jag? WatchKit Extension
//
//  Created by Wilhelm Eklund on 14/03/15.
//  Copyright (c) 2015 Wilhelm Eklund. All rights reserved.
//

import WatchKit
import Foundation
import HinnerJagKit

class GlanceController: InterfaceController {
    // Build up the text of labels
    func getGroupLabels(group: Int) -> (String, String) {
        var headerText = "Mot bl.a. "
        var detailsText = ""
        if let groupList = self.departuresDict[group] {
            var counter = 0
            for departure in groupList {
                if 0 == counter {
                    headerText += "\(departure.destination)"
                } else {
                    detailsText += ", "
                }
                detailsText += "\(departure.remainingTime)"
                counter++
            }
        }
        return (headerText, detailsText)
    }
    
    // MARK: - Override behaviour of what to show in the table
    override func calculateTypesOfRows() -> ([String], Int) {
        return (["header", "details", "header", "details"], 2)
    }

    override func fillTableWithContent(typesOfRows: [String], startIndexGroup2: Int) {
        var (header1, details1) = self.getGroupLabels(1)
        var (header2, details2) = self.getGroupLabels(2)
        
        // Set value on the labels
        if let headerRow = self.tableView.rowControllerAtIndex(0) as TravelHeaderRow? {
            headerRow.headerLabel.setText(header1)
        }
        if let headerRow = self.tableView.rowControllerAtIndex(2) as TravelHeaderRow? {
            headerRow.headerLabel.setText(header2)
        }
        if let detailsRow = self.tableView.rowControllerAtIndex(1) as TravelDetailsRow? {
            detailsRow.remainingTimeLabel.setText(details1)
            detailsRow.destinationLabel.setText("")
        }
        if let detailsRow = self.tableView.rowControllerAtIndex(3) as TravelDetailsRow? {
            detailsRow.remainingTimeLabel.setText(details2)
            detailsRow.destinationLabel.setText("")
        }
    }
}