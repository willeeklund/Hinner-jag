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
    @IBOutlet weak var showLineLabel: UILabel!
    
    var chosenStation: Site?
    var chosenLineNumber: Int?
    var chosenStopAreaTypeCode: String?
    var sitesForLine = Set<Site>()
    var listOfLines = [Int]()
    lazy var allSites = Site.getAllSites()
    let linkColor = UIColor(red: 8.0/255.0, green: 206.0/255.0, blue: 253.0/255.0, alpha: 1)
    var searchSuggestionView = UIView(frame: CGRectMake(20, 60, 150, 300))

    
    // MARK: - Lifecycle stuff
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        gaSetup()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setScreenName("MapViewController")
        // Search textfield
        searchTextField.delegate = self
        searchTextField.addTarget(self, action: #selector(textFieldValueChanged), forControlEvents: .EditingChanged)
        view.addSubview(searchSuggestionView)
        // Map
        mapView.delegate = self
        mapView.showsUserLocation = true
        if nil != chosenLineNumber {
            let prefix = "Visar stationer längs"
            let labelText: String
            // User has chosen to present specific line number on map
            if
                nil != chosenStopAreaTypeCode &&
                [TransportType.Metro, .Train, .Tram].map({ $0.stopAreaTypeCode() }).contains(chosenStopAreaTypeCode!)
            {
                // If metro line, also add the other routes of same color
                switch chosenLineNumber! {
                // Blue metro line
                case 10, 11:
                    listOfLines = [10, 11]
                    labelText = "\(prefix) blå linjen"
                // Red metro line
                case 13, 14:
                    listOfLines = [13, 14]
                    labelText = "\(prefix) röda linjen"
                // Green metro line
                case 17, 18, 19:
                    listOfLines = [17, 18, 19]
                    labelText = "\(prefix) gröna linjen"
                // Trains
                case 33, 34, 35, 36, 37, 38:
                    listOfLines = [33, 34, 35, 36, 37, 38]
                    labelText = "\(prefix) pendeltåg"
                default:
                    listOfLines = [chosenLineNumber!]
                    // Tram
                    if TransportType.Tram.stopAreaTypeCode() == chosenStopAreaTypeCode! {
                        labelText = "\(prefix) tvärbana \(chosenLineNumber!)"
                    } else {
                        labelText = "\(prefix) linje \(chosenLineNumber!)"
                    }
                }
            } else {
                listOfLines = [chosenLineNumber!]
                labelText = "\(prefix) linje \(chosenLineNumber!)"
            }
            for lineNumber in listOfLines {
                addSitesFromLineNumber(lineNumber)
            }
            // Display showLineLabel
            showLineLabel.text = labelText
            showLineLabel.hidden = false
            showLineLabel.adjustsFontSizeToFitWidth = true
            showLineLabel.layer.borderColor = linkColor.CGColor
            showLineLabel.layer.borderWidth = 2.0
            // Add sites to map
            mapView.addAnnotations(Array(sitesForLine))
            // Zoom to show all new annotations
            mapView.showAnnotations(mapView.annotations, animated: false)
            mapView.region.span.latitudeDelta *= 1.3
            mapView.region.span.longitudeDelta *= 1.3
            mapView.setRegion(mapView.region, animated: true)
            var desc = "Show line \(chosenLineNumber!)"
            if nil != chosenStopAreaTypeCode {
                desc += " (\(chosenStopAreaTypeCode!))"
            }
            trackEvent("MapViewController", action: "Show", label: desc, value: nil)
        } else {
            // Show all sites on map
            mapView.addAnnotations(allSites)
            if chosenStation != nil {
                setMapCenter(chosenStation!.coordinate)
            } else {
                // Default position T-centralen
                setMapCenter(CLLocationCoordinate2D(latitude: 59.33, longitude: 18.06))
            }
            showLineLabel.hidden = true
            trackEvent("MapViewController", action: "Show", label: "Show all sites", value: nil)
        }
    }
    
    func addSitesFromLineNumber(number: Int) {
        for site in JourneyPattern.getSitesForLine(number, withStopAreaTypeCode: chosenStopAreaTypeCode) {
            sitesForLine.insert(site)
        }
    }
    
    func setMapCenter(coordinate: CLLocationCoordinate2D) {
        // Delta will set zoom level
        let delta = 0.02
        let region = MKCoordinateRegion(center: coordinate, span: MKCoordinateSpan(latitudeDelta: delta, longitudeDelta: delta))
        mapView.setRegion(region, animated: true)
    }
    
    @IBAction func closeMap(sender: UIButton) {
        // Reset search textfield before leaving
        searchTextField.text = ""
        // Dismiss view controller
        presentingViewController?.dismissViewControllerAnimated(true, completion: nil)
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
                        nil != chosenStation
                        && station == chosenStation!
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
                        nil != chosenStation
                            && station == chosenStation!
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
        if presentingViewController is MainAppViewController && view.annotation is Site {
            let station = view.annotation as! Site
            print("Station tapped. \(station.siteId)")
            // Change active status for this station
            station.toggleActive()
            trackEvent("Station", action: "toggle_active_from_map", label: "\(station.title!) (\(station.siteId))", value: 1)
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
        view.addGestureRecognizer(tapRecognizer)
    }
    func mapView(mapView: MKMapView, didDeselectAnnotationView view: MKAnnotationView) {
        view.removeGestureRecognizer(tapRecognizer)
    }
    
    func mapView(mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        // Hide keyboard and suggested searches
        searchTextField.resignFirstResponder()
        searchSuggestionView.hidden = true
        showLineLabel.hidden = nil == chosenLineNumber
    }
    
    func tappedAnnotation(recognizer: UIPanGestureRecognizer) {
        if let view = recognizer.view as? MKAnnotationView {
            if presentingViewController is MainAppViewController && view.annotation is Site {
                let station = view.annotation as! Site
                let mainAppVC = presentingViewController as! MainAppViewController
                mainAppVC.searchFromNewClosestStation(station)
                mainAppVC.dismissViewControllerAnimated(true, completion: nil)
                trackEvent("Station", action: "change_from_map", label: "\(station.title!) (\(station.siteId))", value: 1)
            }
        }
    }
    
    // MARK: - Textfield delegate
    func textFieldDidBeginEditing(textField: UITextField) {
        searchSuggestionView.hidden = false
        // Hide showLineLabel if no chosen line or text is entered
        let hasNoLineNumber = nil == chosenLineNumber
        let hasText = nil != textField.text && textField.text!.characters.count > 0
        showLineLabel.hidden = hasNoLineNumber || hasText
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        // Hide keyboard and suggested searches
        textField.resignFirstResponder()
        searchSuggestionView.hidden = true
        showLineLabel.hidden = nil == chosenLineNumber
        return true
    }
    
    func textFieldValueChanged(textField: UITextField) {
        // Show and clear suggested searches view
        searchSuggestionView.hidden = false
        searchSuggestionView.subviews.forEach({ $0.removeFromSuperview() })
        showLineLabel.hidden = true
        if nil == textField.text {
            return
        }
        // Trim search string
        let searchString = textField.text!.lowercaseString.stringByTrimmingCharactersInSet(
            NSCharacterSet.whitespaceAndNewlineCharacterSet()
        )
        let mapCenter = CLLocation(latitude: mapView.centerCoordinate.latitude, longitude: mapView.centerCoordinate.longitude)
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
                        trackEvent("Station", action: "search_suggestion_selected", label: "\(station.title!) (\(station.siteId))", value: 1)
                        chosenStation = station
                        // Update annotation view for this station and select it
                        mapView.removeAnnotation(station)
                        mapView.addAnnotation(station)
                        setMapCenter(chosenStation!.coordinate)
                        mapView.selectAnnotation(station, animated: true)
                        return
                    }
                }
            }
            print("Unable to match \(stationName)")
        }
    }
}
