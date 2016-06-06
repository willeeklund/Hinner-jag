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

class MapViewController: UIViewController, MKMapViewDelegate, UITextFieldDelegate
{
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var searchTextField: UITextField!

    var chosenStation: Site?
    var chosenLineNumber: Int?
    var chosenStopAreaTypeCode: String?
    lazy var allSites = Site.getAllSites()
    let linkColor = UIColor(red: 8.0/255.0, green: 206.0/255.0, blue: 253.0/255.0, alpha: 1)
    var searchSuggestionView = UIView(frame:CGRectMake(20, 60, 150, 300))
    
    // MARK: - Lifecycle stuff
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.gaSetup()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setScreenName("MapViewController")
        // Search textfield
        self.searchTextField.delegate = self
        self.searchTextField.addTarget(self, action: #selector(textFieldValueChanged), forControlEvents: .EditingChanged)
        self.view.addSubview(searchSuggestionView)
        // Map
        self.mapView.delegate = self
        self.mapView.showsUserLocation = true
        if nil != chosenLineNumber {
            // User has chosen to present specific line number on map
            let sitesForLine = JourneyPattern.getSitesForLine(chosenLineNumber!)
            mapView.addAnnotations(sitesForLine)
            // Zoom to show all new annotations
            mapView.showAnnotations(sitesForLine, animated: false)
            mapView.region.span.latitudeDelta *= 1.2
            mapView.region.span.longitudeDelta *= 1.2
            mapView.setRegion(mapView.region, animated: true)
        } else {
            // Show all sites on map
            self.mapView.addAnnotations(allSites)
            if self.chosenStation != nil {
                self.setMapCenter(self.chosenStation!.coordinate)
            } else {
                // Default position T-centralen
                self.setMapCenter(CLLocationCoordinate2D(latitude: 59.33, longitude: 18.06))
            }
        }
    }
    
    func setMapCenter(coordinate: CLLocationCoordinate2D) {
        // Delta will set zoom level
        let delta = 0.02
        let region = MKCoordinateRegion(center: coordinate, span: MKCoordinateSpan(latitudeDelta: delta, longitudeDelta: delta))
        self.mapView.setRegion(region, animated: true)
    }
    
    @IBAction func closeMap(sender: UIButton) {
        // Reset search textfield before leaving
        self.searchTextField.text = ""
        // Dismiss view controller
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
    
    func mapView(mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        // Hide keyboard and suggested searches
        self.searchTextField.resignFirstResponder()
        searchSuggestionView.hidden = true
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
    
    // MARK: - Textfield delegate
    func textFieldDidBeginEditing(textField: UITextField) {
        searchSuggestionView.hidden = false
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        // Hide keyboard and suggested searches
        textField.resignFirstResponder()
        searchSuggestionView.hidden = true
        return true
    }
    
    func textFieldValueChanged(textField: UITextField) {
        // Show and clear suggested searches view
        searchSuggestionView.hidden = false
        searchSuggestionView.subviews.forEach({ $0.removeFromSuperview() })
        if nil == textField.text {
            return
        }
        // Trim search string
        let searchString = textField.text!.lowercaseString.stringByTrimmingCharactersInSet(
            NSCharacterSet.whitespaceAndNewlineCharacterSet()
        )
        let mapCenter = CLLocation(latitude: self.mapView.centerCoordinate.latitude, longitude: self.mapView.centerCoordinate.longitude)
        // Find sites from annotations containing search string
        let sites = mapView.annotations.filter({ (annotation) in
            if let site = annotation as? Site {
                if let title = site.title?.lowercaseString {
                    if title.containsString(searchString) {
                        return true
                    }
                }
            }
            return false
        }).sort() {
            if let first = $0 as? Site {
                if let second = $1 as? Site {
                    // Sort by distance from current map center
                    return first.distanceFromLocation(mapCenter) < second.distanceFromLocation(mapCenter)
                }
            }
            return true
        }
        
        // Show suggestions if any matching
        if 0 == sites.count {
            return
        }
        for (index, site) in sites[0...min(7, sites.count - 1)].enumerate() {
            let button = UIButton(frame: CGRectMake(0, CGFloat(index * 30), searchSuggestionView.frame.width, 30))
            button.tintColor = linkColor
            button.setTitle(site.title!, forState: .Normal)
            button.backgroundColor = UIColor(red: 255.0, green: 255.0, blue: 255.0, alpha: 0.7)
            button.setTitleColor(UIColor.blueColor(), forState: .Normal)
            button.addTarget(self, action: #selector(selectSuggestionButton), forControlEvents: .TouchUpInside)
            searchSuggestionView.addSubview(button)
            searchSuggestionView.frame.width
        }
    }
    
    func selectSuggestionButton(button: UIButton) {
        if let stationName = button.currentTitle {
            for annotation in mapView.annotations {
                if stationName == annotation.title! {
                    if let station = annotation as? Site {
                        self.trackEvent("Station", action: "search_suggestion_selected", label: "\(station.title!) (\(station.siteId))", value: 1)
                        self.chosenStation = station
                        // Update annotation view for this station and select it
                        mapView.removeAnnotation(station)
                        mapView.addAnnotation(station)
                        self.setMapCenter(self.chosenStation!.coordinate)
                        mapView.selectAnnotation(station, animated: true)
                        return
                    }
                }
            }
            print("Unable to match \(stationName)")
        }
    }
}
