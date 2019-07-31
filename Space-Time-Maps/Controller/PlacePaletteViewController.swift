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
    
    var savedPlaces : PlaceManager!
    var didBeginDrag : ((_ place: Place) -> Void)? // Passed in from parent
    var geographicSearchBounds : GMSCoordinateBounds?
    
    private let cellHeight : CGFloat = 50.0
    private let sectionInsets = UIEdgeInsets(top: 20.0, left: 10.0, bottom: 20.0, right: 10.0)

    override func viewDidLoad() {
        super.viewDidLoad()
        self.collectionView?.register(LocationCell.self, forCellWithReuseIdentifier: reuseIdentifier)
        self.collectionView?.dragInteractionEnabled = true
        self.collectionView?.dragDelegate = self
        
        makeSearchButton()
    }
    
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

    // MARK: - UICollectionViewDelegate
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }


    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return savedPlaces.numPlaces()
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! LocationCell
        if let place = self.place(for: indexPath) {
            if place.isInItinerary() {
                cell.nameLabel.textColor = .gray
            }
            cell.backgroundColor = .gray
            cell.nameLabel.text = place.name
            cell.nameLabel.backgroundColor = .white
            cell.nameLabel.sizeToFit()
            cell.nameLabel.center = cell.contentView.center
        }
        return cell
    }
    
    // MARK - Helpers
    func place(for indexPath: IndexPath) -> Place? {
        let allPlaces = savedPlaces.getPlaces()
        let index = indexPath.item
        return allPlaces.indices.contains(index) ? allPlaces[index] : nil
    }
    
    func placeName(for indexPath: IndexPath) -> String? {
        let place = self.place(for: indexPath)
        return place?.name
    }

}


// MARK: - UICollectionViewDelegateFlowLayout
extension PlacePaletteViewController : UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        var size = view.frame.size
        size.width -= (sectionInsets.left + sectionInsets.right)
        return CGSize(width:size.width, height:self.cellHeight)
    }
}

// MARK: - UICollectionViewDragDelegate
extension PlacePaletteViewController: UICollectionViewDragDelegate {
    
    func collectionView(_ collectionView: UICollectionView,
                        itemsForBeginning session: UIDragSession,
                        at indexPath: IndexPath) -> [UIDragItem] {
        if let place = self.place(for: indexPath) {
            didBeginDrag?(place)
            let item = NSItemProvider(object: place as NSItemProviderWriting)
            let dragItem = UIDragItem(itemProvider: item)
            return [dragItem]
        } else {
            return []
        }
    }
    
}

// MARK: - Delegates for GMS Autocomplete

extension PlacePaletteViewController: GMSAutocompleteViewControllerDelegate {
    
    // Handle the user's selection.
    func viewController(_ viewController: GMSAutocompleteViewController, didAutocompleteWith place: GMSPlace) {
        let newPlace = Place(place.name!, place.placeID!, place.coordinate)
        self.savedPlaces?.add(newPlace)
        NotificationCenter.default.post(name: .didAddSavedPlace, object: self)
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

extension Notification.Name {
    static let didAddSavedPlace = Notification.Name("didAddSavedPlace")
}
