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
    @IBOutlet weak var headerLabel: UILabel!
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    required public override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }
    
    internal class func createCellForIndexPath(section: Int, tableView: UITableView, mappingDict: Dictionary <Int, String>, departuresDict: Dictionary<String, [Departure]>) -> TravelHeaderCell {
        let reuseId = "TravelHeaderCell"
        var cell = tableView.dequeueReusableCellWithIdentifier(reuseId) as? TravelHeaderCell
        if nil == cell {
            cell = TravelHeaderCell()
        }
        if let sectionString = mappingDict[section] {
            var imageName: String?
            var directionLabel: String = ""
            let directionSuffix = self.createDirectionSuffix(sectionString, departuresDict: departuresDict)
            
            // Metro groups
            if sectionString.rangeOfString("METRO") != nil {
                if sectionString.rangeOfString("gröna") != nil {
                    imageName = "train_green"
                    directionLabel = "Grön linje"
                } else if sectionString.rangeOfString("röda") != nil {
                    imageName = "train_red"
                    directionLabel = "Röd linje"
                } else if sectionString.rangeOfString("blå") != nil {
                    imageName = "train_blue"
                    directionLabel = "Blå linje"
                } else {
                    print("Can not decide direction label for '\(sectionString)'")
                    directionLabel = "Tunnelbana"
                }
            }
            // Train groups
            else if sectionString.rangeOfString("TRAIN") != nil {
                imageName = "train_purple"
                directionLabel = ""
            }
            // Bus groups
            else if sectionString.rangeOfString("BUS") != nil {
                imageName = "bus"
                directionLabel = "Buss"
                if let depList = departuresDict[sectionString] {
                    let firstDep = depList[0]
                    directionLabel = "Buss \(firstDep.lineNumber)"
                }
            }
            // Bus groups
            else if sectionString.rangeOfString("TRAM") != nil {
                imageName = "train_orange"
                directionLabel = "Tvärbana"
            }
            
            // Set image
            if nil != imageName {
                cell?.trainImage.image = UIImage(named: imageName!)
            }
            
            cell?.headerLabel?.text = "\(directionLabel) \(directionSuffix)"
        } else {
            cell?.headerLabel?.text = ""
        }
        return cell! as TravelHeaderCell
    }
    
    internal class func createDirectionSuffix(sectionString: String, departuresDict: Dictionary<String, [Departure]>) -> String {
        let suffixDestination: String
        if sectionString.rangeOfString("METRO") != nil {
            suffixDestination = "T-centralen"
        } else if sectionString.rangeOfString("TRAIN") != nil {
            suffixDestination = "Sthlm"
        } else if
            sectionString.rangeOfString("BUS") != nil
            || sectionString.rangeOfString("TRAM") != nil
        {
            // No direction suffix for buses or trams
            return ""
        } else {
            suffixDestination = ""
        }
        if let depList = departuresDict[sectionString] {
            let firstDep = depList[0]
            
            if firstDep.from_central_direction != nil {
                var truthValue = firstDep.from_central_direction! == firstDep.direction
                
                // If both metros and trains station, reverse direction suffix for train departures
                let isBothMetroAndTrains = firstDep.stationType != nil && firstDep.stationType! == .MetroAndTrain
                if isBothMetroAndTrains && "TRAIN" == firstDep.transportMode {
                    truthValue = !truthValue
                }
                
                if truthValue {
                    return "från \(suffixDestination)"
                } else {
                    return "mot \(suffixDestination)"
                }
            } else {
                // This probably means we are at T-centralen
                if "TRAIN" == firstDep.transportMode {
                    return firstDep.lineName
                }
            }
        }
        // If not departures were received or there is no 'from_central_direction'
        return ""
    }
}
