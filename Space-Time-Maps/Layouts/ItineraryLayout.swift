//
//  ItineraryLayout.swift
//  Space-Time-Maps
//
//  Created by Vicky on 09/08/2019.
//  Copyright © 2019 vicky. All rights reserved.
//

import UIKit

class ItineraryLayout: UICollectionViewLayout {
    
    weak var delegate: ItineraryLayoutDelegate!

    fileprivate var cellPadding: CGFloat = 6
    fileprivate var cache = [UICollectionViewLayoutAttributes]()
    fileprivate var contentHeight: CGFloat = 0
    
    fileprivate var contentWidth: CGFloat {
        guard let collectionView = collectionView else { return 0 }
        let insets = collectionView.contentInset
        return collectionView.bounds.width - (insets.left + insets.right)
    }
    
    override var collectionViewContentSize: CGSize {
        return CGSize(width: contentWidth, height:contentHeight)
    }
    
    override func prepare() {
        guard let collectionView = collectionView else { return }
        
        for item in 0 ..< collectionView.numberOfItems(inSection: 0) {
            let indexPath = IndexPath(item: item, section:0)
            let startHour = delegate.collectionView(collectionView, startTimeForDestinationAtIndexPath: indexPath)
            let hourHeight = delegate.hourHeight(of: collectionView)
            
            let y = CGFloat(startHour) * hourHeight
            let x: CGFloat = 0
            let width = contentWidth
            let height = 2 * hourHeight
            let frame = CGRect(x: x, y: y, width: width, height: height)
            
            let attributes = UICollectionViewLayoutAttributes(forCellWith: indexPath)
            attributes.frame = frame
            cache.append(attributes)
            
            contentHeight = max(contentHeight, frame.maxY)
            
        }
    }
    
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        
        var visibleLayoutAttributes = [UICollectionViewLayoutAttributes]()
        
        // Loop through the cache and look for items in the rect
        for attributes in cache {
            if attributes.frame.intersects(rect) {
                visibleLayoutAttributes.append(attributes)
            }
        }
        return visibleLayoutAttributes
    }
    
    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        return cache[indexPath.item]
    }
    
}

protocol ItineraryLayoutDelegate: AnyObject {
    func numberOfHours(of collectionView: UICollectionView) -> Int // Will give dateInterval later
    func hourHeight(of collectionView: UICollectionView) -> CGFloat
    func collectionView(_ collectionView:UICollectionView, startTimeForDestinationAtIndexPath indexPath: IndexPath) -> Int
}
