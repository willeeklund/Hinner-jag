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
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    required override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }
    
    internal class func createCellForIndexPath(_ indexPath: IndexPath, tableView: UITableView, mappingDict: Dictionary <Int, String>, departuresDict: Dictionary<String, [Departure]>) -> TravelDetailsCell {
        let reuseId = "TravelDetailsCell"
        var cell: TravelDetailsCell? = tableView.dequeueReusableCell(withIdentifier: reuseId) as? TravelDetailsCell
        if nil == cell {
            cell = TravelDetailsCell()
        }
        if let mappingName = mappingDict[(indexPath as NSIndexPath).section] {
            if let depList = departuresDict[mappingName] {
                if (indexPath as NSIndexPath).row < depList.count {
                    let departure = depList[(indexPath as NSIndexPath).row]
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
