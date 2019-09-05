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

    fileprivate var cache = [UICollectionViewLayoutAttributes]()
    fileprivate var contentHeight: CGFloat = 0
    
    fileprivate var contentWidth: CGFloat {
        guard let collectionView = collectionView else { return 0 }
        return collectionView.bounds.width
    }
    
    override var collectionViewContentSize: CGSize {
        return CGSize(width: contentWidth, height:contentHeight)
    }
    
    override func prepare() {
        super.prepare()
        cache.removeAll()
        
        guard let collectionView = collectionView else { return }
        
        for section in 0 ... collectionView.numberOfSections - 1 {
            for item in 0 ..< collectionView.numberOfItems(inSection: section) {
                let indexPath = IndexPath(item: item, section: section)
                cacheAttributesForCellAt(indexPath: indexPath, in: collectionView)
            }
        }
    }
    
    func cacheAttributesForCellAt(indexPath: IndexPath, in collectionView: UICollectionView) {
        
        // Get data from delegate
        let timelineStartHour = delegate.timelineStartHour(of: collectionView)
        let eventTiming = delegate.collectionView(collectionView, timingForEventAtIndexPath: indexPath)
        let hourHeight = delegate.hourHeight(of: collectionView)
        
        let startHour = eventTiming.start.inHours()
        let duration = eventTiming.duration.inHours()

        if indexPath.section == 2 {
            
            let width = contentWidth
            let height = CGFloat(duration) * hourHeight + 40
            let relativeHour = CGFloat(startHour) - timelineStartHour
            let y = relativeHour * hourHeight - 25// - startOffset
            let x : CGFloat = 0.0
            let frame = CGRect(x: x, y: y, width: width, height: height)
            
            // Add to cache
            let attributes = UICollectionViewLayoutAttributes(forCellWith: indexPath)
            attributes.frame = frame
            attributes.zIndex = -1
            cache.append(attributes)
            // Update content height
            contentHeight = max(contentHeight, frame.maxY)
            
        } else {
            
            let width = contentWidth * 0.7
            let height = CGFloat(duration) * hourHeight
            let relativeHour = CGFloat(startHour) - timelineStartHour
            let y = relativeHour * hourHeight// - startOffset
            let x = contentWidth * 0.15
            let frame = CGRect(x: x, y: y, width: width, height: height)
            
            // Add to cache
            let attributes = UICollectionViewLayoutAttributes(forCellWith: indexPath)
            attributes.frame = frame
            cache.append(attributes)
            // Update content height
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
        return cache.first(where: { $0.indexPath == indexPath })
    }
    
}

protocol ItineraryLayoutDelegate: AnyObject {
    func timelineStartHour(of collectionView: UICollectionView) -> CGFloat
    func hourHeight(of collectionView: UICollectionView) -> CGFloat
    func collectionView(_ collectionView:UICollectionView, timingForEventAtIndexPath indexPath: IndexPath) -> Timing
}
