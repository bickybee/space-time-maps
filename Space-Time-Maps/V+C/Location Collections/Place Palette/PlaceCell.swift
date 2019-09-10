//
//  PlaceCell.swift
//  Space-Time-Maps
//
//  Created by Vicky on 06/09/2019.
//  Copyright © 2019 vicky. All rights reserved.
//

import UIKit

class PlaceCell: UICollectionViewCell {

    var dragHandle : UIView! = UIView()
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var durationLabel: UILabel!
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var editBtn: UIButton!
    
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
    }
    
    private func setup() {
        containerView.layer.cornerRadius = 5;
        containerView.layer.shadowOpacity = 0.5;
        containerView.layer.masksToBounds = true
        self.layer.masksToBounds = true
    }
    
    func configureWith(name: String, duration: TimeInterval) {
        
        nameLabel.text = name
        durationLabel.text = Utils.secondsToString(seconds: duration)
        
    }
    
    func configureWith(_ place: Place) {
        
        nameLabel.text = place.name
        durationLabel.text = Utils.secondsToString(seconds: place.timeSpent)
        containerView.backgroundColor = place.color
        
    }

}
