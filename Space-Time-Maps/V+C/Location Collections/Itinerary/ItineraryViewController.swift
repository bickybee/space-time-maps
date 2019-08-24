//
//  ItineraryViewController.swift
//  Space-Time-Maps
//
//  Created by vicky on 2019-07-21.
//  Copyright © 2019 vicky. All rights reserved.
//

import UIKit

class ItineraryViewController: DraggableCellViewController {

    // CollectionView Cell constants
    private let locationReuseIdentifier = "locationCell"
    private let legReuseIdentifier = "legCell"
    
    // Child views
    @IBOutlet weak var collectionView: UICollectionView!
    var timelineController: TimelineViewController!

    // Itinerary editing
    var editingSession : ItineraryEditingSession?
    var previousTouchHour : Double?
    var defaultDuration = TimeInterval.from(hours: 0.5)

    // Delegate (subscribes to itinerary updates)
    weak var delegate : ItineraryViewControllerDelegate?
    
    // Collection view data source!
    var itinerary = Itinerary(destinations: [Destination](), route:[Leg](), travelMode: .driving) {
        didSet {
            collectionView.reloadData()
        }
    }
    
    // MARK: - Setup
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.dragDelegate = self as DragDelegate
        self.dragDataDelegate = self as DragDataDelegate
        
        setupCollectionView()
    }
    
    override func viewDidLayoutSubviews() {
        timelineController.setSidebarWidth(collectionView.frame.minX)
    }
    
    func setupCollectionView() {
        if let layout = collectionView?.collectionViewLayout as? ItineraryLayout {
            layout.delegate = self
        }
        collectionView.register(DestinationCell.self, forCellWithReuseIdentifier: locationReuseIdentifier)
        collectionView.register(LegCell.self, forCellWithReuseIdentifier: legReuseIdentifier)
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.isScrollEnabled = false
        collectionView.backgroundColor = .clear
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let timelineVC = segue.destination as? TimelineViewController {
            
            timelineVC.delegate = self
            timelineController = timelineVC
            
        }
    }
    
}

// MARK: - CollectionView delegate methods
extension ItineraryViewController : UICollectionViewDelegateFlowLayout, UICollectionViewDelegate, UICollectionViewDataSource {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 2
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        if section == 0 {
            return itinerary.destinations.count
        } else {
            return itinerary.route.count
        }
        
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        if indexPath.section == 0 {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: locationReuseIdentifier, for: indexPath) as! DestinationCell
            return setupLocationCell(cell, with: indexPath.item)
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: legReuseIdentifier, for: indexPath) as! LegCell
            return setupLegCell(cell, with: indexPath.item)
        }
        
    }
    
    func setupLocationCell(_ cell: DestinationCell, with index: Int) -> DestinationCell {
        
        guard let destination = itinerary.destinations[safe: index] else { return cell }
        
//        if editingSession != nil {
//            cell.setupWith(name: destination.place.name, color: .lightGray, constrained: destination.constraints.areEnabled)
//        } else {
        let fraction = Double(index) / Double(itinerary.destinations.count - 1)
        cell.setupWith(name: destination.place.name, fraction: fraction, constrained: destination.constraints.areEnabled)
    
        addDragRecognizerTo(cell: cell)
        
        return cell
        
    }
    
    func setupLegCell(_ cell: LegCell, with index: Int) -> LegCell {
        
        let legs = itinerary.route
        guard let leg = legs[safe: index] else { return cell }
        
        let startFraction = Double(index) / Double(legs.count)
        let endFraction = Double(index + 1) / Double(legs.count + 1)
        cell.setupWith(duration: leg.timing.duration, fromStartFraction: startFraction, toEndFraction: endFraction)
        
        return cell
    }
}

// MARK: - PlacePalette Drag Delegate
// Coordinates dragging/dropping from the place palette to the itinerary
extension ItineraryViewController : DragDelegate {
    
    func didEditItinerary(destinations: [Destination]?, route: Route?) {
        
        guard let destinations = destinations, let route = route else { return }
        
        self.itinerary.destinations = destinations
        self.itinerary.route = route
        delegate?.itineraryViewController(self, didUpdateItinerary: itinerary)
    }
    
    func draggableCellViewController(_ draggableCellViewController: DraggableCellViewController, didBeginDragging object: AnyObject, at indexPath: IndexPath, withGesture gesture: UIPanGestureRecognizer) {
        
        let destination : Destination
        if let place = object as? Place {
            destination = Destination(place: place, timing: Timing(start: 0, duration: defaultDuration), constraints: Constraints())
        } else if let dest = object as? Destination {
            destination = dest
        } else {
            return
        }
        
        var editingDestinations = itinerary.destinations
        
        if draggableCellViewController as? ItineraryViewController != nil {
            editingDestinations.remove(at: indexPath.item)
        }
        
        editingSession = ItineraryEditingSession(movingDestination: destination, withIndex: indexPath.item, inDestinations: editingDestinations, travelMode: .driving, callback: didEditItinerary)
    }
    
    func draggableCellViewController(_ draggableCellViewController: DraggableCellViewController, didContinueDragging object: AnyObject, at indexPath: IndexPath, withGesture gesture: UIPanGestureRecognizer) {
        
        // Get place for corresponding time of touch
        guard let editingSession = editingSession else { return }
        let location = gesture.location(in: collectionView)
        
        if !collectionView.frame.contains(location) {
            editingSession.removeDestination()
            return
        }
        
        let y = location.y
        let hour = timelineController.roundedHourInTimeline(forY: y)
        if hour != previousTouchHour {
            editingSession.moveDestination(toTime: TimeInterval.from(hours: hour))
            previousTouchHour = hour
        }
        
    }
    
    func draggableCellViewController(_ draggableCellViewController: DraggableCellViewController, didEndDragging object: AnyObject, at indexPath: IndexPath, withGesture gesture: UIPanGestureRecognizer) {
        
//        editingSession?.end()
        editingSession = nil
        previousTouchHour = nil
        
    }
    
    func cellForIndex(_ indexPath: IndexPath) -> DraggableCell? {
        
        return collectionView.cellForItem(at: indexPath) as? DraggableCell
        
    }
    
}

extension ItineraryViewController: DragDataDelegate {
    
    func objectFor(draggableCell: DraggableCell) -> AnyObject? {
        guard let indexPath = collectionView.indexPath(for: draggableCell),
              let destination = itinerary.destinations[safe: indexPath.item] else { return nil }
        
        return destination
    }
    
    func indexPathFor(draggableCell: DraggableCell) -> IndexPath? {
        guard let indexPath = collectionView.indexPath(for: draggableCell) else { return nil}
        return indexPath
    }
    
}


// MARK: - Custom CollectionView Layout delegate methods
extension ItineraryViewController : ItineraryLayoutDelegate {
    
    func timelineStartHour(of collectionView: UICollectionView) -> CGFloat {
        return timelineController.startHour
    }
    
    func hourHeight(of collectionView: UICollectionView) -> CGFloat {
        return timelineController.hourHeight
    }
    
    func collectionView(_ collectionView:UICollectionView, startTimeForSchedulableAtIndexPath indexPath: IndexPath) -> TimeInterval {
        guard let schedulable = schedulableFor(indexPath: indexPath) else { return 0 }
        return schedulable.timing.start
    }
    
    func collectionView(_ collectionView:UICollectionView, durationForSchedulableAtIndexPath indexPath: IndexPath) -> TimeInterval {
        guard let schedulable = schedulableFor(indexPath: indexPath) else { return 0 }
        return schedulable.timing.duration
    }
    
    func schedulableFor(indexPath: IndexPath) -> Schedulable? {
        
        let section = indexPath.section
        let item = indexPath.item
        
        if section == 0 {
            return itinerary.destinations[safe: item]
        } else if section == 1 {
            return itinerary.route[safe: item]
        } else {
            return nil
        }
        
    }
}

extension ItineraryViewController: TimelineViewDelegate {
    
    func timelineViewController(_ timelineViewController: TimelineViewController, didUpdateStartHour: CGFloat) {
        collectionView.reloadData()
    }
    
    func timelineViewController(_ timelineViewController: TimelineViewController, didUpdateHourHeight: CGFloat) {
        collectionView.reloadData()
    }
    
}

// MARK: - Self delegate protocol
protocol ItineraryViewControllerDelegate : AnyObject {
    
    func itineraryViewController(_ itineraryViewController: ItineraryViewController, didUpdateItinerary: Itinerary)
    
}
