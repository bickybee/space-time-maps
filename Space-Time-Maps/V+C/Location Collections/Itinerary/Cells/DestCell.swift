//
//  DestCell.swift
//  Space-Time-Maps
//
//  Created by Vicky on 04/09/2019.
//  Copyright © 2019 vicky. All rights reserved.
//

import UIKit

class DestCell: UICollectionViewCell, Draggable {
    
    var dragHandle : UIView! = UIView()
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var durationLabel: UILabel!
    @IBOutlet weak var containerView: UIView!

    override func awakeFromNib() {
        super.awakeFromNib()
        setup()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        dragHandle.frame = containerView.frame
    }
    
    private func setup() {
        containerView.layer.cornerRadius = 5;
        containerView.layer.shadowOffset = CGSize(width: 0, height: 0)
        containerView.layer.shadowRadius = 0.5
        containerView.layer.shadowOpacity = 0.5;
        containerView.layer.masksToBounds = false
        self.layer.masksToBounds = false
//        containerView.layer.masksToBounds = true;
        
        dragHandle = UIView(frame: containerView.frame)
        dragHandle.backgroundColor = .clear
        dragHandle.layer.zPosition = 100
        dragHandle.layer.cornerRadius = 5;
//        dragHandle.layer.masksToBounds = true;
        self.addSubview(dragHandle)
    }
    
    func configureWith(name: String, duration: TimeInterval) {
        
        nameLabel.text = name
        durationLabel.text = Utils.secondsToString(seconds: duration)
        
    }
    
    func configureWith(_ destination: Destination) {
        
        nameLabel.text = destination.place.name
        durationLabel.text = Utils.secondsToString(seconds: destination.timing.duration)
        containerView.backgroundColor = destination.place.color
        
    }
    
    

}
