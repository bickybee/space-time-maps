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

    var editingSession : ItineraryEditingSession?
    var previousTouchHour : Double?

    // Delegate (subscribes to itinerary updates)
    weak var delegate : ItineraryViewControllerDelegate?
    
    // Data source!
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
        collectionView.register(LocationCell.self, forCellWithReuseIdentifier: locationReuseIdentifier)
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
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: locationReuseIdentifier, for: indexPath) as! LocationCell
            return setupLocationCell(cell, with: indexPath.item)
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: legReuseIdentifier, for: indexPath) as! LegCell
            return setupLegCell(cell, with: indexPath.item)
        }
        
    }
    
    func setupLocationCell(_ cell: LocationCell, with index: Int) -> LocationCell {
        
        guard let destination = itinerary.destinations[safe: index] else { return cell }
        
        // Else, return a location cell
        let maxIndex = itinerary.destinations.count - 1
        let color = ColorUtils.colorFor(index: index, outOf: maxIndex)
        cell.backgroundColor = color
        cell.nameLabel.text = destination.place.name
        cell.layoutSubviews()
        addDragRecognizerTo(cell: cell)
        
        return cell
        
    }
    
    func setupLegCell(_ cell: LegCell, with index: Int) -> LegCell {
        
        let legs = itinerary.route
        let maxIndex = legs.count - 1
        let gradient = ColorUtils.gradientFor(index: index, outOf: maxIndex + 1)
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = cell.gradientView.frame
        gradientLayer.colors = [gradient.0.cgColor, gradient.1.cgColor]
        cell.gradientView.layer.sublayers = nil
        cell.gradientView.layer.addSublayer(gradientLayer)
        
        let leg = legs[index]
        let timeString = Utils.secondsToString(seconds: leg.duration)
        cell.timeLabel.text = timeString
        
        cell.layoutSubviews()
        
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
    
    func draggableCellViewController(_ draggableCellViewController: DraggableCellViewController, didBeginDragging object: AnyObject, at index: Int, withView view: UIView) {
        
        guard let place = object as? Place else { return }
        
        var editingDestinations = itinerary.destinations
        
        if draggableCellViewController as? ItineraryViewController != nil {
            editingDestinations.remove(at: index)
        }
        
        editingSession = ItineraryEditingSession(movingPlace: place, withIndex: index, inDestinations: editingDestinations, travelMode: .driving, callback: didEditItinerary)
    }
    
    func draggableCellViewController(_ draggableCellViewController: DraggableCellViewController, didContinueDragging object: AnyObject, at index: Int, withView view: UIView) {
        
        // First convert view from parent coordinates to local coordinates
        let viewFrame : CGRect
        if let placePaletteViewController = draggableCellViewController as? PlacePaletteViewController {
            viewFrame = placePaletteViewController.collectionView.convert(view.frame, to: collectionView)
        } else if let itineraryViewController = draggableCellViewController as? ItineraryViewController {
            viewFrame = itineraryViewController.collectionView.convert(view.frame, to: collectionView)
        } else {
            return
        }
        
        // Get place for corresponding time of touch
        guard let editingSession = editingSession else { return }
        
        let intersection = collectionView.frame.intersection(viewFrame)
        if intersection.isNull {
            editingSession.removeDestination()
            return
        }
        
        let y = intersection.minY // using top of view
        let hour = timelineController.roundedHourInTimeline(forY: y)
        if hour != previousTouchHour {
            editingSession.moveDestination(toTime: TimeInterval.from(hours: hour))
            previousTouchHour = hour
        }
        
    }
    
    func draggableCellViewController(_ draggableCellViewController: DraggableCellViewController, didEndDragging object: AnyObject, at index: Int, withView view: UIView) {
        // End drag session
        editingSession = nil
        previousTouchHour = nil
    }
    
}

extension ItineraryViewController: DragDataDelegate {
    
    func objectFor(draggableCell: DraggableCell) -> AnyObject? {
        guard let indexPath = collectionView.indexPath(for: draggableCell),
              let destination = itinerary.destinations[safe: indexPath.item] else { return nil }
        
        return destination.place
    }
    
    func indexFor(draggableCell: DraggableCell) -> Int? {
        guard let indexPath = collectionView.indexPath(for: draggableCell) else { return nil}
        return indexPath.item
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
        return schedulable.startTime
    }
    
    func collectionView(_ collectionView:UICollectionView, durationForSchedulableAtIndexPath indexPath: IndexPath) -> TimeInterval {
        guard let schedulable = schedulableFor(indexPath: indexPath) else { return 0 }
        return schedulable.duration
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
