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

class TravelHeaderCell: UITableViewCell
{
    
    @IBOutlet weak var trainImage: UIImageView!
    @IBOutlet weak var headerLabel: UILabel!
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    required override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }
    
    internal class func createCellForIndexPath(section: Int, tableView: UITableView, mappingDict: Dictionary <Int, String>, departuresDict: Dictionary<String, [Departure]>) -> TravelHeaderCell {
        let reuseId = "TravelHeaderCell"
        var cell = tableView.dequeueReusableCellWithIdentifier(reuseId) as? TravelHeaderCell
        if nil == cell {
            cell = TravelHeaderCell()
        }
        if let sectionString = mappingDict[section] {
            println("sectionString = \(sectionString)")
            var imageName: String?
            var directionLabel: String = ""
            let directionSuffix = self.createDirectionSuffix(sectionString, departuresDict: departuresDict)
            
            // Metro groups
            if sectionString.rangeOfString("gröna") != nil {
                imageName = "train_green"
                directionLabel = "Grön linje"
            } else if sectionString.rangeOfString("röda") != nil {
                imageName = "train_red"
                directionLabel = "Röd linje"
            } else if sectionString.rangeOfString("blå") != nil {
                imageName = "train_blue"
                directionLabel = "Blå linje"
            }
            // Train groups
            else if sectionString.rangeOfString("TRAIN") != nil {
                // TODO: Better image of pendeltåg
                imageName = "train_purple"
                let trainRange = Range<String.Index>(start: advance(sectionString.startIndex, 8), end: advance(sectionString.startIndex, 20))
                directionLabel = sectionString.substringWithRange(trainRange)
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
        if sectionString.rangeOfString("TRAIN") != nil {
            suffixDestination = "Sthlm"
        } else {
            suffixDestination = "T-centralen"
        }
        if let depList = departuresDict[sectionString] {
            let firstDep = depList[0]
            
            if firstDep.from_central_direction != nil {
                if firstDep.from_central_direction! == firstDep.direction {
                    return "från \(suffixDestination)"
                } else {
                    return "mot \(suffixDestination)"
                }
            }
        }
        // If not departures were received or there is no 'from_central_direction'
        return ""
    }
}
