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
    
    weak var delegate: TimelineViewDelegate?
    
    var roundHourTo = 0.25
    
    // Render variables
    var startTime : TimeInterval = 0.0
    var hourHeight : CGFloat = 50.0
    
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
        timelineView.startTime = startTime
        timelineView.hourHeight = hourHeight
        timelineView.setNeedsDisplay()
    }
    
    func setSidebarWidth( _ width: CGFloat) {
        timelineView.sidebarWidth = width
    }
    
    @objc func setCurrentTime() {
        guard let currentTime = Utils.currentTime() else { return }
        timelineView.startTime = currentTime
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
            
            var newStartTime = startTime - Double(dy*100)
            let newEndTime = (newStartTime + TimeInterval.from(hours:Double(view.frame.height / hourHeight)))
            
            if newStartTime < 0 {
                newStartTime = startTime
            } else if newEndTime > TimeInterval.from(hours: 24.5) {
                newStartTime = startTime
            }
            
            previousPanLocation = location
            startTime = newStartTime
            delegate?.timelineViewController(self, didUpdateStartTime: startTime)
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
            let newEndTime = (startTime + TimeInterval.from(hours:Double(view.frame.height / newHourHeight)))
            if newEndTime > TimeInterval.from(hours: 24.5) {
                let newStartTime = TimeInterval.from(hours: 24.5) - TimeInterval.from(hours:Double(view.frame.height / newHourHeight))
                if newStartTime > 0 {
                    startTime = newStartTime
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
    
    func isTimelineWithinBounds(startTime: TimeInterval, hourHeight: CGFloat) {
        // TODO
    }

}

// For external access

extension TimelineViewController {
    
    public func hourInTimeline(forY y: CGFloat) -> Double? {

        let relativeHour = y / hourHeight
        let absoluteHour = Double(relativeHour) + startTime.inHours()
        
        return absoluteHour
    }
    
    public func roundedHourInTimeline(forY y: CGFloat) -> Double? {

        guard let hour = hourInTimeline(forY: y) else { return nil }
        let decimal = hour.truncatingRemainder(dividingBy: 1.0)
        let roundedHour = floor(hour) + floor(decimal / roundHourTo) * roundHourTo
        
        return roundedHour
    }
    
}

protocol TimelineViewDelegate : AnyObject {
    
    func timelineViewController(_ timelineViewController: TimelineViewController, didUpdateStartTime: TimeInterval)
    func timelineViewController(_ timelineViewController: TimelineViewController, didUpdateHourHeight: CGFloat)
    
}
