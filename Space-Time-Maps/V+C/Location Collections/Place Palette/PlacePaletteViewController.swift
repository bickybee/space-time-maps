//
//  PlacePaletteViewController.swift
//  Space-Time-Maps
//
//  Created by vicky on 2019-07-21.
//  Copyright © 2019 vicky. All rights reserved.
//

import UIKit
import GooglePlaces

private let reuseIdentifier = "locationCell"

class PlacePaletteViewController: DraggableContentViewController {
    
    // Delegates
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
    
    var groupsBeforeEditing = [PlaceGroup]()
    var midDrag = false
    var draggingIndexPath : IndexPath?
//    var draggingView : UIView?
    
    // CollectionView cell
    private let cellHeight : CGFloat = 50.0
    private var cellWidth : CGFloat!
    private let sectionInsets = UIEdgeInsets(top: 20.0, left: 10.0, bottom: 20.0, right: 10.0)


    override func viewDidLoad() {
        super.viewDidLoad()
        self.cellWidth = collectionView.frame.width - (sectionInsets.left + sectionInsets.right)
        collectionView.register(LocationCell.self, forCellWithReuseIdentifier: reuseIdentifier)
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.isScrollEnabled = true
        searchButton.isEnabled = false
        
        self.dragDataDelegate = self
        
        var places = [Place]()
        places.append(contentsOf: Utils.defaultPlaces())
        
        let defaultPlaceGroup = PlaceGroup(name: "", places: places, kind: .none)
        groups.append(defaultPlaceGroup)
        
    }
    
    @IBAction func searchClicked(_ sender: Any) {
        presentAutocompleteController()
    }
    
    @IBAction func groupClicked(_ sender: Any) {
        print("create group modal")
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "createGroup" {
            guard let groupCreationController = segue.destination as? GroupCreationViewController else { return }
            groupCreationController.delegate = self
        }
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

// MARK: - UICollectionView delegates
extension PlacePaletteViewController : UICollectionViewDelegateFlowLayout, UICollectionViewDelegate, UICollectionViewDataSource {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return groups.count
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if let group = groups[safe: section] {
            return inEditingMode ? group.places.count + 1 : group.places.count
        } else {
            return 0
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! LocationCell
        guard let group = groups[safe: indexPath.section] else { return cell }
        
        // Placeholder cell? (for empty sctions)
        if indexPath.item == group.places.endIndex {
            cell.contentView.alpha = 0.0
            cell.backgroundColor = .clear
            return cell
        }
        
        // Dragging cell?
        if let draggingIndexPath = draggingIndexPath {
            if (indexPath == draggingIndexPath) {
//                print(draggingIndexPath)
                cell.contentView.alpha = 0.0
                cell.backgroundColor = .clear
                return cell
            }
        }
        
        // Otherwise
        let place = group.places[indexPath.item]
        cell.contentView.alpha = 1.0
        cell.backgroundColor = .lightGray
        cell.nameLabel.text = place.name
        addDragRecognizerTo(draggable: cell)
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 5, left: 8, bottom: 10, right: 8)
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {

        return CGSize(width:self.cellWidth, height:self.cellHeight)

    }
    
    func collectionView(_ collectionView: UICollectionView,
                                 viewForSupplementaryElementOfKind kind: String,
                                 at indexPath: IndexPath) -> UICollectionReusableView {
        // 1
        switch kind {
        // 2
        case UICollectionView.elementKindSectionHeader:
            // 3
            guard
                let headerView = collectionView.dequeueReusableSupplementaryView(
                    ofKind: kind,
                    withReuseIdentifier: "groupHeader",
                    for: indexPath) as? GroupHeaderView
                else {
                    fatalError("Invalid view type")
            }
            
            guard let group = groups[safe: indexPath.section] else { assert(false, "No group here") }
            headerView.label.text = group.name
            headerView.tag = indexPath.section
            headerView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tapGroup)))
            addDragRecognizerTo(draggable: headerView)
            return headerView
        default:
            // 4
            assert(false, "Invalid element type")
        }
    
    }
    
    @objc func tapGroup(_ gesture: UITapGestureRecognizer) {
        print("tapped")
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        if section == 0 {
            return CGSize(width: 0, height: 0)
        } else {
            return CGSize(width: collectionView.frame.size.width, height: 40.0)
        }
    }
}

extension PlacePaletteViewController: DragDataDelegate {
    
    func objectFor(draggable: Draggable) -> Any? {
        if let draggableCell = draggable as? UICollectionViewCell,
            let indexPath = collectionView.indexPath(for: draggableCell),
            let place = groups[safe: indexPath.section]?.places[safe: indexPath.item] {
            
            return place
            
        } else if draggable as? UICollectionReusableView != nil {
            return groups[safe: draggable.tag]
        }

        return nil
    }
    
    func indexPathFor(draggable: Draggable) -> IndexPath? {
        if let draggableCell = draggable as? UICollectionViewCell,
            let indexPath = collectionView.indexPath(for: draggableCell) {
            return indexPath
        } else if draggable as? UICollectionReusableView != nil {
            return IndexPath(item: 0, section: draggable.tag)
        }
        
        return nil
    }
    
}

extension PlacePaletteViewController: DragDelegate {

    func draggableContentViewController( _ draggableContentViewController: DraggableContentViewController, didBeginDragging object: Any, at indexPath: IndexPath, withGesture gesture: UIPanGestureRecognizer) {
        guard object as? Place != nil else { return }
        midDrag = false
        draggingIndexPath = indexPath
//        draggingView = setupPlaceholderView(from: gesture.view!)
        groupsBeforeEditing = groups.map({ $0.copy() })
        groupsBeforeEditing[indexPath.section].places.remove(at: indexPath.item)
        collectionView.reloadData()
    }
    
    func draggableContentViewController( _ draggableContentViewController: DraggableContentViewController, didContinueDragging object: Any, at indexPath: IndexPath, withGesture gesture: UIPanGestureRecognizer) {
        guard let place = object as? Place else { return }
        guard var insertAt = collectionView.indexPathForItem(at: gesture.location(in: collectionView)) else { return }
        
//        draggingView!.center = gesture.location(in: view)
//        if groups[insertAt.section].places.count == 1 {
//            if groups[0].places[0].isPlaceholder() && insertAt.item == 1 {
//                insertAt = draggingIndexPath!
//            }
//        }
        
        guard groupsBeforeEditing.count > insertAt.section, groupsBeforeEditing[insertAt.section].places.count >= insertAt.item else { return }
        
        if (!midDrag ){
            collectionView.performBatchUpdates({
                midDrag = true
                groups = groupsBeforeEditing.map({ $0.copy() })
                groups[insertAt.section].places.insert(place, at: insertAt.item) // FIXME TODO DEBUG!!!
                collectionView.moveItem(at: draggingIndexPath!, to: insertAt)
                draggingIndexPath = insertAt
            }, completion: { success in self.midDrag = false })
        }
    }
    
    func draggableContentViewController( _ draggableContentViewController: DraggableContentViewController, didEndDragging object: Any, at indexPath: IndexPath, withGesture gesture: UIPanGestureRecognizer) {

        let reloadIndexPath = draggingIndexPath!
        draggingIndexPath = nil
        collectionView.reloadItems(at: [reloadIndexPath])
        
    }
    
    func cellForIndex(_ indexPath: IndexPath) -> Draggable? {
        return nil
    }
    
    func setupPlaceholderView(from uiView: UIView) -> UIView? {
        guard let snapshot = uiView.snapshotView(afterScreenUpdates: true) else { return nil }
        
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
                | UInt(GMSPlaceField.formattedAddress.rawValue))!
        autocompleteController.placeFields = fields
        
        // Display the autocomplete view controller.
        present(autocompleteController, animated: true, completion: nil)
        
    }
    
    // Handle the user's selection.
    func viewController(_ viewController: GMSAutocompleteViewController, didAutocompleteWith place: GMSPlace) {
        let coordinate = Coordinate(lat: place.coordinate.latitude, lon: place.coordinate.longitude)
        let newPlace = Place(name: place.name!, coordinate: coordinate, placeID: place.placeID!)
        groups[0].places.append(newPlace)
        collectionView.reloadData()
        delegate?.placePaletteViewController(self, didUpdatePlaces: groups)
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
    
}
