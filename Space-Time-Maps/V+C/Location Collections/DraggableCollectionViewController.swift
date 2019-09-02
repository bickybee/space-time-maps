//
//  DraggableCollectionViewController.swift
//  Space-Time-Maps
//
//  Created by Vicky on 14/08/2019.
//  Copyright © 2019 vicky. All rights reserved.
//

import UIKit

protocol Draggable: UIView {
    
    var dragHandle : UIView { get set }
    
}

// To work with DraggableCell class
class DraggableContentViewController: UIViewController, UIGestureRecognizerDelegate {
    
    // Dragging
    var draggingObject : Any?
    var draggingIndex : IndexPath?
    var draggable : Draggable?
    var draggingView : UIView?
    
    weak var dragDelegate : DragDelegate?
    weak var dragDataDelegate : DragDataDelegate?

    // UI consts
    let draggingViewInsets = CGPoint(x: 30, y: 8)

    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    func addDragRecognizerTo(draggable: Draggable) {
        
        let dragRecognizer = UIPanGestureRecognizer(target: self, action: #selector(dragObject))
        
        dragRecognizer.delegate = self
        draggable.dragHandle.addGestureRecognizer(dragRecognizer)
        
        
    }
    
    func gestureRecognizer(_: UIGestureRecognizer,
                           shouldRecognizeSimultaneouslyWith shouldRecognizeSimultaneouslyWithGestureRecognizer:UIGestureRecognizer) -> Bool {
        if shouldRecognizeSimultaneouslyWithGestureRecognizer as? UIPinchGestureRecognizer != nil {
            return true
        } else {
            return false
        }
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
        guard setupDraggableFrom(gesture: gesture),
              setupPlaceholderView(),
              setupDraggingObject(),
              setupDraggingIndex() else { return }
        
        // Ping delegate
        dragDelegate?.draggableContentViewController(self, didBeginDragging: draggingObject!, at: draggingIndex!, withGesture: gesture)
        
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
        dragDelegate?.draggableContentViewController(self, didContinueDragging: draggingObject!, at: draggingIndex!, withGesture: gesture)
    }
    
    func didEndDrag(_ gesture: UIPanGestureRecognizer) {
        
        // Ensures no nils
        guard isDraggingSessionSetup() else { return }
        
        // Ping delegate
        dragDelegate?.draggableContentViewController(self, didEndDragging: draggingObject!, at: draggingIndex!, withGesture: gesture)
        
        // Clean up dragging session
        draggingView!.removeFromSuperview()
        
        draggingView = nil
        draggable = nil
        draggingObject = nil
        draggingIndex = nil
        
    }
    
    func setupDraggableFrom(gesture: UIPanGestureRecognizer) -> Bool {
        
        // Traverse view hierarchy lol
        guard let handle = gesture.view,
              let originatingView = handle.superview,
              let draggableView = originatingView as? Draggable else { return false }

        // If we're good, set stuff accordingly
        draggable = draggableView
        
        return true
        
    }
    
    func setupPlaceholderView() -> Bool {
        guard let draggable = draggable,
              let cellSnapshot = draggable.snapshotView(afterScreenUpdates: true) else { return false }
    
        cellSnapshot.alpha = 0.6
        cellSnapshot.frame = draggable.frame
        cellSnapshot.bounds = draggable.bounds
        view.addSubview(cellSnapshot)
        
        draggingView = cellSnapshot
        
        return true
    }
    
    func setupDraggingObject() -> Bool {
        
        guard let draggable = draggable,
              let object = dragDataDelegate?.objectFor(draggable: draggable) else { return false }
        
        draggingObject = object
        
        return true
        
    }
    
    func setupDraggingIndex() -> Bool {
        
        guard let draggable = draggable,
              let index = dragDataDelegate?.indexPathFor(draggable: draggable) else { return false }
        
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
    
    var dragging : Bool { get set }
    
    func draggableContentViewController( _ draggableContentViewController: DraggableContentViewController, didBeginDragging object: Any, at indexPath: IndexPath, withGesture gesture: UIPanGestureRecognizer)
    func draggableContentViewController( _ draggableContentViewController: DraggableContentViewController, didContinueDragging object: Any, at indexPath: IndexPath, withGesture gesture: UIPanGestureRecognizer)
    func draggableContentViewController( _ draggableContentViewController: DraggableContentViewController, didEndDragging object: Any, at indexPath: IndexPath, withGesture gesture: UIPanGestureRecognizer)
    func cellForIndex(_ indexPath: IndexPath) -> Draggable?
}

// Get object associated with dragging cell from the delegate
protocol DragDataDelegate : AnyObject {
    
    func indexPathFor(draggable: Draggable) -> IndexPath?
    func objectFor(draggable: Draggable) -> Any?
    
}


