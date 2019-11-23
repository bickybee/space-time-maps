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
    var timelineView = TimelineView()
    
    var previousPanLocation : CGPoint?
    var prevVelocity: CGPoint?
    var panMultiplier: CGFloat = 1.0
    var offset : CGFloat = 0.0 // current scroll position via collectionview
    
    weak var delegate: TimelineViewDelegate?
    
        
    // Render variables
    var hourHeight : CGFloat {
        get {
            return timelineView.hourHeight
        } set (newVal) {
            timelineView.hourHeight = newVal
        }
    }
    
    var sidebarWidth : CGFloat {
        get {
            return timelineView.sidebarWidth
        } set (newVal) {
            timelineView.sidebarWidth = newVal
        }
    }
    
    var startHour : CGFloat = 0.0
    
    var visibleHours : CGFloat {
        get {
            return timelineView.frame.height / hourHeight
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTimelineView()
    }
    
    func setupTimelineView() {
        self.view = timelineView
        setCurrentTime()
        view.addGestureRecognizer(UIPinchGestureRecognizer(target: self, action: #selector(pinchTime)))
    }
    
    func renderTimeline() {
        timelineView.setNeedsDisplay()
    }
    
    @objc func setCurrentTime() {
        guard let currentTime = Utils.currentTime() else { return }
        timelineView.currentHour = CGFloat(currentTime.inHours())
        renderTimeline()
    }

    
    @objc func pinchTime(_ gestureRecognizer : UIPinchGestureRecognizer) {
        
        if gestureRecognizer.state == .began || gestureRecognizer.state == .changed {
            
            var newHourHeight = hourHeight * gestureRecognizer.scale
            gestureRecognizer.scale = 1.0
            
            if newHourHeight > 25 && newHourHeight < 200 {
                hourHeight = newHourHeight
                delegate?.timelineViewController(self, didUpdateHourHeightBy: 0)
                view.frame.size.height = hourHeight * 24.5
                renderTimeline()
            }
            
        }
    }

}

extension TimelineViewController : UIGestureRecognizerDelegate {
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
}

// For external access

extension TimelineViewController {
    
    public func hourInTimeline(forY y: CGFloat) -> Double {

        let relativeHour = (y + offset) / hourHeight
        let absoluteHour = relativeHour + startHour
        
        return Double(absoluteHour)
    }
    
    public func roundedHourInTimeline(forY y: CGFloat) -> Double {

        let hour = hourInTimeline(forY: y)
        let roundedHour = Utils.ceilHour(hour)
        
        return roundedHour
    }
    
    public func yFromTime(_ seconds: TimeInterval) -> CGFloat {
        let hour = CGFloat(seconds.inHours())
        let y = hour * hourHeight + offset
        return y
    }
    
}

protocol TimelineViewDelegate : AnyObject {

    func timelineViewController(_ timelineViewController: TimelineViewController, didUpdateHourHeightBy delta: CGFloat)
    
}
