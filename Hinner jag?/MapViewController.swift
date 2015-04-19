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
        self.setScreeName("MapViewController")
        self.mapView.delegate = self
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
    
    // MARK: - Map annotations
    func mapView(mapView: MKMapView!, viewForAnnotation annotation: MKAnnotation!) -> MKAnnotationView! {
        // Use default view for the users location
        if annotation is MKUserLocation {
            return nil
        }
        let reuseId = "MapViewController"
        var view: MKAnnotationView? = self.mapView?.dequeueReusableAnnotationViewWithIdentifier(reuseId)
        if nil == view {
            view = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            view?.canShowCallout = true
            // TODO: Set left accessory view to show which lines exist at this station
            // var imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 46, height: 46))
            // imageView.image = UIImage(named: "train_green")
            // view?.leftCalloutAccessoryView = imageView
            var btn = UIButton()
            btn.setBackgroundImage(UIImage(named: "right_arrow"), forState: .Normal)
            btn.sizeToFit()
            view?.rightCalloutAccessoryView = btn
        }
        view?.annotation = annotation
        return view
    }
    
    func mapView(mapView: MKMapView!, annotationView view: MKAnnotationView!, calloutAccessoryControlTapped control: UIControl!) {
        println("calloutAccessoryControlTapped()")
        if self.presentingViewController is MainAppViewController && view.annotation is Station {
            println("Set new selected station")
            let mainAppVC = self.presentingViewController as! MainAppViewController
            mainAppVC.searchFromNewClosestStation(view.annotation as! Station)
            mainAppVC.dismissViewControllerAnimated(true, completion: nil)
        }
    }

}
