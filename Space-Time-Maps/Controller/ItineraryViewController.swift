//
//  ItineraryViewController.swift
//  Space-Time-Maps
//
//  Created by vicky on 2019-07-21.
//  Copyright © 2019 vicky. All rights reserved.
//

import UIKit

private let reuseIdentifier = "locationCell"

class ItineraryViewController: UICollectionViewController {
    
    private let cellHeight : CGFloat = 50.0
    private let sectionInsets = UIEdgeInsets(top: 20.0, left: 10.0, bottom: 20.0, right: 10.0)
    private let queryService = QueryService()
    
    weak var delegate : ItineraryViewControllerDelegate?
    var itinerary = Itinerary(places: [Place](), route: nil, travelMode: .driving) {
        didSet {
            collectionView.reloadData()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.register(LocationCell.self, forCellWithReuseIdentifier: reuseIdentifier)
    }
    
    @objc func setRoute(route: Route) {
        print("set route")
        itinerary.route = route
        delegate?.itineraryViewController(self, didUpdateItinerary: itinerary)
    }
    
    func updateItinerary() {
        queryService.sendRouteQuery(places: itinerary.places, travelMode: itinerary.travelMode, callback: setRoute)
    }
    
    func transportModeChanged(_ sender: Any) {
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
            itinerary.travelMode = travelMode
            updateItinerary()
        }
    }

}

extension ItineraryViewController : UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        var size = view.frame.size
        size.width -= (sectionInsets.left + sectionInsets.right)
        return CGSize(width:size.width, height:cellHeight)
    }
    
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return itinerary.places.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! LocationCell
        let index = indexPath.item
        
        
        if let place = itinerary.places[safe: index] {
            var text = ""
            
            // If there's an existing route and the cell is odd, return a route cell
            if let route = itinerary.route {
                let legs = route.legs
                if index > 0 && index <= legs.count {
                    let timeInSeconds = route.legs[index-1].duration
                    let formatter = DateComponentsFormatter()
                    formatter.allowedUnits = [.hour, .minute]
                    formatter.unitsStyle = .full
                    let formattedString = formatter.string(from: TimeInterval(timeInSeconds))!
                    text += formattedString + " -> "
                }
            }
            
            // Else, return a location cell
            if index == 0 {
                cell.backgroundColor = .green
            } else if index == itinerary.places.count - 1 {
                cell.backgroundColor = .red
            } else {
                cell.backgroundColor = .yellow
            }
            text += place.name
            cell.nameLabel.text = text
            cell.nameLabel.backgroundColor = .white
            cell.nameLabel.sizeToFit()
            cell.nameLabel.center = cell.contentView.center
        }
        
        return cell
    }
}

protocol ItineraryViewControllerDelegate : AnyObject {
    
    func itineraryViewController(_ itineraryViewController: ItineraryViewController, didUpdateItinerary: Itinerary)
    
}
