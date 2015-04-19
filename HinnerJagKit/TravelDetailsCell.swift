//
//  TravelDetailsCell.swift
//  Hinner jag?
//
//  Created by Wilhelm Eklund on 09/03/15.
//  Copyright (c) 2015 Wilhelm Eklund. All rights reserved.
//

import Foundation
import UIKit
import HinnerJagKit

class TravelDetailsCell: UITableViewCell
{
    
    @IBOutlet weak var remainingTimeLabel: UILabel!
    @IBOutlet weak var destinationLabel: UILabel!
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    required override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }
    
    internal class func createCellForIndexPath(indexPath: NSIndexPath, tableView: UITableView, mappingDict: Dictionary <Int, String>, departuresDict: Dictionary<String, [Departure]>) -> TravelDetailsCell {
        let reuseId = "TravelDetailsCell"
        var cell: TravelDetailsCell? = tableView.dequeueReusableCellWithIdentifier(reuseId) as? TravelDetailsCell
        if nil == cell {
            cell = TravelDetailsCell()
        }
        if let mappingName = mappingDict[indexPath.section] {
            if let depList = departuresDict[mappingName] {
                if indexPath.row < depList.count {
                    let departure = depList[indexPath.row]
                    cell?.remainingTimeLabel?.text = departure.remainingTime
                    cell?.destinationLabel?.text = departure.destination
                }
            }
        } else {
            cell?.remainingTimeLabel?.text = "..."
            cell?.destinationLabel?.text = "..."
        }
        
        return cell! as TravelDetailsCell
    }
}
