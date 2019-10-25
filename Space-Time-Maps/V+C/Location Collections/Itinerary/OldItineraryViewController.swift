////
////  ItineraryViewController.swift
////  Space-Time-Maps
////
////  Created by vicky on 2019-07-21.
////  Copyright © 2019 vicky. All rights reserved.
////
//
//import UIKit
//
//class OldItineraryViewController: DraggableContentViewController {
//
//    // CollectionView Cell constants
//    private let locationReuseIdentifier = "locationCell"
//    private let legReuseIdentifier = "legCell"
//    private let oneOfReuseIdentifier = "oneOfCell"
//    private let groupReuseIdentifier = "groupCell"
//    private let nilReuseIdentifier = "nilCell"
//
//    private let scheduler = Scheduler()
//
//    // Child views
//    @IBOutlet weak var collectionView: UICollectionView!
//    var timelineController: TimelineViewController!
//    var optionView : UIView?
//    var optionsVC = OptionsViewController()
//
//    // Itinerary editing
//    var editingSession : ItineraryEditingSession?
//    var previousTouchHour : Double?
//    var defaultDuration = TimeInterval.from(hours: 1.0)
//
//    // Delegate (subscribes to itinerary updates)
//    weak var delegate : ItineraryViewControllerDelegate?
//
//    // Collection view data source!
//    var itinerary = Itinerary()
//    var dragging = false
//    
//    // MARK: - Setup
//    override func viewDidLoad() {
//        super.viewDidLoad()
//
//        self.dragDelegate = self as DragDelegate
//        self.dragDataDelegate = self as DragDataDelegate
//
//        setupCollectionView()
//
//    }
//
//    override func viewDidLayoutSubviews() {
//        timelineController.setSidebarWidth(collectionView.frame.minX)
//    }
//
//    func setupCollectionView() {
//
//        if let layout = collectionView?.collectionViewLayout as? ItineraryLayout {
//            layout.delegate = self
//        }
//
//        let destNib = UINib(nibName: "DestCell", bundle: nil)
//        let groupNib = UINib(nibName: "GroupCell", bundle: nil)
//        let routeNib = UINib(nibName: "RouteCell", bundle: nil)
//        collectionView.register(routeNib, forCellWithReuseIdentifier: legReuseIdentifier)
//        collectionView.register(destNib, forCellWithReuseIdentifier: locationReuseIdentifier)
//        collectionView.register(groupNib, forCellWithReuseIdentifier: groupReuseIdentifier)
//        collectionView.register(NilCell.self, forCellWithReuseIdentifier: nilReuseIdentifier)
//
//        collectionView.delegate = self
//        collectionView.dataSource = self
//        collectionView.isScrollEnabled = false
//        collectionView.backgroundColor = .clear
//
//        showDraggingView = false
//        collectionView.addGestureRecognizer(UIPinchGestureRecognizer(target: self, action:#selector(pinchLocationCell)))
//    }
//
//    func computeRoute() {
//        // This is called when the mode of transport changes, but needs to be fixed because it won't update asManyOf blocks if they change to no longer fit their dests...
//        scheduler.reschedule(blocks: itinerary.schedule, callback: didEditItinerary)
//
//    }
//
//    func updateScheduler(_ places: [Place]) {
//        scheduler.updatePlaces(places)
//    }
//
//    func updateScheduler(_ travelMode: TravelMode) {
//        scheduler.travelMode = travelMode
//        scheduler.reschedule(blocks: itinerary.schedule, callback: didEditItinerary(blocks:route:))
//    }
//
//    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
//        if let timelineVC = segue.destination as? TimelineViewController {
//
//            timelineVC.delegate = self
//            timelineController = timelineVC
//
//        }
//    }
//
//    @objc func pinchLocationCell(gesture: UIPinchGestureRecognizer) {
//
//        guard let editingSession = editingSession else { return }
//
//        let dir = Double(gesture.scale - 1.0)
//        let thresh = 0.05
//
//        if abs(dir) >= thresh {
//            let step = dir > 0 ? 1 : -1
//            let deltaTime = TimeInterval.from(minutes: step * 15)
//            editingSession.changeBlockDuration(with: deltaTime)
//            gesture.scale = 1.0
//        }
//
//    }
//
//}
//
//// MARK: - CollectionView delegate methods
//extension OldItineraryViewController : UICollectionViewDelegateFlowLayout, UICollectionViewDelegate, UICollectionViewDataSource {
//
//    func numberOfSections(in collectionView: UICollectionView) -> Int {
//        return 3
//    }
//
//    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
//
//        switch section {
//        case 0:
//            return itinerary.destinations.count
//        case 1:
//            return itinerary.route.count
//        case 2:
//            return itinerary.schedule.count
//        default:
//            return 0
//        }
//
//    }
//
//    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
//
//        let section = indexPath.section
//        switch section {
//        case 0:
//            return setupDestinationCell(with: indexPath)
//        case 1:
//            return setupLegCell(with: indexPath)
//        case 2:
//            return setupBlockCell(with: indexPath)
//        default:
//            return UICollectionViewCell()
//        }
//
//    }
//
//    func setupDestinationCell(with indexPath: IndexPath) -> UICollectionViewCell {
//
//        let index = indexPath.item
//        let destination = itinerary.destinations[index]
//        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: locationReuseIdentifier, for: indexPath) as! DestCell
//        cell.configureWith(destination)
//        cell.isUserInteractionEnabled = false
//        //        addDragRecognizerTo(draggable: cell)
//        return cell
//
//    }
//
//    func setupLegCell(with indexPath: IndexPath) -> UICollectionViewCell {
//
//        let index = indexPath.item
//        let leg = itinerary.route.legs[index]
//        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: legReuseIdentifier, for: indexPath) as! RouteLineCell
//        let gradient = [leg.startPlace.color, leg.endPlace.color]
//
//        cell.configureWith(timing: leg.timing, duration: leg.travelTiming.duration, hourHeight: timelineController.hourHeight, gradient: gradient)
//        return cell
//    }
//
//    func setupBlockCell(with indexPath: IndexPath) -> UICollectionViewCell {
//        let index = indexPath.item
//        guard let block = itinerary.schedule[index] as? OptionBlock else {
//            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: nilReuseIdentifier, for: indexPath) as! NilCell
//            if (cell.gestureRecognizers == nil || cell.gestureRecognizers?.count == 0) {
//                addDragRecognizerTo(draggable: cell)
//            }
//            return cell
//        }
//
//        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: groupReuseIdentifier, for: indexPath) as! GroupCell
//
//        //        cell.nextBtn.tag = index
//        //        cell.nextBtn.addTarget(self, action: #selector(nextOption(_:)), for: .touchUpInside)
//        //        cell.prevBtn.tag = index
//        //        cell.prevBtn.addTarget(self, action: #selector(prevOption(_:)), for: .touchUpInside)
//        //        cell.configureWith(block)
//        cell.button.tag = index
//        cell.button.addTarget(self, action: #selector(seeOptions), for: .touchUpInside)
//        if (cell.gestureRecognizers == nil || cell.gestureRecognizers?.count == 0) {
//            addDragRecognizerTo(draggable: cell)
//        }
//
//        return cell
//    }
//
//    @objc func seeOptions(_ sender: UIButton) {
//        let blockIndex = sender.tag
//
//        guard let newView = setupOptionViewForBlockIndex(blockIndex) else { return }
//        collectionView.addSubview(newView)
//        optionView = newView
//
//    }
//
//    func setupOptionViewForBlockIndex(_ blockIndex: Int) -> UIView? {
//
//        guard let block = itinerary.schedule[blockIndex] as? OptionBlock else { return nil }
//        let enteringLeg = itinerary.route.legEndingAt(block.destinations![0].place)
//        let exitingLeg = itinerary.route.legStartingAt(block.destinations!.last!.place)
//        let startTime = enteringLeg != nil ? enteringLeg!.timing.start : block.timing.start
//        let endTime = exitingLeg != nil ? exitingLeg!.timing.end : block.timing.end
//
//        let minY = timelineController.yFromTime(startTime)
//        let maxY = timelineController.yFromTime(endTime)
//        let frame = CGRect(x: 0, y: minY, width: collectionView.frame.width, height: maxY - minY)
//
//        let newOptionView = UIView(frame: frame)
//        newOptionView.tag = blockIndex
//        newOptionView.backgroundColor = UIColor.red
//
//        optionsVC.view.frame = CGRect(x: 0, y: 0, width: newOptionView.frame.width, height: newOptionView.frame.height)
//        optionsVC.optionBlock = block
//        optionsVC.hourHeight = timelineController.hourHeight
//
//        newOptionView.addSubview(optionsVC.view)
//        optionsVC.didMove(toParent: self)
//        return newOptionView
//
//    }
//
//    @objc func prevOption(_ sender: UIButton) {
//        let blockIndex = sender.tag
//        scheduler.scheduleOptionChange(of: blockIndex, direction: -1, in: itinerary.schedule, callback: didEditItinerary)
//    }
//
//    @objc func nextOption(_ sender: UIButton) {
//        let blockIndex = sender.tag
//        scheduler.scheduleOptionChange(of: blockIndex, direction: 1, in: itinerary.schedule, callback: didEditItinerary)
//    }
//
//}
//
//// MARK: - PlacePalette Drag Delegate
//// Coordinates dragging/dropping from the place palette to the itinerary
//extension OldItineraryViewController : DragDelegate {
//
//    func draggableContentViewController(_ draggableContentViewController: DraggableContentViewController, didBeginDragging object: Any, at indexPath: IndexPath, withGesture gesture: UIPanGestureRecognizer) {
//
//        guard let block = blockFromObject(object) else { return }
//        var editingBlocks = itinerary.schedule
//        var index : Int?
//
//        if draggableContentViewController is ItineraryViewController {
//            editingBlocks.remove(at: indexPath.item)
//            index = indexPath.item
//        }
//
//        editingSession = ItineraryEditingSession(scheduler: scheduler, movingBlock: block, withIndex: index, inBlocks: editingBlocks, travelMode: itinerary.travelMode, callback: didEditItinerary)
//    }
//
//    func draggableContentViewController(_ draggableContentViewController: DraggableContentViewController, didContinueDragging object: Any, at indexPath: IndexPath, withGesture gesture: UIPanGestureRecognizer) {
//
//        // Get place for corresponding time of touch
//        guard let editingSession = editingSession else { return }
//        let location = gesture.location(in: collectionView)
//
//        if !collectionView.frame.contains(location) {
//            if previousTouchHour != nil {
//                editingSession.removeBlock()
//                previousTouchHour = nil
//            }
//            return
//        }
//
//        let y = gesture.location(in: view).y
//        let hour = timelineController.roundedHourInTimeline(forY: y)
//        if hour != previousTouchHour {
//            editingSession.moveBlock(toTime: TimeInterval.from(hours: hour))
//            previousTouchHour = hour
//        }
//
//    }
//
//    func draggableContentViewController(_ draggableContentViewController: DraggableContentViewController, didEndDragging object: Any, at indexPath: IndexPath, withGesture gesture: UIPanGestureRecognizer) {
//
//        editingSession = nil
//        previousTouchHour = nil
//
//    }
//
//    func didEditItinerary(blocks: [ScheduleBlock]?, route: Route?) {
//
//        if let blocks = blocks {
//            self.itinerary.schedule = blocks
//        }
//
//        if let route = route {
//            self.itinerary.route = route
//        }
//
//        DispatchQueue.main.async {
//            self.collectionView.reloadData()
//            self.delegate?.itineraryViewController(self, didUpdateItinerary: self.itinerary)
//        }
//
//    }
//
//    func blockFromObject(_ object : Any) -> ScheduleBlock? {
//
//        // If we're dragging within the itinerary, object is and stays a block
//        if let scheduleObject = object as? ScheduleBlock {
//            return scheduleObject
//        } else { // Otherwise we're dragging a place or placegroup from the palette into the itinerary, meaning we need to turn it into a block
//            if let place = object as? Place {
//                return SingleBlock(timing: Timing(start: 0, duration: place.timeSpent), place: place)
//
//            } else if let group = object as? PlaceGroup {
//                switch group.kind {
//                case .asManyOf:
//                    return AsManyOfBlock(placeGroup: group, timing: Timing(start: 0, duration: TimeInterval.from(hours: 2)))
//                case .oneOf,
//                     .none:
//                    return  OneOfBlock(placeGroup: group, timing: Timing(start: 0, duration: defaultDuration))
//                }
//
//            } else {
//                return nil
//            }
//        }
//
//    }
//
//}
//
//extension OldItineraryViewController: DragDataDelegate {
//
//    func objectFor(draggable: UIView) -> Any? {
//        guard let draggable = draggable as? UICollectionViewCell,
//            let indexPath = collectionView.indexPath(for: draggable),
//            let obj = eventFor(indexPath: indexPath) else { return nil }
//
//        if obj is ScheduleBlock {
//            return obj
//        } else if obj is Destination {
//            return blockOfDestination(at: indexPath.item)
//        } else {
//            return nil
//        }
//
//    }
//
//    func indexPathFor(draggable: UIView) -> IndexPath? {
//        guard let draggable = draggable as? UICollectionViewCell,
//            let indexPath = collectionView.indexPath(for: draggable) else { return nil}
//
//        return indexPath
//    }
//
//    // this is bad i think?? lol TODO make not bad!
//    func blockOfDestination(at index: Int) -> ScheduleBlock? {
//
//        var count = 0
//
//        for block in itinerary.schedule {
//
//            if let destinations = block.destinations {
//                count += destinations.count
//            }
//
//            if count > index {
//                return block
//            }
//
//        }
//
//        return nil
//
//    }
//
//}
//
//
//// MARK: - Custom CollectionView Layout delegate methods
//extension OldItineraryViewController : ItineraryLayoutDelegate {
//
//    func timelineStartHour(of collectionView: UICollectionView) -> CGFloat {
//        return timelineController.startHour
//    }
//
//    func hourHeight(of collectionView: UICollectionView) -> CGFloat {
//        return timelineController.hourHeight
//    }
//
//    func collectionView(_ collectionView:UICollectionView, timingForEventAtIndexPath indexPath: IndexPath) -> Timing {
//        guard let event = eventFor(indexPath: indexPath) else { return Timing() }
//        return event.timing
//    }
//
//    func eventFor(indexPath: IndexPath) -> Schedulable? {
//
//        let section = indexPath.section
//        let item = indexPath.item
//
//        switch section {
//        case 0:
//            return itinerary.destinations[safe: item]
//        case 1:
//            return itinerary.route.legs[safe: item]
//        case 2:
//            return itinerary.schedule[safe: item]
//        default:
//            return nil
//        }
//
//    }
//}
//
//// Reload collection when there are changes to the timeline (timeline panning, timeline pinching)
//extension OldItineraryViewController: TimelineViewDelegate {
//
//    func timelineViewController(_ timelineViewController: TimelineViewController, didUpdateStartHour: CGFloat) {
//        collectionView.reloadData()
//        if let ov = optionView {
//            ov.removeFromSuperview()
//            optionView = setupOptionViewForBlockIndex(ov.tag)!
//            collectionView.addSubview(optionView!)
//        }
//    }
//
//    func timelineViewController(_ timelineViewController: TimelineViewController, didUpdateHourHeight: CGFloat) {
//        collectionView.reloadData()
//        if let ov = optionView {
//            ov.removeFromSuperview()
//            optionView = setupOptionViewForBlockIndex(ov.tag)!
//            collectionView.addSubview(optionView!)
//        }
//    }
//
//}
//
//// MARK: - Self delegate protocol
//protocol OldItineraryViewControllerDelegate : AnyObject {
//
//    func itineraryViewController(_ itineraryViewController: OldItineraryViewController, didUpdateItinerary: Itinerary)
//
//}
//
