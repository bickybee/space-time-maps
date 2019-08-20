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
    
    var roundHourTo = 0.25
    
    // Render variables
    var hourHeight : CGFloat = 50.0
    var startHour : CGFloat = 0.0
    
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
        timelineView.startHour = startHour
        timelineView.hourHeight = hourHeight
        timelineView.setNeedsDisplay()
    }
    
    func setSidebarWidth( _ width: CGFloat) {
        timelineView.sidebarWidth = width
    }
    
    @objc func setCurrentTime() {
        guard let currentTime = Utils.currentTime() else { return }
        timelineView.currentHour = CGFloat(currentTime.inHours())
        renderTimeline()
    }
    
    @objc func panTime(gesture: UIPanGestureRecognizer) {
        let location = gesture.location(in: view)
        
        switch gesture.state {
        case .began:
            previousPanLocation = location
        case .changed:
            guard let previousY = previousPanLocation?.y else { return }
            let dy = location.y - previousY
            
            var newStartHour = startHour - (dy / hourHeight) * panMultiplier // pan speed relative to hour height!
            let newEndHour = newStartHour + view.frame.height / hourHeight
            
            if newStartHour < 0 {
                newStartHour = startHour
            } else if newEndHour > 24.5 {
                newStartHour = startHour
            }
            
            previousPanLocation = location
            startHour = newStartHour
            delegate?.timelineViewController(self, didUpdateStartHour: startHour)
            renderTimeline()
            
        case .ended,
             .cancelled:
            previousPanLocation = nil
            
        default:
            break
        }
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
        let decimal = hour.truncatingRemainder(dividingBy: 1.0)
        let roundedHour = floor(hour) + floor(decimal / roundHourTo) * roundHourTo
        
        return roundedHour
    }
    
}

protocol TimelineViewDelegate : AnyObject {
    
    func timelineViewController(_ timelineViewController: TimelineViewController, didUpdateStartHour: CGFloat)
    func timelineViewController(_ timelineViewController: TimelineViewController, didUpdateHourHeight: CGFloat)
    
}
