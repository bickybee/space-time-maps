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
    private let reuseIdentifier = "locationCell"
    private let cellHeight : CGFloat = 50.0
    private let cellInsets = UIEdgeInsets(top: 5.0, left: 5.0, bottom: 5.0, right: 5.0)
    private let sectionInsets = UIEdgeInsets(top: 20.0, left: 10.0, bottom: 20.0, right: 10.0)
    
    // Child views
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var timelineView: TimelineView!
    
    // API interfacing
    private let queryService = QueryService()
    
    // Interacting with itinerary
    var itineraryBeforeModifications : Itinerary?
    var previousTouchHour : Int?
    
    // Interacting with timeline
    var timer: Timer?
    var previousPanLocation : CGPoint?
    var startTime: Double = 12 // in hours
    var hourHeight: CGFloat = 50
    
    // Delegate (subscribes to itinerary updates)
    weak var delegate : ItineraryViewControllerDelegate?
    
    // Data source!
    var itinerary = Itinerary(destinations: [Destination](), route: nil, travelMode: .driving) {
        didSet {
            collectionView.reloadData()
        }
    }
    
    // MARK: - Setup
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.dragDelegate = self as? DragDelegate
        self.dragDataDelegate = self as? DragDataDelegate
        
        setupCollectionView()
        setupTimelineView()
    }
    
    func setupCollectionView() {
        if let layout = collectionView?.collectionViewLayout as? ItineraryLayout {
            layout.delegate = self
        }
        collectionView.register(LocationCell.self, forCellWithReuseIdentifier: reuseIdentifier)
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
    
    func previewInsert(place: Place, at time: Int) {
        
        // Need the initial itinerary to compare our modifications to
        guard let initialDestinations = itineraryBeforeModifications?.destinations else { return }
        
        let newDestination = Destination(place: place, startTime: time)
        var modifiedDestinations = initialDestinations
        modifiedDestinations.append(newDestination)
        itinerary.destinations = modifiedDestinations
        computeRoute()
        
    }
    
    func computeRoute() {
        //queryService.sendRouteQuery(places: itinerary.places, travelMode: itinerary.travelMode, callback: setRoute)
        queryService.getRouteFor(destinations: itinerary.destinations, travelMode: itinerary.travelMode) { route in
            self.itinerary.route = route
            self.delegate?.itineraryViewController(self, didUpdateItinerary: self.itinerary)
        }
    }
    
    // FIXME: - legh how this is accessed from outside
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
            computeRoute()
        }
    }
    
    @objc func panDestination(_ gesture: UIPanGestureRecognizer) {
        print("pan")
        
        guard let originatingCell = gesture.view?.superview?.superview as? LocationCell else { return } // lmao
        guard let indexPath = collectionView.indexPath(for: originatingCell) else { return }
        guard let destination = itinerary.destinations[safe: indexPath.item] else { return }
        
        print(destination.place.name)
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
        // Get current time
        let calendar = Calendar.current
        let currentComponents = calendar.dateComponents([.hour, .minute], from: Date())
        
        // Get components of time
        guard let currentHour = currentComponents.hour else { return }
        guard let currentMinute = currentComponents.minute else { return }
        let currentTime = Double(currentHour) + (Double(currentMinute + 1) / 60.0) // 1 min in future :-)
        
        // Set time
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
            startTime -= Double(dy/70)
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
                    let timeString = Utils.secondsToString(seconds: timeInSeconds)
                    text += timeString + " -> "
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
            
            addDragRecognizerTo(cell: cell)
        }
        
        return cell
    }
}

// MARK: - PlacePalette Drag Delegate
// Coordinates dragging/dropping from the place palette to the itinerary
extension ItineraryViewController : DragDelegate {
    
    func timelineLocation(of viewFrame: CGRect) -> Int? {
        // Does the dragging view intersect our collection view?
        let intersection = collectionView.frame.intersection(viewFrame)
        guard !intersection.isNull else { return nil }
        
        // What time does this intersection correspond to? (Using top of view)
        let y = intersection.minY
        let startOffset = CGFloat(startTime.truncatingRemainder(dividingBy: 1)) * hourHeight
        let hour = Int(floor((y + startOffset) / hourHeight))
        //set hour of destination
        
        return hour + Int(floor(timelineView.startTime))
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
        guard let hour = timelineLocation(of: viewFrame), hour != previousTouchHour,
              let place = object as? Place else { return }
        
        // If the time has changed, preview changes
        previewInsert(place: place, at: hour)
        previousTouchHour = hour
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
    
    func startTime(of collectionView: UICollectionView) -> Int {
        return Int(floor(startTime))
    }
    
    func startOffset(of collectionView: UICollectionView) -> CGFloat {
        return CGFloat(startTime.truncatingRemainder(dividingBy: 1)) * timelineView.hourHeight
    }
    
    func hourHeight(of collectionView: UICollectionView) -> CGFloat {
        return hourHeight
    }
    
    func collectionView(_ collectionView:UICollectionView, startTimeForDestinationAtIndexPath indexPath: IndexPath) -> Int {
        return itinerary.destinations[indexPath.item].startTime
    }
    
}

// MARK: - Self delegate protocol
protocol ItineraryViewControllerDelegate : AnyObject {
    
    func itineraryViewController(_ itineraryViewController: ItineraryViewController, didUpdateItinerary: Itinerary)
    
}
