//
//  PlacePaletteViewController.swift
//  Space-Time-Maps
//
//  Created by vicky on 2019-07-21.
//  Copyright © 2019 vicky. All rights reserved.
//

import UIKit
import GooglePlaces
import GoogleMaps

private let reuseIdentifier = "placeCell"

class PlacePaletteViewController: DraggableContentViewController {
    
    weak var delegate : PlacePaletteViewControllerDelegate?
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var searchButton: UIButton!
    @IBOutlet weak var enlargeButton: UIButton!
    @IBOutlet weak var groupButton: UIButton!
    var inEditingMode : Bool = false
    
    // For autocomplete search
    var geographicSearchBounds : GMSCoordinateBounds?
    
    // Data source
    var groups = [PlaceGroup]() {
        didSet {
            collectionView.reloadData()
        }
    }
    
    var placeToAdd : Place?
    
    var groupsBeforeEditing = [PlaceGroup]()
    var midDrag = false
    var draggingIndexPath : IndexPath?
    
    // CollectionView cell
    private let cellHeight : CGFloat = 50.0
    private var cellWidth : CGFloat!
    private let sectionInsets = UIEdgeInsets(top: 20.0, left: 10.0, bottom: 20.0, right: 10.0)
    private let cellInsets = UIEdgeInsets(top: 5, left: 8, bottom: 10, right: 8)


    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupCollectionView()
        setupPlaces()
        setupButtons()
        
    }
    
    func setupCollectionView() {
        
        let placeNib = UINib(nibName: "PlaceCell", bundle: nil)
        collectionView.register(placeNib, forCellWithReuseIdentifier: reuseIdentifier)
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.isScrollEnabled = true
        searchButton.isEnabled = false
        self.dragDataDelegate = self
        
        setupCellWidth()
    }
    
    func setupButtons() {
        
        enlargeButton.addTarget(self, action: #selector(enlargePressed), for: .touchUpInside)
        
    }
    
    func setupPlaces() {
        
        let defaultPlaceGroups = Utils.defaultPlacesGroups()//[PlaceGroup(name: "places", places: [], kind: .none)]
        groups.append(contentsOf: defaultPlaceGroups)
        
    }
    
    func setupCellWidth() {
        self.cellWidth = collectionView.bounds.width - (sectionInsets.left + sectionInsets.right)
    }
    
    @IBAction func searchClicked(_ sender: Any) {
        presentAutocompleteController()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        // Present group creation VC
        if segue.identifier == "createGroup" {
            
            guard let groupCreationController = segue.destination as? GroupCreationViewController else { return }
            groupCreationController.delegate = self
            
        } else if segue.identifier == "addPlace" {
            
            guard let placeCreationController = segue.destination as? PlaceEditingViewController else { return }
            guard let place = placeToAdd else { return }
            placeCreationController.place = place
            placeCreationController.delegate = self
            
        }
        
    }
    
    @objc func enlargePressed(_ sender: Any) {
        delegate?.placePaletteViewController(self, didPressEdit: sender)
    }
    
}

extension PlacePaletteViewController: GroupCreationDelegate {
    
    func createGroup(name: String, kind: PlaceGroup.Kind) {
        
        collectionView.performBatchUpdates({
            
            let newGroup = PlaceGroup(name: name, places: [Place](), kind: kind)
            collectionView.insertSections(IndexSet(integer: groups.endIndex))
            groups.append(newGroup)
            
        }, completion: nil)
        
    }
    
    
}

extension PlacePaletteViewController: PlaceEditingDelegate {
    
    func finishedEditingPlace(_ editedPlace: Place) {
        collectionView.reloadData()
        delegate?.placePaletteViewController(self, didUpdatePlaces: groups)
    }
    
    @objc func tapEditPlace(_ sender: UIButton) {
        let sendingCell = sender.superview!.superview!.superview! as! UICollectionViewCell
        let indexPath = collectionView.indexPath(for: sendingCell)!
        placeToAdd = groups[indexPath.section][indexPath.item]
        performSegue(withIdentifier: "addPlace", sender: nil)
    }
    
    @objc func tapDeletePlace(_ sender: UIButton) {
        let sendingCell = sender.superview!.superview!.superview! as! UICollectionViewCell
        let indexPath = collectionView.indexPath(for: sendingCell)!
        groups[indexPath.section].remove(at: indexPath.item)
        collectionView.deleteItems(at: [indexPath])
    }
    
}

extension PlacePaletteViewController : UICollectionViewDelegateFlowLayout, UICollectionViewDelegate, UICollectionViewDataSource {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return groups.count
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        if let group = groups[safe: section] {
            return inEditingMode ? group.count + 1 : group.count // extra placeholder cell when in editing mode
        } else {
            return 0
        }
        
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! PlaceCell
        guard let group = groups[safe: indexPath.section] else { return cell }

        
        // Placeholder cell?
        if isPlaceholder(indexPath) {
            return placeholderCellFrom(cell)
        }
        
        // Dragging cell?
        if let draggingIndexPath = draggingIndexPath {
            if (indexPath == draggingIndexPath) {
                return draggingCellFrom(cell)
            }
        }
        
        // Otherwise
        let place = group[indexPath.item]
        return placeCellFrom(cell, place)
    }
    
    func placeholderCellFrom(_ cell: PlaceCell) -> PlaceCell {
        cell.contentView.alpha = 0.0
        cell.backgroundColor = .clear
        return cell
    }
    
    func draggingCellFrom(_ cell: PlaceCell) -> PlaceCell {
        cell.contentView.alpha = 0.0
        cell.backgroundColor = .clear
        return cell
    }
    
    func placeCellFrom(_ cell: PlaceCell, _ place: Place) -> PlaceCell {
        
        cell.contentView.alpha = 1.0
        cell.backgroundColor = .clear
        cell.configureWith(place)
        if (cell.gestureRecognizers == nil) || (cell.gestureRecognizers?.count == 0) {
            addDragRecognizerTo(draggable: cell)
        }
        cell.editBtn.alpha = inEditingMode ? 1 : 0
        cell.editBtn.addTarget(self, action: #selector(tapEditPlace(_:)), for: .touchUpInside)
        
        cell.deleteBtn.alpha = inEditingMode ? 1 : 0
        cell.deleteBtn.addTarget(self, action: #selector(tapDeletePlace(_:)), for: .touchUpInside)
        
        return cell
        
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return cellInsets
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        setupCellWidth()
        if isPlaceholder(indexPath) {
            return CGSize(width:cellWidth, height:cellHeight * 0.2)
        } else {
            return CGSize(width:cellWidth, height:cellHeight)
        }

    }
    
    func isPlaceholder(_ indexPath: IndexPath) -> Bool {
        return indexPath.item == groups[indexPath.section].count
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        
        if kind == UICollectionView.elementKindSectionHeader {
            guard let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind,
                                                                                   withReuseIdentifier: "groupHeader",
                                                                                   for: indexPath) as? GroupHeaderView else { fatalError("Invalid view type") }
            return sectionHeaderFrom(headerView, indexPath)
        }
            
        else {
            assert(false, "Invalid element type")
        }
    
    }
    
    func sectionHeaderFrom(_ headerView: GroupHeaderView, _ indexPath: IndexPath) -> GroupHeaderView {
        
        guard let group = groups[safe: indexPath.section] else { assert(false, "No group here") }
        headerView.label.text = group.name
        headerView.tag = indexPath.section
        headerView.gestureRecognizers?.forEach(headerView.removeGestureRecognizer)
        if !inEditingMode {
            addDragRecognizerTo(draggable: headerView)
        }
        return headerView
        
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        
        switch section {
        case 0:
            return CGSize(width: 0, height: 0)
        default:
            return CGSize(width: collectionView.frame.size.width, height: 40.0)
        }
        
    }
}

extension PlacePaletteViewController: DragDataDelegate {
    
    func objectFor(draggable: UIView) -> Any? {
        
        switch draggable {
            
        case is UICollectionViewCell:
            guard let indexPath = collectionView.indexPath(for: draggable as! UICollectionViewCell) else { return nil }
            
            let place = groups[indexPath.section][indexPath.item]
            return place
                
        case is UICollectionReusableView:
            return groups[safe: draggable.tag]
            
        default:
            return nil
        }

    }
    
    func indexPathFor(draggable: UIView) -> IndexPath? {
        
        switch draggable {
            
        case is UICollectionViewCell:
            guard let indexPath = collectionView.indexPath(for: draggable as! UICollectionViewCell) else { return nil }
            return indexPath
            
        case is UICollectionReusableView:
            return IndexPath(item: 0, section: draggable.tag)
            
        default:
            return nil
        }
        
    }
    
}

extension PlacePaletteViewController: DragDelegate {

    func draggableContentViewController( _ draggableContentViewController: DraggableContentViewController, didBeginDragging object: Any, at indexPath: IndexPath, withGesture gesture: UILongPressGestureRecognizer) {
        
        guard object as? Place != nil else { return }
        
        midDrag = false
        draggingIndexPath = indexPath
        groupsBeforeEditing = groups.map({ $0.copy() })
        groupsBeforeEditing[indexPath.section].remove(at: indexPath.item)
        
        collectionView.reloadData()
    }
    
    func draggableContentViewController( _ draggableContentViewController: DraggableContentViewController, didContinueDragging object: Any, at indexPath: IndexPath, withGesture gesture: UILongPressGestureRecognizer) {
        
        guard let place = object as? Place else { return }
        guard var insertAt = collectionView.indexPathForItem(at: gesture.location(in: collectionView)) else { return }
        guard groupsBeforeEditing.count > insertAt.section, groupsBeforeEditing[insertAt.section].count >= insertAt.item else { return }
        
        print(draggingIndexPath)
        
        if (!midDrag ){
            collectionView.performBatchUpdates({
                midDrag = true
                
                // if moving into an empty section, first delete the placeholder cell
//                let movingToEmptyGroup = (groups[insertAt.section].count == 0)
//                if movingToEmptyGroup { collectionView.deleteItems(at: [insertAt])}
//                print("moving to empty group: \(movingToEmptyGroup)")
                
                groups = groupsBeforeEditing.map({ $0.copy() })
                groups[insertAt.section].insert(place, at: insertAt.item)
                collectionView.moveItem(at: draggingIndexPath!, to: insertAt)
                draggingIndexPath = insertAt
                
                // if moving the only item out of the empty section, insert the placeholder cell
//                let emptyingGroup = (insertAt.section != indexPath.section) && (groups[indexPath.section].count == 0)
//                if emptyingGroup { collectionView.insertItems(at: [indexPath]) }
//                print("emptying group: \(emptyingGroup)")
                
            }, completion: { success in self.midDrag = false })
        }
    }
    
    func draggableContentViewController( _ draggableContentViewController: DraggableContentViewController, didEndDragging object: Any, at indexPath: IndexPath, withGesture gesture: UILongPressGestureRecognizer) {

        guard object as? Place != nil else { return }
        let reloadIndexPath = draggingIndexPath!
        draggingIndexPath = nil
        collectionView.reloadItems(at: [reloadIndexPath])
        
    }
    
    func cellForIndex(_ indexPath: IndexPath) -> UIView? {
        return nil
    }
    
    func setupPlaceholderView(from uiView: UIView) -> UIView? {
        guard let snapshot = uiView.snapshotView(afterScreenUpdates: false) else { return nil }
        
        snapshot.frame = uiView.frame
        snapshot.bounds = uiView.bounds
        collectionView.addSubview(snapshot)
        
        return snapshot
    }

}

// MARK: - Delegates for GMS Autocomplete

extension PlacePaletteViewController: GMSAutocompleteViewControllerDelegate {
    
    func presentAutocompleteController() {
        
        let autocompleteController = GMSAutocompleteViewController()
        autocompleteController.delegate = self
        
        // Filter autocomplete results to bias within current map region
        if let bounds = geographicSearchBounds {
            autocompleteController.autocompleteBounds = bounds
            autocompleteController.autocompleteBoundsMode = .bias
        }
        
        // Specify the place data types to return.
        let fields: GMSPlaceField = GMSPlaceField(rawValue:
            UInt(GMSPlaceField.coordinate.rawValue)
                | UInt(GMSPlaceField.placeID.rawValue)
                | UInt(GMSPlaceField.name.rawValue)
                | UInt(GMSPlaceField.openingHours.rawValue)
                | UInt(GMSPlaceField.formattedAddress.rawValue))!
        autocompleteController.placeFields = fields
        
        // Display the autocomplete view controller.
        present(autocompleteController, animated: true, completion: nil)
        
    }

    // Handle the user's selection.
    func viewController(_ viewController: GMSAutocompleteViewController, didAutocompleteWith place: GMSPlace) {
        let coordinate = Coordinate(lat: place.coordinate.latitude, lon: place.coordinate.longitude)
        let openTiming = openHoursTimingFromGMSOpeningHours(place.openingHours)
        let newPlace = Place(name: place.name!, coordinate: coordinate, placeID: place.placeID!, openHours: openTiming)
        groups[0].append(newPlace)
        collectionView.reloadData()
    }
    
    func openHoursTimingFromGMSOpeningHours(_ hours: GMSOpeningHours?) -> Timing? {
        
        // Check if no opening hours, or open 24hrs
        guard let hours = hours, let periods = hours.periods else { return nil }
        if periods.count == 1 {
            if periods[0].closeEvent == nil {
                return nil
            }
        }
        
        let today = Date()
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: today)
        
        var startTime = 0.0
        var endTime = 24.5
        
        // otherwise
        for period in periods {
            print(period.openEvent.day)
            print(period.openEvent.day.rawValue)
            if Int(period.openEvent.day.rawValue) == weekday {
                let openTime = period.openEvent.time
                startTime = TimeInterval.from(hours: Int(openTime.hour)) + TimeInterval.from(minutes: Int(openTime.minute))
            }
            if Int(period.closeEvent!.day.rawValue) == weekday {
                let closeTime = period.closeEvent!.time
                endTime = TimeInterval.from(hours: Int(closeTime.hour)) + TimeInterval.from(minutes: Int(closeTime.minute))
            }
        }
        
        if endTime < startTime {
            endTime = 24.5
        }
        
        return Timing(start: startTime, end: endTime)
    }
    
    func viewController(_ viewController: GMSAutocompleteViewController, didFailAutocompleteWithError error: Error) {
        print("Error: ", error.localizedDescription)
    }
    
    // User canceled the operation.
    func wasCancelled(_ viewController: GMSAutocompleteViewController) {
        dismiss(animated: true, completion: nil)
    }
    
    // Turn the network activity indicator on and off again.
    func didRequestAutocompletePredictions(_ viewController: GMSAutocompleteViewController) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
    }
    
    func didUpdateAutocompletePredictions(_ viewController: GMSAutocompleteViewController) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
    }
    
}

// MARK: - Protocols

protocol PlacePaletteViewControllerDelegate : AnyObject {
    
    func placePaletteViewController(_ placePaletteViewController: PlacePaletteViewController, didUpdatePlaces groups: [PlaceGroup])
    func placePaletteViewController(_ placePaletteViewController: PlacePaletteViewController, didPressEdit sender: Any)
    
}

