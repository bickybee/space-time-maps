//
//  TimelineViewController.swift
//  Space-Time-Maps
//
//  Created by Vicky on 19/08/2019.
//  Copyright © 2019 vicky. All rights reserved.
//

import UIKit

class TimelineViewController: UIViewController {

    // Our view
    @IBOutlet weak var timelineView: TimelineView!
    
    var previousPanLocation : CGPoint?
    var panMultiplier: CGFloat = 1.0
    
    weak var delegate: TimelineViewDelegate?
        
    // Render variables
    var hourHeight : CGFloat {
        get {
            return timelineView.hourHeight
        } set (newVal) {
            timelineView.hourHeight = newVal
        }
    }
    var startHour : CGFloat {
        get {
            return timelineView.startHour
        } set (newVal) {
            timelineView.startHour = newVal
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTimelineView()
    }
    
    func setupTimelineView() {
        setCurrentTime()
        view.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(panTime)))
        view.addGestureRecognizer(UIPinchGestureRecognizer(target: self, action: #selector(pinchTime)))
    }
    
    func renderTimeline() {
        timelineView.setNeedsDisplay()
    }
    
    func setSidebarWidth( _ width: CGFloat) {
        timelineView.sidebarWidth = width
    }
    
    @objc func setCurrentTime() {
        guard let currentTime = Utils.currentTime() else { return }
        timelineView.currentHour = CGFloat(currentTime.inHours())
        let startAt = timelineView.currentHour - 1.0
        shiftTimeline(to: startAt)
        renderTimeline()
    }
    
    @objc func panTime(gesture: UIPanGestureRecognizer) {
        let location = gesture.location(in: view)
        
        switch gesture.state {
        case .began:
            previousPanLocation = location
        case .changed:
            guard let previousY = previousPanLocation?.y else { return }
            let dy = (previousY - location.y) * panMultiplier
            
            
            shiftTimeline(by: dy)
            
            previousPanLocation = location
            
        case .ended,
             .cancelled:
            previousPanLocation = nil
            
        default:
            break
        }
    }
    
    func shiftTimeline(by delta: CGFloat) {
        let newStartHour = startHour + (delta / hourHeight) // pan speed relative to hour height!
        shiftTimeline(to: newStartHour)
    }
    
    func shiftTimeline(to hour: CGFloat) {
        var newStartHour = hour
        let newEndHour = newStartHour + view.frame.height / hourHeight
        
        if newStartHour < 0 {
            newStartHour = startHour
        } else if newEndHour > 24.5 {
            newStartHour = startHour
        }
        
        startHour = newStartHour
        delegate?.timelineViewController(self, didUpdateStartHour: startHour)
        renderTimeline()
    }
    
    @objc func pinchTime(_ gestureRecognizer : UIPinchGestureRecognizer) {
        
        if gestureRecognizer.state == .began || gestureRecognizer.state == .changed {
            
            var newHourHeight = hourHeight * gestureRecognizer.scale
            let newEndHour = startHour + view.frame.height / newHourHeight
            if newEndHour > 24.5 {
                let newStartHour = 24.5 - view.frame.height / newHourHeight
                if newStartHour > 0 {
                    startHour = newStartHour
                } else {
                    newHourHeight = hourHeight
                }
            }
            hourHeight = newHourHeight
            gestureRecognizer.scale = 1.0
            
            delegate?.timelineViewController(self, didUpdateHourHeight: hourHeight)
            renderTimeline()
        }
    }
    
    func isTimelineWithinBounds(startHour: TimeInterval, hourHeight: CGFloat) {
        // TODO
    }

}

// For external access

extension TimelineViewController {
    
    public func hourInTimeline(forY y: CGFloat) -> Double {

        let relativeHour = y / hourHeight
        let absoluteHour = relativeHour + startHour
        
        return Double(absoluteHour)
    }
    
    public func roundedHourInTimeline(forY y: CGFloat) -> Double {

        let hour = hourInTimeline(forY: y)
        let roundedHour = Utils.ceilHour(hour)
        
        return roundedHour
    }
    
}

protocol TimelineViewDelegate : AnyObject {
    
    func timelineViewController(_ timelineViewController: TimelineViewController, didUpdateStartHour: CGFloat)
    func timelineViewController(_ timelineViewController: TimelineViewController, didUpdateHourHeight: CGFloat)
    
}
