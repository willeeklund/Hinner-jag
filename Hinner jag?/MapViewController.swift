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
    
    // MARK: - Lifecycle stuff
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.gaSetup()
    }
    
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
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        // Use default view for the users location
        if annotation is MKUserLocation {
            return nil
        }
        let reuseId = "MapViewController"
        var view = self.mapView?.dequeueReusableAnnotationViewWithIdentifier(reuseId) as? MKPinAnnotationView
        if nil == view {
            view = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            view?.canShowCallout = true
            // TODO: Change to different color depending on metro or train
            if let station = annotation as? Station {
                if station.stationType == .Train {
                    view?.pinColor = .Purple
                }
                if station == self.chosenStation {
                    view?.pinColor = .Green
                }
            }

            // TODO: Set left accessory view to show which lines exist at this station
            // var imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 46, height: 46))
            // imageView.image = UIImage(named: "train_green")
            // view?.leftCalloutAccessoryView = imageView
        } else {
            view?.annotation = annotation
        }
        return view
    }
    
    // MARK: - Tapping annotation will select that station
    lazy var tapRecognizer: UITapGestureRecognizer = {
        return UITapGestureRecognizer(target: self, action: "tappedAnnotation:")
    }()
    
    func mapView(mapView: MKMapView, didSelectAnnotationView view: MKAnnotationView) {
        view.addGestureRecognizer(self.tapRecognizer)
    }
    func mapView(mapView: MKMapView, didDeselectAnnotationView view: MKAnnotationView) {
        view.removeGestureRecognizer(self.tapRecognizer)
    }
    
    func tappedAnnotation(recognizer: UIPanGestureRecognizer) {
        if let view = recognizer.view as? MKAnnotationView {
            if self.presentingViewController is MainAppViewController && view.annotation is Station {
                let station = view.annotation as! Station
                let mainAppVC = self.presentingViewController as! MainAppViewController
                mainAppVC.searchFromNewClosestStation(station)
                mainAppVC.dismissViewControllerAnimated(true, completion: nil)
                self.trackEvent("Station", action: "change_from_map", label: "\(station.title!) (\(station.id))", value: 1)
            }
        }
    }

}
