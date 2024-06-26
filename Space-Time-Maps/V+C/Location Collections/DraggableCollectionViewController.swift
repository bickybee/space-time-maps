//
//  DraggableCollectionViewController.swift
//  Space-Time-Maps
//
//  Created by Vicky on 14/08/2019.
//  Copyright © 2019 vicky. All rights reserved.
//

import UIKit

// To work with DraggableCell class
class DraggableContentViewController: UIViewController, UIGestureRecognizerDelegate {
    
    var showDraggingView = true
    
    // Dragging
    var draggingObject : Any?
    var draggingIndex : IndexPath?
    var draggable : UIView?
    var draggingView : UIView?
    var diff : CGPoint?
    
    weak var dragDelegate : DragDelegate?
    weak var dragDataDelegate : DragDataDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    func addDragRecognizerTo(draggable: UIView) -> UILongPressGestureRecognizer {
        
        let dragRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(dragObject))
        dragRecognizer.minimumPressDuration = 0.2
        dragRecognizer.delegate = self
        draggable.addGestureRecognizer(dragRecognizer)
        return dragRecognizer
        
    }
    
    func gestureRecognizer(_: UIGestureRecognizer,
                           shouldRecognizeSimultaneouslyWith shouldRecognizeSimultaneouslyWithGestureRecognizer:UIGestureRecognizer) -> Bool {
        if shouldRecognizeSimultaneouslyWithGestureRecognizer as? UIPinchGestureRecognizer != nil {
            return true
        } else if shouldRecognizeSimultaneouslyWithGestureRecognizer as? UITapGestureRecognizer != nil {
            return false
        } else if shouldRecognizeSimultaneouslyWithGestureRecognizer as? UISwipeGestureRecognizer != nil {
        return true
        }
        else {
            return false
        }
    }
    
    
    @objc func dragObject(_ gesture: UILongPressGestureRecognizer) {
        
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
    
    func didBeginDrag(_ gesture: UILongPressGestureRecognizer) {
        
        // Set up session
        guard setupDraggableFrom(gesture: gesture),
              setupPlaceholderView(),
              setupDraggingObject(),
              setupDraggingIndex() else { return }
        
        // Ping delegate
        NotificationCenter.default.post(name: .didStartContentDrag, object: draggingObject!)
        dragDelegate?.draggableContentViewController(self, didBeginDragging: draggingObject!, at: draggingIndex!, withGesture: gesture)
        
    }
    
    func didContinueDrag(_ gesture: UILongPressGestureRecognizer) {
        
        // Ensures no nils
        guard isDraggingSessionSetup() else { return }
        
        // Translate cell
        let location = gesture.location(in: view)
        let dx = location.x + diff!.x
        let dy = location.y + diff!.y
        draggingView!.center = CGPoint(x: dx, y: dy)
        // Ping delegate
        NotificationCenter.default.post(name: .didContinueContentDrag, object: draggingObject!)
        dragDelegate?.draggableContentViewController(self, didContinueDragging: draggingObject!, at: draggingIndex!, withGesture: gesture, andDiff: diff!)
    }
    
    func didEndDrag(_ gesture: UILongPressGestureRecognizer) {
        
        // Ensures no nils
        guard isDraggingSessionSetup() else { return }
        
        // Ping delegate
        NotificationCenter.default.post(name: .didEndContentDrag, object: draggingObject!)
        dragDelegate?.draggableContentViewController(self, didEndDragging: draggingObject!, at: draggingIndex!, withGesture: gesture)
        
        // Clean up dragging session
        if showDraggingView { draggingView!.removeFromSuperview() }
        
        draggingView = nil
        draggable = nil
        draggingObject = nil
        draggingIndex = nil
        
    }
    
    func setupDraggableFrom(gesture: UILongPressGestureRecognizer) -> Bool {
        
        // Traverse view hierarchy lol
        guard let draggableView = gesture.view else { return false }

        // If we're good, set stuff accordingly
        let touch = gesture.location(in:draggableView)
        diff = CGPoint(x: (draggableView.bounds.width / 2.0) - touch.x, y: (draggableView.bounds.height / 2.0) - touch.y)
        draggable = draggableView
        
        return true
        
    }
    
    func setupPlaceholderView() -> Bool {
        guard let draggable = draggable,
              let cellSnapshot = draggable.snapshotView(afterScreenUpdates: true) else { return false }
    
        cellSnapshot.alpha = 0.6
        cellSnapshot.frame = draggable.frame
        cellSnapshot.bounds = draggable.bounds
        if showDraggingView { view.addSubview(cellSnapshot) }
        
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
        
    func draggableContentViewController( _ draggableContentViewController: DraggableContentViewController, didBeginDragging object: Any, at indexPath: IndexPath, withGesture gesture: UILongPressGestureRecognizer)
    func draggableContentViewController( _ draggableContentViewController: DraggableContentViewController, didContinueDragging object: Any, at indexPath: IndexPath, withGesture gesture: UILongPressGestureRecognizer, andDiff diff: CGPoint)
    func draggableContentViewController( _ draggableContentViewController: DraggableContentViewController, didEndDragging object: Any, at indexPath: IndexPath, withGesture gesture: UILongPressGestureRecognizer)
    func cellForIndex(_ indexPath: IndexPath) -> UIView?
}

// Get object associated with dragging cell from the delegate
protocol DragDataDelegate : AnyObject {
    
    func indexPathFor(draggable: UIView) -> IndexPath?
    func objectFor(draggable: UIView) -> Any?
    
}

extension Notification.Name {
    
    static let didStartContentDrag = Notification.Name("didStartContentDrag")
    static let didContinueContentDrag = Notification.Name("didContinueContentDrag")
    static let didEndContentDrag = Notification.Name("didEndContentDrag")
    
}

