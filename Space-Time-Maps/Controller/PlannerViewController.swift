//
//  ViewController.swift
//  Space-Time-Maps
//
//  Created by vicky on 2019-07-21.
//  Copyright © 2019 vicky. All rights reserved.
//

import UIKit

class PlannerViewController: UIViewController {
    
    var placeManager : PlaceManager!
    var itineraryManager : ItineraryManager!
    
    var placePaletteViewController : PlacePaletteViewController?
    var itineraryViewController : ItineraryViewController?
    var mapViewController : MapViewController?

    override func viewDidLoad() {
        super.viewDidLoad()

        NotificationCenter.default.addObserver(self, selector: #selector(onDidUpdateRoute), name: .didUpdateRoute, object: nil)
    }
    
    // Should also do this for just adding places
    // Should /also/ visualize non-itinerary places on map
    @objc func onDidUpdateRoute(_ notification: Notification) {
        if let route = itineraryManager.getRoute() {
            
            if let mapViewController = mapViewController {
                mapViewController.clearMap()
                if let startingPlace = itineraryManager.getStartingPlace() {
                    mapViewController.displayPlaces([startingPlace], color: .green)
                }
                if let endingPlace = itineraryManager.getEndingPlace() {
                    mapViewController.displayPlaces([endingPlace], color: .red)
                }
                if let enroutePlaces = itineraryManager.getEnroutePlaces() {
                    mapViewController.displayPlaces(enroutePlaces, color: .orange)
                }
                mapViewController.displayRoute(route)
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let placePaletteVC = segue.destination as? PlacePaletteViewController {
            placePaletteVC.placeManager = self.placeManager
            placePaletteVC.collectionView?.frame.size.width = self.view.frame.size.width / 2 // HACKY?
            self.placePaletteViewController = placePaletteVC
        }
        else if let itineraryVC = segue.destination as? ItineraryViewController {
            itineraryVC.itineraryManager = self.itineraryManager
            itineraryVC.collectionView?.frame.size.width = self.view.frame.size.width / 2 // HACKY?
            self.itineraryViewController = itineraryVC
        } else if let mapVC = segue.destination as? MapViewController {
            self.mapViewController = mapVC
        }
    }
}

extension Array where Element: Hashable {
    func difference(from other: [Element]) -> [Element] {
        let thisSet = Set(self)
        let otherSet = Set(other)
        return Array(thisSet.symmetricDifference(otherSet))
    }
}
