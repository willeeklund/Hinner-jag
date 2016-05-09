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
    
    var chosenStation: Site?
    
    // MARK: - Lifecycle stuff
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.gaSetup()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setScreenName("MapViewController")
        self.mapView.delegate = self
        self.mapView.addAnnotations(Site.getAllSites())
        self.mapView.showsUserLocation = true
        var usedCoordinate = CLLocationCoordinate2D(latitude: 59.33, longitude: 18.06)
        if self.chosenStation != nil {
            // Delta will set zoom level
            usedCoordinate = self.chosenStation!.coordinate
        }
        let delta = 0.02
        let region = MKCoordinateRegion(center: usedCoordinate, span: MKCoordinateSpan(latitudeDelta: delta, longitudeDelta: delta))
        
        self.mapView.setRegion(region, animated: true)
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
        let reuseId = "PinAnnotation"
        var view = self.mapView?.dequeueReusableAnnotationViewWithIdentifier(reuseId) as? MKPinAnnotationView
        if nil == view {
            view = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
        }
        view?.canShowCallout = true
        // Set pin color and correct image
        if let station = annotation as? Site {
            // Set right accessory view to show if station is active
            let accessoryButton = UIButton(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
            view?.rightCalloutAccessoryView = accessoryButton
            // Set pin color depending on if the station is active
            if station.isActive {
                if #available(iOS 9.0, *) {
                    if
                        nil != self.chosenStation
                        && station == self.chosenStation!
                    {
                        view?.pinTintColor = UIColor.blueColor()
                    } else {
                        view?.pinTintColor = UIColor.greenColor()
                    }
                } else {
                    view?.pinColor = .Green
                }
                accessoryButton.setImage(UIImage(named: "star_full"), forState: .Normal)
            } else {
                if #available(iOS 9.0, *) {
                    if
                        nil != self.chosenStation
                            && station == self.chosenStation!
                    {
                        view?.pinTintColor = UIColor.purpleColor()
                    } else if station.isChangedManual {
                        view?.pinTintColor = UIColor.blackColor()
                    } else {
                        view?.pinTintColor = UIColor.redColor()
                    }
                } else {
                    view?.pinColor = .Red
                }
                accessoryButton.setImage(UIImage(named: "star_empty"), forState: .Normal)
            }
        }
        return view
    }
    
    // MARK: - Call annotation callout to toggle if station is active
    func mapView(mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        if self.presentingViewController is MainAppViewController && view.annotation is Site {
            let station = view.annotation as! Site
            print("Station tapped. \(station.siteId)")
            // Change active status for this station
            station.toggleActive()
            self.trackEvent("Station", action: "toggle_active_from_map", label: "\(station.title!) (\(station.siteId))", value: 1)
            // Update annotation view for this station
            mapView.removeAnnotation(station)
            mapView.addAnnotation(station)
        }
    }
    
    // MARK: - Tapping annotation will select that station
    lazy var tapRecognizer: UITapGestureRecognizer = {
        return UITapGestureRecognizer(target: self, action: #selector(MapViewController.tappedAnnotation(_:)))
    }()
    
    func mapView(mapView: MKMapView, didSelectAnnotationView view: MKAnnotationView) {
        view.addGestureRecognizer(self.tapRecognizer)
    }
    func mapView(mapView: MKMapView, didDeselectAnnotationView view: MKAnnotationView) {
        view.removeGestureRecognizer(self.tapRecognizer)
    }
    
    func tappedAnnotation(recognizer: UIPanGestureRecognizer) {
        if let view = recognizer.view as? MKAnnotationView {
            if self.presentingViewController is MainAppViewController && view.annotation is Site {
                let station = view.annotation as! Site
                let mainAppVC = self.presentingViewController as! MainAppViewController
                mainAppVC.searchFromNewClosestStation(station)
                mainAppVC.dismissViewControllerAnimated(true, completion: nil)
                self.trackEvent("Station", action: "change_from_map", label: "\(station.title!) (\(station.siteId))", value: 1)
            }
        }
    }
    
}
