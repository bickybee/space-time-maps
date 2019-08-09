//
//  ItineraryViewController.swift
//  Space-Time-Maps
//
//  Created by vicky on 2019-07-21.
//  Copyright © 2019 vicky. All rights reserved.
//

import UIKit

class ItineraryViewController: UIViewController {

    private let reuseIdentifier = "placeCell"
    private let cellHeight : CGFloat = 50.0
    private let sectionInsets = UIEdgeInsets(top: 20.0, left: 10.0, bottom: 20.0, right: 10.0)
    private let queryService = QueryService()
    
    weak var delegate : ItineraryViewControllerDelegate?
    let numHours = 12
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var timelineView: UIView!
    
    var itineraryBeforeModifications : Itinerary?
    
    // Data source!
    var itinerary = Itinerary(destinations: [Destination](), route: nil, travelMode: .driving) {
        didSet {
            collectionView.reloadData()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let layout = collectionView?.collectionViewLayout as? ItineraryLayout {
            print("set layout")
            layout.delegate = self
        }
        collectionView.register(LocationCell.self, forCellWithReuseIdentifier: reuseIdentifier)
        collectionView.delegate = self
        collectionView.dataSource = self
    }
    
    @objc func setRoute(route: Route) {
        itinerary.route = route
        delegate?.itineraryViewController(self, didUpdateItinerary: itinerary)
    }
    
    func updateItinerary() {
        //queryService.sendRouteQuery(places: itinerary.places, travelMode: itinerary.travelMode, callback: setRoute)
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

extension ItineraryViewController : PlacePaletteViewControllerDragDelegate {
    
    func previewInsert(place: Place, withViewFrame viewFrame: CGRect) {
        
        // Need the initial itinerary to compare our modifications to
        guard let initialDestinations = itineraryBeforeModifications?.destinations else { return }
        
        // Does the dragging view intersect our collection view?
        let intersection = collectionView.frame.intersection(viewFrame)
        guard !intersection.isNull else { return }

        // What time does this intersection correspond to?
        let y = intersection.minY
        let hourHeight = view.frame.height / CGFloat(numHours)
        let hour = floor(y / hourHeight)
        //set hour of destination
        
        let newDestination = Destination(place: place, startTime: Int(hour))
        
        // INSERT!
        var modifiedDestinations = initialDestinations
        modifiedDestinations.append(newDestination)
        itinerary.destinations = modifiedDestinations
        updateItinerary()
        
    }
    
    func placePaletteViewController(_ placePaletteViewController: PlacePaletteViewController, didBeginDraggingPlace place: Place, withPlaceholderView view: UIView) {
        itineraryBeforeModifications = itinerary
    }
    
    func placePaletteViewController(_ placePaletteViewController: PlacePaletteViewController, didContinueDraggingPlace place: Place, withPlaceholderView view: UIView) {
        // First convert view from parent coordinates to local coordinates
        let viewFrame = placePaletteViewController.collectionView.convert(view.frame, to: collectionView)
        previewInsert(place: place, withViewFrame: viewFrame)
    }
    
    func placePaletteViewController(_ placePaletteViewController: PlacePaletteViewController, didEndDraggingPlace place: Place, withPlaceholderView view: UIView) {
        // First convert view from parent coordinates to local coordinates
        let viewFrame = placePaletteViewController.collectionView.convert(view.frame, to: collectionView)
        previewInsert(place: place, withViewFrame: viewFrame)
        // End drag session
        itineraryBeforeModifications = nil
    }
    
}

extension ItineraryViewController : UICollectionViewDelegateFlowLayout, UICollectionViewDelegate, UICollectionViewDataSource {
        
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        var size = view.frame.size
        size.width -= (sectionInsets.left + sectionInsets.right)
        return CGSize(width:size.width, height:cellHeight)
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return itinerary.destinations.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! LocationCell
        let index = indexPath.item
        
        
        if let destination = itinerary.destinations[safe: index] {
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
            } else if index == itinerary.destinations.count - 1 {
                cell.backgroundColor = .red
            } else {
                cell.backgroundColor = .yellow
            }
            text += destination.place.name
            cell.nameLabel.text = text
            cell.nameLabel.backgroundColor = .white
            cell.nameLabel.sizeToFit()
            cell.nameLabel.center = cell.contentView.center
        }
        
        return cell
    }
}

extension ItineraryViewController : ItineraryLayoutDelegate {
    
    func numberOfHours(of collectionView: UICollectionView) -> Int {
        return 12
    }
    
    func hourHeight(of collectionView: UICollectionView) -> CGFloat {
        return timelineView.frame.height / CGFloat(numHours)
    }
    
    func collectionView(_ collectionView:UICollectionView, startTimeForDestinationAtIndexPath indexPath: IndexPath) -> Int {
        return itinerary.destinations[indexPath.item].startTime
    }
    
}

protocol ItineraryViewControllerDelegate : AnyObject {
    
    func itineraryViewController(_ itineraryViewController: ItineraryViewController, didUpdateItinerary: Itinerary)
    
}
