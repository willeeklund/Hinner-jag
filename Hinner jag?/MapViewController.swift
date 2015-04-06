//
//  MapViewController.swift
//  Hinner jag
//
//  Created by Wilhelm Eklund on 06/04/15.
//  Copyright (c) 2015 Wilhelm Eklund. All rights reserved.
//

import Foundation
import MapKit
import HinnerJagKit

class MapViewController: UIViewController, MKMapViewDelegate
{
    @IBOutlet weak var mapView: MKMapView!
    
    var locateStation: LocateStation?
    var chosenStation: Station?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if nil != self.locateStation {
            for station in self.locateStation!.stationList {
                self.mapView.addAnnotation(station)
            }
            self.mapView.showsUserLocation = true
        }
        if self.chosenStation != nil {
            let delta = 0.02
            let region = MKCoordinateRegion(center: self.chosenStation!.coordinate, span: MKCoordinateSpan(latitudeDelta: delta, longitudeDelta: delta))
            self.mapView.setRegion(region, animated: true)
        }
    }
    
    
    @IBAction func closeMap(sender: UIButton) {
        self.presentingViewController?.dismissViewControllerAnimated(true, completion: nil)
    }
}
