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

class PlacePaletteViewController: DraggableCellViewController {
    
    // Delegates
    weak var delegate : PlacePaletteViewControllerDelegate?
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var searchButton: UIButton!
    
    
    // For autocomplete search
    var geographicSearchBounds : GMSCoordinateBounds?
    
    // Data source
    var places = [Place]() {
        didSet {
            collectionView.reloadData()
        }
    }
    
    // CollectionView cell
    private let cellHeight : CGFloat = 50.0
    private let sectionInsets = UIEdgeInsets(top: 20.0, left: 10.0, bottom: 20.0, right: 10.0)


    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.register(LocationCell.self, forCellWithReuseIdentifier: reuseIdentifier)
        collectionView.delegate = self
        collectionView.dataSource = self
        
        self.dragDataDelegate = self
        
        places.append(contentsOf: Utils.defaultPlaces())
        
    }
    
    @IBAction func searchClicked(_ sender: Any) {
        presentAutocompleteController()
    }

    
}

// MARK: - UICollectionView delegates
extension PlacePaletteViewController : UICollectionViewDelegateFlowLayout, UICollectionViewDelegate, UICollectionViewDataSource {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return places.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! LocationCell
        
        guard let place = places[safe: indexPath.item] else { return cell }
        cell.backgroundColor = .gray
        cell.nameLabel.text = place.name
        addDragRecognizerTo(cell: cell)
        
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

extension PlacePaletteViewController: DragDataDelegate {
    
    func objectFor(draggableCell: DraggableCell) -> AnyObject? {
        guard let indexPath = collectionView.indexPath(for: draggableCell),
              let place = places[safe: indexPath.item] else { return nil }
        
        return place
    }
    
    func indexFor(draggableCell: DraggableCell) -> Int? {
        guard let indexPath = collectionView.indexPath(for: draggableCell) else { return nil}
        return indexPath.item
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
        let newPlace = Place(name: place.name!, coordinate: coordinate, placeID: place.placeID!, isInItinerary: false)
        places.append(newPlace)
        print(newPlace)
        delegate?.placePaletteViewController(self, didUpdatePlaces: places)
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
    
    func placePaletteViewController(_ placePaletteViewController: PlacePaletteViewController, didUpdatePlaces places: [Place])
    
}
