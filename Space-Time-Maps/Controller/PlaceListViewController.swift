//
//  SavedPlacesCollectionViewContsoller.swift
//  Space-Time-Maps
//
//  Created by vicky on 2019-07-18.
//  Copyright © 2019 vicky. All rights reserved.
//

import UIKit
import GooglePlaces

class PlaceListViewController: UICollectionViewController {
    
    private let reuseIdentifier = "placeCell"
    private let cellHeight : CGFloat = 200.0
    private let sectionInsets = UIEdgeInsets(top: 50.0, left: 20.0, bottom: 50.0, right: 20.0)
    
    var placeManager : PlaceManager!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.collectionView?.dragInteractionEnabled = true
        self.collectionView?.dragDelegate = self
        self.collectionView?.dropDelegate = self

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // MARK: Helper Functions
    
    func place(for indexPath: IndexPath) -> Place? {
        let allPlaces = placeManager.getPlaces()
        let index = indexPath.item
        return allPlaces.indices.contains(index) ? allPlaces[index] : nil
    }
    
    func placeName(for indexPath: IndexPath) -> String? {
        let place = self.place(for: indexPath)
        return place?.name
    }
    
    func removePlace(at indexPath: IndexPath) {
        self.placeManager.remove(at: indexPath.item)
    }
    
    func insertPlace(_ place: Place, at indexPath: IndexPath) {
        self.placeManager.insert(place, at: indexPath.item)
    }
    
    func updateCellsWithAnimation() {
        self.collectionView?.performBatchUpdates({
            let indexSet = IndexSet(integersIn: 0...0)
            self.collectionView?.reloadSections(indexSet)
        }, completion: nil)
    }
    
    @objc func deletePlace(sender: UIButton) {
        let index = sender.tag
        self.placeManager.remove(at: index)
        self.updateCellsWithAnimation()
    }

    // MARK: UICollectionViewDataSource

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.placeManager.getPlaces().count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! PlaceCell
        cell.backgroundColor = .yellow
        cell.nameLabel.text = placeName(for: indexPath)
        cell.deleteButton.tag = indexPath.item
        cell.deleteButton.addTarget(self, action: #selector(self.deletePlace), for: .touchUpInside)
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        var size = collectionView.bounds.size
        size.width -= (sectionInsets.left + sectionInsets.right)
        return CGSize(width:size.width, height:self.cellHeight)
    }

}

// MARK: - UICollectionViewDragDelegate
extension PlaceListViewController: UICollectionViewDragDelegate {
    func collectionView(_ collectionView: UICollectionView,
                        itemsForBeginning session: UIDragSession,
                        at indexPath: IndexPath) -> [UIDragItem] {
        if let place = self.place(for: indexPath) {
            let item = NSItemProvider(object: place as NSItemProviderWriting)
            let dragItem = UIDragItem(itemProvider: item)
            return [dragItem]
        } else {
            return []
        }
    }
}

// MARK: - UICollectionViewDropDelegate
extension PlaceListViewController: UICollectionViewDropDelegate {
    
    // Enable dropping
    func collectionView(_ collectionView: UICollectionView,
                        canHandle session: UIDropSession) -> Bool {
        return true
    }
    
    // What to do when a drop is performed?
    func collectionView(_ collectionView: UICollectionView,
                        performDropWith coordinator: UICollectionViewDropCoordinator) {

        guard let destinationIndexPath = coordinator.destinationIndexPath else {
            return
        }
        
        coordinator.items.forEach { dropItem in
            guard let sourceIndexPath = dropItem.sourceIndexPath else {
                return
            }
            
            collectionView.performBatchUpdates({
                let place = self.place(for: sourceIndexPath)
                removePlace(at: sourceIndexPath)
                insertPlace(place!, at: destinationIndexPath)
                collectionView.deleteItems(at: [sourceIndexPath])
                collectionView.insertItems(at: [destinationIndexPath])
            }, completion: { _ in
                coordinator.drop(dropItem.dragItem,
                                 toItemAt: destinationIndexPath)
            })
        }
    }
    
    func collectionView(
        _ collectionView: UICollectionView,
        dropSessionDidUpdate session: UIDropSession,
        withDestinationIndexPath destinationIndexPath: IndexPath?)
        -> UICollectionViewDropProposal {
            return UICollectionViewDropProposal(
                operation: .move,
                intent: .insertAtDestinationIndexPath)
    }
    
}

