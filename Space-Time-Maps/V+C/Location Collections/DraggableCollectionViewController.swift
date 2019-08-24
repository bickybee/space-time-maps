//
//  DraggableCollectionViewController.swift
//  Space-Time-Maps
//
//  Created by Vicky on 14/08/2019.
//  Copyright © 2019 vicky. All rights reserved.
//

import UIKit

// To work with DraggableCell class
class DraggableCellViewController: UIViewController {
    
    // Dragging
    var draggingObject : AnyObject?
    var draggingIndex : IndexPath?
    var draggingCell : DraggableCell?
    var draggingView : UIView?
    
    weak var dragDelegate : DragDelegate?
    weak var dragDataDelegate : DragDataDelegate?

    // UI consts
    let draggingViewInsets = CGPoint(x: 30, y: 8)

    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    func addDragRecognizerTo(cell: DraggableCell) {
        
        let dragRecognizer = UIPanGestureRecognizer(target: self, action: #selector(dragObject))
        cell.dragHandle.addGestureRecognizer(dragRecognizer)
        
    }
    
    @objc func dragObject(_ gesture: UIPanGestureRecognizer) {
        
        switch gesture.state {
        case .began:
            didBeginDrag(gesture)
        
        case .changed:
            didContinueDrag(gesture)
            
        case .ended,
             .cancelled:
            didEndDrag(gesture)
            
        default:
            break
        }

    }
    
    func didBeginDrag(_ gesture: UIPanGestureRecognizer) {
        
        // Set up session
        guard setupDraggableCellFrom(gesture: gesture),
              setupPlaceholderView(),
              setupDraggingObject(),
              setupDraggingIndex() else { return }
        
        // Ping delegate
        dragDelegate?.draggableCellViewController(self, didBeginDragging: draggingObject!, at: draggingIndex!, withGesture: gesture)
        
    }
    
    func didContinueDrag(_ gesture: UIPanGestureRecognizer) {
        
        // Ensures no nils
        guard isDraggingSessionSetup() else { return }
        
        // Translate cell
        let location = gesture.location(in: view)
        let dx = location.x
        let dy = location.y
        draggingView!.center = CGPoint(x: dx, y: dy)
        
        // Ping delegate
        dragDelegate?.draggableCellViewController(self, didContinueDragging: draggingObject!, at: draggingIndex!, withGesture: gesture)
    }
    
    func didEndDrag(_ gesture: UIPanGestureRecognizer) {
        
        // Ensures no nils
        guard isDraggingSessionSetup() else { return }
        
        // Ping delegate
        dragDelegate?.draggableCellViewController(self, didEndDragging: draggingObject!, at: draggingIndex!, withGesture: gesture)
        
        // Clean up dragging session
        draggingView!.removeFromSuperview()
        
        draggingView = nil
        draggingCell = nil
        draggingObject = nil
        draggingIndex = nil
        
    }
    
    func setupDraggableCellFrom(gesture: UIPanGestureRecognizer) -> Bool {
        
        // Traverse view hierarchy lol
        guard let handle = gesture.view,
              let contentView = handle.superview,
              let originatingCell = contentView.superview,
              let draggableCell = originatingCell as? DraggableCell else { return false }

        // If we're good, set stuff accordingly
        draggingCell = draggableCell
        
        return true
        
    }
    
    func setupPlaceholderView() -> Bool {
        guard let draggingCell = draggingCell,
              let cellSnapshot = draggingCell.snapshotView(afterScreenUpdates: true) else { return false }
    
        view.addSubview(cellSnapshot)
        
        draggingView = cellSnapshot
        
        return true
    }
    
    func setupDraggingObject() -> Bool {
        
        guard let draggingCell = draggingCell,
              let object = dragDataDelegate?.objectFor(draggableCell: draggingCell) else { return false }
        
        draggingObject = object
        
        return true
        
    }
    
    func setupDraggingIndex() -> Bool {
        
        guard let draggingCell = draggingCell,
              let index = dragDataDelegate?.indexPathFor(draggableCell: draggingCell) else { return false }
        
        draggingIndex = index
        
        return true
        
    }
    
    func isDraggingSessionSetup() -> Bool {
        
        guard draggingView != nil,
              draggingObject != nil,
              draggingIndex != nil else { return false }
        
        return true
        
    }

}

// Let delegate handle any further actions associated with dragging the cell
protocol DragDelegate : AnyObject {
    
    func draggableCellViewController( _ draggableCellViewController: DraggableCellViewController, didBeginDragging object: AnyObject, at indexPath: IndexPath, withGesture gesture: UIPanGestureRecognizer)
    func draggableCellViewController( _ draggableCellViewController: DraggableCellViewController, didContinueDragging object: AnyObject, at indexPath: IndexPath, withGesture gesture: UIPanGestureRecognizer)
    func draggableCellViewController( _ draggableCellViewController: DraggableCellViewController, didEndDragging object: AnyObject, at indexPath: IndexPath, withGesture gesture: UIPanGestureRecognizer)
    func cellForIndex(_ indexPath: IndexPath) -> DraggableCell?
}

// Get object associated with dragging cell from the delegate
protocol DragDataDelegate : AnyObject {
    
    func indexPathFor(draggableCell: DraggableCell) -> IndexPath?
    func objectFor(draggableCell: DraggableCell) -> AnyObject?
    
}


