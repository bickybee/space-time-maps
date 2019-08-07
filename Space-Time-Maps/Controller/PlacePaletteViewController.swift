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
    var placeholderDraggingPlaceCell : UIView?
    
    weak var delegate : PlacePaletteViewControllerDelegate?
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
        
        let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(didLongPress(gesture:)))
        collectionView.addGestureRecognizer(longPressRecognizer)
        makeSearchButton()
    }
    
    @objc func didLongPress(gesture: UILongPressGestureRecognizer) {
        
        let location = gesture.location(in: view)
        switch gesture.state {
        case .began:
            if let indexPath = collectionView.indexPathForItem(at: location) {
                if let place = places[safe: indexPath.item] {
                    longPressedPlace = place
                    print(place)
                    let cell = collectionView(collectionView, cellForItemAt: indexPath) as UIView
                    if let cellSnapshot = cell.snapshotView(afterScreenUpdates: true) {
                        placeholderDraggingPlaceCell = cellSnapshot
                        placeholderDraggingPlaceCell!.center = location
                        placeholderDraggingPlaceCell!.alpha = 0.5
                        view.addSubview(placeholderDraggingPlaceCell!)
                    }
                    delegate?.placePaletteViewController(self, didLongPress: gesture, onPlace: place)
                }
            }
        case .changed:
            if let placeholderCell = placeholderDraggingPlaceCell, let place = longPressedPlace {
                placeholderCell.center = location
                delegate?.placePaletteViewController(self, didLongPress: gesture, onPlace: place)
            }
            
        case .ended,
            .cancelled:
            if let placeholderCell = placeholderDraggingPlaceCell, let place = longPressedPlace{
                placeholderCell.removeFromSuperview()
                delegate?.placePaletteViewController(self, didLongPress: gesture, onPlace: place)
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
        let btnLaunchAc = UIButton(frame: CGRect(x: x, y: y, width: sideLength, height: sideLength))
        btnLaunchAc.backgroundColor = .blue
        btnLaunchAc.setTitle("search", for: .normal)
        btnLaunchAc.addTarget(self, action: #selector(searchClicked), for: .touchUpInside)
        self.view.addSubview(btnLaunchAc)
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
    func placePaletteViewController(_ placePaletteViewController: PlacePaletteViewController, didLongPress gesture: UILongPressGestureRecognizer, onPlace place: Place)
    
}

protocol PlaceCollectionDragDelegate : AnyObject {
    
    func placeCollectionViewController(_ collectionviewController: UICollectionViewController, didBeginDrag gesture: UIGestureRecognizer, place: Place)
    func placeCollectionViewController(_ collectionviewController: UICollectionViewController, didContinueDrag gesture: UIGestureRecognizer, place: Place)
    func placeCollectionViewController(_ collectionviewController: UICollectionViewController, didEndDrag gesture: UIGestureRecognizer, place: Place)
    
}

protocol PlaceCollectionDropDelegate : AnyObject {
    
    func placeCollectionViewController(_ collectionviewController: UICollectionViewController, didDrop gesture: UIGestureRecognizer, place: Place)
    
}
