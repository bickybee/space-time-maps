//
//  DestCell.swift
//  Space-Time-Maps
//
//  Created by Vicky on 04/09/2019.
//  Copyright © 2019 vicky. All rights reserved.
//

import UIKit

// Used XIB to set up complex constraints cuz it's way easier :-)
class DestinationCell: UICollectionViewCell {
    
    @IBOutlet weak var container: PaddedDestinationView!
    
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
    
    private func setup() {
        container.destinationView.layer.cornerRadius = 5
        container.destinationView.layer.masksToBounds = true
    }
    
    func configureWith(name: String, duration: TimeInterval) {
        
        container.destinationView.nameLabel.text = name
        container.destinationView.durationLabel.text = Utils.secondsToString(seconds: duration)
        
    }
    
    func configureWith(_ destination: Destination) {
        
        container.destinationView.nameLabel.text = destination.place.name
        container.destinationView.durationLabel.text = Utils.secondsToString(seconds: destination.timing.duration)
        container.destinationView.backgroundColor = destination.place.color
        
    }
    
    

}
