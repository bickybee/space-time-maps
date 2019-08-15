//
//  ViewController.swift
//  Space-Time-Maps
//
//  Created by vicky on 2019-07-21.
//  Copyright © 2019 vicky. All rights reserved.
//

import UIKit
import GooglePlaces

class ParentViewController: UIViewController {
    
    // Child view controllers
    var placePaletteController : PlacePaletteViewController!
    var itineraryController : ItineraryViewController!
    var mapController : MapViewController!
    
    // UI outlets
    @IBOutlet weak var transportModePicker: UISegmentedControl!
    @IBOutlet weak var transportTimeLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    // Change the mode of transport for the route calculations
    // FOR NOW just passing this to itineraryController, maybe should be part of that to begin with
    @IBAction func transportModeChanged(_ sender: Any) {
        if let control = sender as? UISegmentedControl {
            let selection = control.selectedSegmentIndex
            var travelMode : TravelMode
            switch selection {
            case 0:
                travelMode = .driving
            case 1:
                travelMode = .walking
            case 2:
                travelMode = .bicycling
            case 3:
                travelMode = .transit
            default:
                travelMode = .driving
            }
            itineraryController.itinerary.travelMode = travelMode
            itineraryController.computeRoute()
        }
    }
    
    // Compare itinerary places and saved places, mark which saved places are in the itinerary
    func markItineraryPlaces() {
        let savedPlaces = placePaletteController.places
        let itineraryDestinations = itineraryController.itinerary.destinations
        savedPlaces.forEach{ $0.isInItinerary = false}
        for savedPlace in savedPlaces {
            for destination in itineraryDestinations {
                if savedPlace == destination.place {
                    savedPlace.isInItinerary = true
                }
            }
        }
        placePaletteController.places = savedPlaces
    }
    
    // Package itinerary and place data to send to map for rendering
    func updateMap() {
        guard mapController.viewIfLoaded != nil else { return }
        
        // Package relevant data
        let itinerary = itineraryController.itinerary
        let palettePlaces = placePaletteController.places
        
        let nonItineraryPlaces = palettePlaces.filter { !$0.isInItinerary }
        let itineraryPlaces = itinerary.destinations.map { $0.place }
        let itineraryLegs = itinerary.route?.legs
        
        // Send data to map
        mapController.refreshMarkup(destinationPlaces: itineraryPlaces, nonDestinationPlaces: nonItineraryPlaces, routeLegs: itineraryLegs)

    }
    
    func updateTransportTimeLabel() {
        if let duration = itineraryController.itinerary.route?.duration {
            let formatter = DateComponentsFormatter()
            formatter.allowedUnits = [.hour, .minute]
            formatter.unitsStyle = .full
            
            let formattedString = formatter.string(from: TimeInterval(duration))!
            transportTimeLabel.text = formattedString
        } else {
            transportTimeLabel.text = "no route yet"
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let placePaletteVC = segue.destination as? PlacePaletteViewController {
            
            if let itineraryController = itineraryController {
                placePaletteVC.dragDelegate = itineraryController as DragDelegate
            }
            placePaletteVC.delegate = self
            placePaletteVC.view.frame.size.width = self.view.frame.size.width / 2 // HACKY!
            placePaletteController = placePaletteVC
            
        }
        else if let itineraryVC = segue.destination as? ItineraryViewController {
            
            if let placePaletteController = placePaletteController {
                placePaletteController.dragDelegate = itineraryVC as DragDelegate
            }
            itineraryVC.delegate = self
            itineraryVC.view.frame.size.width = self.view.frame.size.width / 2 // HACKY!
            itineraryController = itineraryVC
            
        } else if let mapVC = segue.destination as? MapViewController {
            
            mapVC.delegate = self
            mapController = mapVC
            updateMap()
            
        }
    }
}

extension ParentViewController : PlacePaletteViewControllerDelegate {
    
    func placePaletteViewController(_ placePaletteViewController: PlacePaletteViewController, didUpdatePlaces places: [Place]) {
        updateMap()
    }
    
}

extension ParentViewController : ItineraryViewControllerDelegate {
    
    func itineraryViewController(_ itineraryViewController: ItineraryViewController, didUpdateItinerary: Itinerary) {
        markItineraryPlaces()
        updateTransportTimeLabel()
        updateMap()
    }
    
}

extension ParentViewController : MapViewControllerDelegate {
    
    func mapViewController(_ mapViewController: MapViewController, didUpdateBounds bounds: GMSCoordinateBounds) {
        if let placePaletteController = placePaletteController {
            placePaletteController.geographicSearchBounds = bounds
        }
    }
    
}
