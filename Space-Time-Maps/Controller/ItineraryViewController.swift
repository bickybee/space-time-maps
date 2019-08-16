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
    @IBOutlet weak var timelineView: TimelineView!
    
    // API interfacing
    private let queryService = QueryService()
    
    // Interacting with itinerary
    var itineraryBeforeModifications : Itinerary? // Inaccurate name tbh-- more like "itineraryWithoutCurrentDraggingPlace"
    var previousTouchHour : Double?
    
    // Interacting with timeline
    var timer: Timer?
    var previousPanLocation : CGPoint?
    var startTime: TimeInterval = TimeInterval.from(hours: 12.0)
    var hourHeight: CGFloat = 100
    
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
        setupTimelineView()
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
    }
    
    func setupTimelineView() {
        setCurrentTime()
        timer = Timer.scheduledTimer(timeInterval: 60, target: self, selector: #selector(setCurrentTime), userInfo: nil, repeats: true)
        
        view.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(panTime)))
        view.addGestureRecognizer(UIPinchGestureRecognizer(target: self, action: #selector(pinchTime)))
    }
    
}

// MARK: - Itinerary related
extension ItineraryViewController {
    
    func previewInsert(place: Place, at time: TimeInterval) {
        
        // Need the initial itinerary to compare our modifications to
        guard let initialDestinations = itineraryBeforeModifications?.destinations else { return }
        
        let newDestination = Destination(place: place, startTime: time)
        var modifiedDestinations = initialDestinations
        modifiedDestinations.append(newDestination)
        itinerary.destinations = modifiedDestinations
        computeRoute()
        
    }
    
    func revertToInitialItinerary() {
        guard let initialDestinations = itineraryBeforeModifications?.destinations else { return }
        itinerary.destinations = initialDestinations
        computeRoute()
    }
    
    func computeRoute() {
        if itinerary.destinations.count == 0 {
            self.itinerary.route = []
            delegate?.itineraryViewController(self, didUpdateItinerary: self.itinerary)
        } else {
            queryService.getRouteFor(destinations: itinerary.destinations, travelMode: itinerary.travelMode) { route in
                self.itinerary.route = route
                self.delegate?.itineraryViewController(self, didUpdateItinerary: self.itinerary)
            }
        }
    }
    
}

// MARK: - Timeline related
extension ItineraryViewController {
    
    func reloadTimelineRelatedViews() {
        timelineView.startTime = startTime
        timelineView.hourHeight = hourHeight
        timelineView.setNeedsDisplay()
        collectionView.reloadData()
    }
    
    @objc func setCurrentTime() {
        guard let currentTime = Utils.currentTime() else { return }
        startTime = currentTime
        reloadTimelineRelatedViews()
    }
    
    @objc func panTime(gesture: UIPanGestureRecognizer) {
        let location = gesture.location(in: view)
        
        switch gesture.state {
        case .began:
            previousPanLocation = location
        case .changed:
            guard let previousY = previousPanLocation?.y else { return }
            let dy = location.y - previousY
            startTime -= Double(dy*100)
            previousPanLocation = location
            
            reloadTimelineRelatedViews()
            
        case .ended,
             .cancelled:
            previousPanLocation = nil
            
        default:
            break
        }
    }
    
    @objc func pinchTime(_ gestureRecognizer : UIPinchGestureRecognizer) {
        
        if gestureRecognizer.state == .began || gestureRecognizer.state == .changed {
            hourHeight *= gestureRecognizer.scale
            gestureRecognizer.scale = 1.0
            
            reloadTimelineRelatedViews()
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
            //return 0
            return itinerary.route.count ?? 0
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
        addDragRecognizerTo(cell: cell)
        
        return cell
        
    }
    
    func setupLegCell(_ cell: LegCell, with index: Int) -> LegCell {
        
        let legs = itinerary.route
        let maxIndex = legs.count - 1
        let gradient = ColorUtils.gradientFor(index: index, outOf: maxIndex + 1)
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = cell.bounds
        gradientLayer.colors = [gradient.0.cgColor, gradient.1.cgColor]
        cell.gradientView.layer.sublayers = nil
        cell.gradientView.layer.addSublayer(gradientLayer)
        
        let leg = legs[index]
        let timeString = Utils.secondsToString(seconds: leg.duration)
        cell.timeLabel.text = timeString
        
        return cell
    }
}

// MARK: - PlacePalette Drag Delegate
// Coordinates dragging/dropping from the place palette to the itinerary
extension ItineraryViewController : DragDelegate {
    
    func hourInTimeline(for viewFrame: CGRect) -> Double? {
        // Does the dragging view intersect our collection view?
        let intersection = collectionView.frame.intersection(viewFrame)
        guard !intersection.isNull else { return nil }
        
        // What time does this intersection correspond to? (Using top of view)
        let y = Double(intersection.minY)
        //let startOffset = startTime.inHours().truncatingRemainder(dividingBy: 1) * Double(hourHeight)
        let relativeHour = y / Double(hourHeight)
        let absoluteHour = relativeHour + startTime.inHours()        //set hour of destination
        
        return absoluteHour
    }
    
    func roundedHourInTimeline(for viewFrame: CGRect) -> Double? {
        // Does the dragging view intersect our collection view?
        guard let hour = hourInTimeline(for: viewFrame) else { return nil }
        let decimal = hour.truncatingRemainder(dividingBy: 1.0)
        let roundedHour = floor(hour) + floor(decimal / 0.25) * 0.25
        
        return roundedHour
    }
    
    func draggableCellViewController(_ draggableCellViewController: DraggableCellViewController, didBeginDragging object: AnyObject, at index: Int, withView view: UIView) {
        // Start drag session
        itineraryBeforeModifications = itinerary
        if let _ = draggableCellViewController as? ItineraryViewController {
            var destinations = itinerary.destinations
            destinations.remove(at: index)
            itineraryBeforeModifications!.destinations = destinations
        }
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
        guard let place = object as? Place else { return }
        
        let hour = roundedHourInTimeline(for: viewFrame)
        if hour != previousTouchHour {
            if let hour = hour {
                previewInsert(place: place, at: TimeInterval.from(hours: hour))
            } else {
                revertToInitialItinerary()
            }
            previousTouchHour = hour
        }
        
    }
    
    func draggableCellViewController(_ draggableCellViewController: DraggableCellViewController, didEndDragging object: AnyObject, at index: Int, withView view: UIView) {
        // End drag session
        itineraryBeforeModifications = nil
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
    
    func timelineStartTime(of collectionView: UICollectionView) -> TimeInterval {
        return startTime
    }
    
    func hourHeight(of collectionView: UICollectionView) -> CGFloat {
        return hourHeight
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

// MARK: - Self delegate protocol
protocol ItineraryViewControllerDelegate : AnyObject {
    
    func itineraryViewController(_ itineraryViewController: ItineraryViewController, didUpdateItinerary: Itinerary)
    
}
