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
    
    var savedPlaces : PlaceManager!
    var itineraryManager : ItineraryManager!
    
    var placePaletteViewController : PlacePaletteViewController?
    var itineraryViewController : ItineraryViewController?
    var mapViewController : MapViewController?
    
    @IBOutlet weak var transportModePicker: UISegmentedControl!
    @IBOutlet weak var transportTimeLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Observe itinerary updates
        NotificationCenter.default.addObserver(self, selector: #selector(onDidUpdateItinerary), name: .didUpdateItinerary, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onDidAddSavedPlace), name: .didAddSavedPlace, object: nil)

    }
    
    // Change the mode of transport for the route calculations
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
            itineraryManager.setTravelMode(travelMode)
            itineraryManager.calculateItineraryUpdates()
        }
    }
    
    // Compare itinerary places and saved places, mark which saved places are in the itinerary
    func markItineraryPlaces() {
        let savedPlaces = self.savedPlaces.getPlaces()
        savedPlaces.forEach{ $0.setInItinerary(false)}
        let itineraryPlaces = itineraryManager.getPlaceManager().getPlaces()
        for savedPlace in savedPlaces {
            for itineraryPlace in itineraryPlaces {
                if savedPlace == itineraryPlace {
                    savedPlace.setInItinerary(true)
                }
            }
        }
    }
    
    // Package itinerary and place data to send to map for rendering
    func updateMap() {
        if let mapViewController = mapViewController {
            // Determine place colors based on data
            // Set up to send to map
            var placeVisuals = [PlaceVisual]()
            var routeVisuals = [RouteVisual]()
            let nonItineraryPlaces = savedPlaces.getPlaces().filter { !$0.isInItinerary() }
            if nonItineraryPlaces.count > 0 {
                let nonItineraryVisuals = nonItineraryPlaces.map { PlaceVisual(place: $0, color: .gray) }
                placeVisuals.append(contentsOf: nonItineraryVisuals)
            }
            let numPlaces = itineraryManager.getPlaceManager().numPlaces()
            let places = itineraryManager.getPlaceManager().getPlaces()
            if numPlaces >= 1 {
                placeVisuals.append(PlaceVisual(place: places.first!, color: .green))
            }
            if numPlaces >= 2 {
                placeVisuals.append(PlaceVisual(place: places.last!, color: .red))
            }
            if numPlaces >= 3 {
                let enroutePlaces = Array(places[1 ... places.count - 2])
                let enrouteVisuals = enroutePlaces.map { PlaceVisual(place: $0, color: .yellow) }
                placeVisuals.append(contentsOf: enrouteVisuals)
            }
            if let routePolyline = itineraryManager.getRoutePolyline() {
                routeVisuals.append( RouteVisual(route: routePolyline, color: .blue) )
            }
            // Send and call a refresh!
            mapViewController.setPlaces(placeVisuals)
            mapViewController.setRoutes(routeVisuals)
            // Only actually refresh map if the view has loaded
            if mapViewController.viewIfLoaded != nil {
                mapViewController.refreshMarkup()
            }
        }
    }
    
    func updateTransportTimeLabel() {
        if let duration = itineraryManager.getRoute()?.getDuration() {
            let formatter = DateComponentsFormatter()
            formatter.allowedUnits = [.hour, .minute]
            formatter.unitsStyle = .full
            
            let formattedString = formatter.string(from: TimeInterval(duration))!
            transportTimeLabel.text = formattedString
        } else {
            transportTimeLabel.text = "no route yet"
        }
    }
    
    // Should also do this for just adding places
    // Should /also/ visualize non-itinerary places on map
    @objc func onDidUpdateItinerary(_ notification: Notification) {
        markItineraryPlaces()
        updateMap()
        updateTransportTimeLabel()
        itineraryViewController?.collectionView?.reloadData()
        placePaletteViewController?.collectionView?.reloadData()
    }
    
    @objc func onDidAddSavedPlace(_ notification: Notification) {
        updateMap()
        let newPlace = savedPlaces.getPlaces().last!
        mapViewController?.moveCameraTo(latitude: newPlace.coordinate.lat, longitude: newPlace.coordinate.lon)
        placePaletteViewController?.collectionView?.reloadData()
    }
    
    // Begin drag...
    func beginPotentialInsertionOf(place: Place) {
        itineraryManager.calculatePotentialRoutePermutations(for: place)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let placePaletteVC = segue.destination as? PlacePaletteViewController {
            placePaletteVC.savedPlaces = self.savedPlaces
            placePaletteVC.collectionView?.frame.size.width = self.view.frame.size.width / 2 // HACKY?
            placePaletteVC.didBeginDrag = self.beginPotentialInsertionOf(place:)
            self.placePaletteViewController = placePaletteVC
        }
        else if let itineraryVC = segue.destination as? ItineraryViewController {
            itineraryVC.itineraryManager = self.itineraryManager
            itineraryVC.collectionView?.frame.size.width = self.view.frame.size.width / 2 // HACKY?
            self.itineraryViewController = itineraryVC
        } else if let mapVC = segue.destination as? MapViewController {
            self.mapViewController = mapVC
            updateMap()
        }
    }
}
