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

class PlacePaletteViewController: UICollectionViewController {

    var geographicSearchBounds : GMSCoordinateBounds?
    var longPressedPlace : Place?
    var pressOffset : CGPoint?
    var placeholderDraggingPlaceCell : UIView?
    
    weak var delegate : PlacePaletteViewControllerDelegate?
    weak var dragDelegate : PlacePaletteViewControllerDragDelegate?
    
    //Data source!
    var places = [Place]() {
        didSet {
            collectionView.reloadData()
        }
    }
    
    private let cellHeight : CGFloat = 50.0
    private let sectionInsets = UIEdgeInsets(top: 20.0, left: 10.0, bottom: 20.0, right: 10.0)

    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.register(LocationCell.self, forCellWithReuseIdentifier: reuseIdentifier)
        
        makeSearchButton()
    }
    
    // TODO: fix offset btwn mouse and center
    @objc func didPress(gesture: UIGestureRecognizer) {
        
        let location = gesture.location(in: view)
        print(location)
        switch gesture.state {
        case .began:
            if let indexPath = collectionView.indexPathForItem(at: location) {
                if let place = places[safe: indexPath.item] {
                    longPressedPlace = place
                    print(place)
                    let cell = collectionView(collectionView, cellForItemAt: indexPath) as UIView
                    if let cellSnapshot = cell.snapshotView(afterScreenUpdates: true) {
                        pressOffset = CGPoint(x:location.x - cellSnapshot.center.x ,y:location.y - cellSnapshot.center.y)
                        placeholderDraggingPlaceCell = cellSnapshot
                        placeholderDraggingPlaceCell!.frame = cell.frame
                        placeholderDraggingPlaceCell!.alpha = 0.5
                        view.addSubview(placeholderDraggingPlaceCell!)
                        dragDelegate?.placePaletteViewController(self, didBeginDraggingPlace: longPressedPlace!, withPlaceholderView: placeholderDraggingPlaceCell!)
                    }
                }
            }
        case .changed:
            if let placeholderCell = placeholderDraggingPlaceCell, let place = longPressedPlace {
                placeholderCell.center = CGPoint(x:location.x, y:location.y)
                dragDelegate?.placePaletteViewController(self, didContinueDraggingPlace: place, withPlaceholderView: placeholderCell)
            }
            
        case .ended,
            .cancelled:
            if let placeholderCell = placeholderDraggingPlaceCell, let place = longPressedPlace{
                placeholderCell.removeFromSuperview()
                dragDelegate?.placePaletteViewController(self, didEndDraggingPlace: place, withPlaceholderView: placeholderCell)
            }
            placeholderDraggingPlaceCell = nil
            longPressedPlace = nil
        default:
            break
        }
        
    }
    
    // Search button for location autocomplete
    func makeSearchButton() {
        let sideLength : CGFloat = 65
        let x = self.view.bounds.size.width/2 - sideLength
        let y = self.view.bounds.size.height/2 - sideLength
        let btn = UIButton(frame: CGRect(x: x, y: y, width: sideLength, height: sideLength))
        btn.backgroundColor = .blue
        btn.setTitle("search", for: .normal)
        btn.addTarget(self, action: #selector(searchClicked), for: .touchUpInside)
        self.view.addSubview(btn)
    }
    
    // Present the Autocomplete view controller when button is pressed.
    @objc func searchClicked(_ sender: UIButton) {
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

}


// MARK: - UICollectionViewDelegateFlowLayout
extension PlacePaletteViewController : UICollectionViewDelegateFlowLayout {
    
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return places.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! LocationCell
        if let place = places[safe: indexPath.item] {
            cell.backgroundColor = .gray
            cell.nameLabel.text = place.name
            cell.nameLabel.backgroundColor = .white
            cell.nameLabel.sizeToFit()
            cell.nameLabel.center = cell.contentView.center
        }
        cell.dragHandle.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(didPress)))
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        var size = view.frame.size
        size.width -= (sectionInsets.left + sectionInsets.right)
        return CGSize(width:size.width, height:self.cellHeight)
    }
}

// MARK: - Delegates for GMS Autocomplete

extension PlacePaletteViewController: GMSAutocompleteViewControllerDelegate {
    
    // Handle the user's selection.
    func viewController(_ viewController: GMSAutocompleteViewController, didAutocompleteWith place: GMSPlace) {
        let coordinate = Coordinate(lat: place.coordinate.latitude, lon: place.coordinate.longitude)
        let newPlace = Place(name: place.name!, coordinate: coordinate, placeID: place.placeID!, isInItinerary: false)
        places.append(newPlace)
        delegate?.placePaletteViewController(self, didUpdatePlaces: places)
    }
    
    func viewController(_ viewController: GMSAutocompleteViewController, didFailAutocompleteWithError error: Error) {
        // TODO: handle the error.
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

protocol PlacePaletteViewControllerDelegate : AnyObject {
    
    func placePaletteViewController(_ placePaletteViewController: PlacePaletteViewController, didUpdatePlaces places: [Place])
    
}

protocol PlacePaletteViewControllerDragDelegate : AnyObject {
    
    func placePaletteViewController(_ placePaletteViewController: PlacePaletteViewController, didBeginDraggingPlace place: Place, withPlaceholderView view: UIView)
    func placePaletteViewController(_ placePaletteViewController: PlacePaletteViewController, didContinueDraggingPlace place: Place, withPlaceholderView view: UIView)
    func placePaletteViewController(_ placePaletteViewController: PlacePaletteViewController, didEndDraggingPlace place: Place, withPlaceholderView view: UIView)
    
}
