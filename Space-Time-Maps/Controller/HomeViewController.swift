//
//  ViewController.swift
//  Space-Time-Maps
//
//  Created by vicky on 2019-06-29.
//  Copyright © 2019 vicky. All rights reserved.
//
import UIKit
import GooglePlaces
import GoogleMaps

class HomeViewController: UIViewController {
    
    // GMS location search autocomplete
    var resultsViewController: GMSAutocompleteResultsViewController?
    var searchController: UISearchController?
    var resultView: UITextView?
    
    // Google Maps stuff
    var placesClient: GMSPlacesClient!
    var mapView : GMSMapView!
    let defaultLocation = CLLocation(latitude: 43.6532, longitude: -79.3832) // Toronto
    let defaultZoom: Float = 13.0
    
    // User-saved stuff
    var placeManager : PlaceManager!
    var itineraryManager : ItineraryManager!
    
    // Query service for making API calls
    var queryService: QueryService!
    
    // Map mark-up
    var mapViewController : MapViewController!
    var polylines: [String] = []
    var markers: [GMSMarker] = []
    
    @IBOutlet weak var placeInfoView: PlaceInfo!
    var currentPlaceInfo : Place?
    
    // MARK: - Overrides for UIViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Initialize Places client
        self.placesClient = GMSPlacesClient.shared()
        
        // Initializze map
        mapViewController = MapViewController()
        self.addChild(mapViewController)
        mapViewController.view.frame = self.view.bounds
        self.view.addSubview(mapViewController.view)
        
        // Hide info view initially
        placeInfoView.isHidden = true
        placeInfoView.deleteButton.addTarget(self, action: #selector(removePlace), for: .touchUpInside)
        
        // Make buttons
        makeSearchButton()
        makeRouteButton()
        makeListButton()
        makePlanButton()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        // Load any existing locations or routes
         refreshMapMarkup()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let savedPlacesVC = segue.destination as? PlaceListViewController {
            savedPlacesVC.placeManager = self.placeManager
        }
        else if let plannerVC = segue.destination as? PlannerViewController {
            plannerVC.placeManager = self.placeManager
            plannerVC.itineraryManager = self.itineraryManager
        }
    }
    
    // MARK: - Custom functions for clicks & place/route data
    
    func refreshMapMarkup() {
        self.mapViewController.clearMap()
//        self.mapViewController.displayPlaces(placeManager.getPlaces())
//        self.mapViewController.displayRoutes(self.polylines)
    }

    @objc func removePlace(_ sender: Any) {
        dismissPlaceInfoView()
        if let currentPlace = self.currentPlaceInfo {
            self.placeManager.remove(name: currentPlace.name)
            refreshMapMarkup()
        }
    }
    
    // Present the Autocomplete view controller when button is pressed.
    @objc func searchClicked(_ sender: UIButton) {
        let autocompleteController = GMSAutocompleteViewController()
        autocompleteController.delegate = self
        
        // Filter autocomplete results to bias within current map region
        let visibleRegion = mapViewController.mapView.projection.visibleRegion()
        let bounds = GMSCoordinateBounds(coordinate: visibleRegion.farLeft, coordinate: visibleRegion.nearRight)
        autocompleteController.autocompleteBounds = bounds
        autocompleteController.autocompleteBoundsMode = .bias
        
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
    
    // Add path
    func addPath(_ route: Route?) {
        if let route = route{
            self.polylines.append(route.polyline)
        }
    }
    
    // Get polyline for route between given places in given order
    @objc func routeClicked(_sender: UIButton) {
        if let places = self.placeManager?.getPlaces() {
            if places.count >= 2 {
                for i in 0...(places.count - 2) {
                    let fromPlaceID = places[i].placeID
                    let toPlaceID = places[i+1].placeID
                    self.queryService?.getRoute(fromPlaceID, toPlaceID, nil, TravelMode.driving, self.addPath)
                }
            }
        }
    }
    
    @objc func showList(_sender: UIButton) {
        performSegue(withIdentifier: "savedPlacesList", sender: _sender)
    }
    
    @objc func showPlanner(_sender: UIButton) {
        performSegue(withIdentifier: "planner", sender: _sender)
    }
    
    func showPlaceInfoView() {
    
        if let currentPlace = self.currentPlaceInfo {
            // Set place info view data to match tapped marker
            self.placeInfoView.nameLabel.text = currentPlace.name
            self.view.bringSubviewToFront(self.placeInfoView)
            
            // Display place info view if not already displayed
            if self.placeInfoView.isHidden {
                if let window = UIApplication.shared.keyWindow {
                    
                    let height = self.placeInfoView.frame.height
                    let y = window.frame.height - height
                    
                    // Start below the screen
                    self.placeInfoView.frame = CGRect(x: 0, y: window.frame.height, width: window.frame.width, height: height)
                    self.placeInfoView.isHidden = false
                    
                    // Animate upwards
                    UIView.animate(withDuration: 0.5) {
                        self.placeInfoView.frame = CGRect(x: 0, y: y, width: self.placeInfoView.frame.width, height: height)
                    }
                }
            }
        }
    }
    
    func dismissPlaceInfoView() {
        // Dismiss place info view if it's showing
        if !self.placeInfoView.isHidden {
            if let window = UIApplication.shared.keyWindow {
                // Animate downwards
                UIView.animate(withDuration: 0.5, animations: {
                    self.placeInfoView.frame = CGRect(x: 0, y: window.frame.height, width: window.frame.width, height: self.placeInfoView.frame.height)
                }, completion: { (completed: Bool) in
                    self.placeInfoView.isHidden = completed
                })
            }
        }
    }
    
    // MARK: - Make buttons
    
    func makeSearchButton() {
        let btnLaunchAc = UIButton(frame: CGRect(x: 0, y: 0, width: 85, height: 85))
        btnLaunchAc.backgroundColor = .blue
        btnLaunchAc.setTitle("SEARCH", for: .normal)
        btnLaunchAc.addTarget(self, action: #selector(searchClicked), for: .touchUpInside)
        self.view.addSubview(btnLaunchAc)
    }
    
    func makeRouteButton() {
        let btnLaunchAc = UIButton(frame: CGRect(x: 0, y: 85, width: 85, height: 85))
        btnLaunchAc.backgroundColor = .red
        btnLaunchAc.setTitle("GO", for: .normal)
        btnLaunchAc.addTarget(self, action: #selector(routeClicked), for: .touchUpInside)
        self.view.addSubview(btnLaunchAc)
    }
    
    func makeListButton() {
        let btnLaunchAc = UIButton(frame: CGRect(x: view.frame.size.width - 85, y: view.frame.size.height - 85, width: 85, height: 85))
        btnLaunchAc.backgroundColor = .green
        btnLaunchAc.setTitle("LIST", for: .normal)
        btnLaunchAc.addTarget(self, action: #selector(showList), for: .touchUpInside)
        self.view.addSubview(btnLaunchAc)
    }
    
    // TODO: - Plan pageeee
    func makePlanButton() {
        let btnLaunchAc = UIButton(frame: CGRect(x: view.frame.size.width - 85, y: view.frame.size.height - 170, width: 85, height: 85))
        btnLaunchAc.backgroundColor = .yellow
        btnLaunchAc.setTitle("PLAN", for: .normal)
        btnLaunchAc.addTarget(self, action: #selector(showPlanner), for: .touchUpInside)
        self.view.addSubview(btnLaunchAc)
    }
}

// MARK: - Delegates for MapView

extension HomeViewController: GMSMapViewDelegate {
    
    func mapView(_ mapView: GMSMapView, didTap marker: GMSMarker) -> Bool {
        if let place = self.placeManager.placeAtCoordinate(Coordinate(marker.layer.latitude, marker.layer.longitude)) {
            self.currentPlaceInfo = place
            showPlaceInfoView()
            return true
        }
        return false
    }
    
    func mapView(_ mapView: GMSMapView, didTapAt coordinate: CLLocationCoordinate2D) {
        self.currentPlaceInfo = nil
        dismissPlaceInfoView()
    }
    
}

// MARK: - Delegates for GMS Autocomplete

extension HomeViewController: GMSAutocompleteViewControllerDelegate {
    
    // Handle the user's selection.
    func viewController(_ viewController: GMSAutocompleteViewController, didAutocompleteWith place: GMSPlace) {
        let newPlace = Place(place.name!, place.placeID!, place.coordinate)
        self.placeManager?.add(newPlace)
        refreshMapMarkup()
        print(newPlace)
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
