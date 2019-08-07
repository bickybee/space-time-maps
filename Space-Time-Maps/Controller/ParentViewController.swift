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
    
    var dataManager : DataManager!
    
    var placePaletteController : PlacePaletteViewController!
    var itineraryController : ItineraryViewController!
    var mapController : MapViewController!
    
    var placesBeforeDragging: [Place]?
    
    @IBOutlet weak var transportModePicker: UISegmentedControl!
    @IBOutlet weak var transportTimeLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    // Change the mode of transport for the route calculations
    // FOR NOW just passing this to itineraryController, maybe should be part of that to begin with
    @IBAction func transportModeChanged(_ sender: Any) {
        itineraryController.transportModeChanged(sender)
    }
    
    // Compare itinerary places and saved places, mark which saved places are in the itinerary
    func markItineraryPlaces() {
        let savedPlaces = placePaletteController.places
        let itineraryPlaces = itineraryController.itinerary.places
        savedPlaces.forEach{ $0.isInItinerary = false}
        for savedPlace in savedPlaces {
            for itineraryPlace in itineraryPlaces {
                if savedPlace == itineraryPlace {
                    savedPlace.isInItinerary = true
                }
            }
        }
        placePaletteController.places = savedPlaces
    }
    
    // Package itinerary and place data to send to map for rendering
    func updateMap() {
        let itinerary = itineraryController.itinerary
        let palettePlaces = placePaletteController.places
        // Determine place colors based on data
        // Set up to send to map
        var placeVisuals = [PlaceVisual]()
        var routeVisuals = [RouteVisual]()
        let nonItineraryPlaces = palettePlaces.filter { !$0.isInItinerary }
        if nonItineraryPlaces.count > 0 {
            let nonItineraryVisuals = nonItineraryPlaces.map { PlaceVisual(place: $0, color: UIColor.gray) }
            placeVisuals.append(contentsOf: nonItineraryVisuals)
        }
        let numPlaces = itinerary.places.count
        let places = itinerary.places
        if numPlaces >= 1 {
            placeVisuals.append(PlaceVisual(place: places.first!, color: UIColor.green))
        }
        if numPlaces >= 2 {
            placeVisuals.append(PlaceVisual(place: places.last!, color: UIColor.red))
        }
        if numPlaces >= 3 {
            let enroutePlaces = Array(places[1 ... places.count - 2])
            let enrouteVisuals = enroutePlaces.map { PlaceVisual(place: $0, color: UIColor.yellow) }
            placeVisuals.append(contentsOf: enrouteVisuals)
        }
        if let routePolyline = itinerary.route?.polyline {
            routeVisuals.append( RouteVisual(route: routePolyline, color: UIColor.blue) )
        }
        // Send and call a refresh!
        mapController.setPlaces(placeVisuals)
        mapController.setRoutes(routeVisuals)
        // Only actually refresh map if the view has loaded
        if mapController.viewIfLoaded != nil {
            mapController.refreshMarkup()
        }
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
            placePaletteVC.collectionView.frame.size.width = self.view.frame.size.width / 2 // HACKY?
            placePaletteVC.delegate = self
            placePaletteController = placePaletteVC
        }
        else if let itineraryVC = segue.destination as? ItineraryViewController {
            itineraryVC.collectionView.frame.size.width = self.view.frame.size.width / 2 // HACKY?
            itineraryVC.delegate = self
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
    
    // TODO: pass in the dragging view itself, test if (touch - view-dimensions) intersects the itineraryview (not just the touch)
    func placePaletteViewController(_ placePaletteViewController: PlacePaletteViewController, didPress gesture: UIGestureRecognizer, onPlace place: Place) {
        switch gesture.state {
        case .began:
            placesBeforeDragging = itineraryController!.itinerary.places
        case .ended,
             .changed:
            let location = gesture.location(in: view)
            if let droppedInItinerary = itineraryController?.collectionView.bounds.contains(location) {
                if droppedInItinerary {
                    let itineraryLocation = gesture.location(in: itineraryController?.collectionView!)
                    if let index = itineraryController?.collectionView.indexPathForItem(at: itineraryLocation)?.item {
                        if placesBeforeDragging!.indices.contains(index) && !(placesBeforeDragging![index] == place) {
                            print("inserting")
                            var newPlaces = placesBeforeDragging!
                            newPlaces.insert(place, at: index)
                            itineraryController?.itinerary.places = newPlaces
                            itineraryController?.updateItinerary()
                        }
                    } else {
                        if !(placesBeforeDragging!.last == place) {
                            print("appending")
                            var newPlaces = placesBeforeDragging!
                            newPlaces.append(place)
                            itineraryController?.itinerary.places = newPlaces
                            itineraryController?.updateItinerary()
                        }
                    }
                }
            }
        default:
            break
        }
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
