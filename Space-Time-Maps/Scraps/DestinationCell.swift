////
////  LocationCell.swift
////  Space-Time-Maps
////
////  Created by vicky on 2019-07-21.
////  Copyright © 2019 vicky. All rights reserved.
////
//
//import UIKit
//
//class DestinationCell: UICollectionViewCell{
//    
//    var contentContainer : UIView!
//    var nameContainer : UIView!
//    var nameLabel : UILabel!
//    let padding : CGFloat = 5
//    let cellInsets = UIEdgeInsets(top: 5.0, left: 5.0, bottom: 5.0, right: 5.0)
//    
//    override init(frame: CGRect) {
//        super.init(frame: frame)
//        
//        setupContent()
//    }
//    
//    required init?(coder aDecoder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }
//    
//    private func setupContent() {
//        
//        contentContainer = UIView(frame: contentView.frame)
//        contentContainer.frame.size.width = self.frame.size.width * 0.6
//        contentContainer.center = contentView.center
//        contentContainer.layer.cornerRadius = 5;
//        contentContainer.layer.masksToBounds = true;
//        contentView.addSubview(contentContainer)
//        
//        setupLabel()
//        
//    }
//    
//    private func setupLabel() {
//        nameContainer = UIView()
//        nameContainer.frame = contentContainer.frame.inset(by: cellInsets)
//        nameContainer.backgroundColor = .white
//        nameContainer.layer.cornerRadius = 5;
//        nameContainer.layer.masksToBounds = true;
//        nameContainer.layer.zPosition = 0
//        
//        nameLabel = UILabel()
//        nameLabel.textAlignment = .left
//        nameLabel.textColor = UIColor.darkGray
//        nameLabel.font = UIFont.systemFont(ofSize: 8.0)
//        nameLabel.numberOfLines = 0
//        nameLabel.frame = nameContainer.frame.inset(by: cellInsets)
//        
//        contentView.addSubview(nameContainer)
//        contentView.addSubview(nameLabel)
//    }
//    
//    public func setupWith(name: String, fraction: Double, constrained: Bool) {
//        let color = ColorUtils.colorFor(fraction: fraction)
//        setupWith(name: name, color: color, constrained: constrained)
//    }
//    
//    public func setupWith(name: String, color: UIColor, constrained: Bool) {
//        contentContainer.backgroundColor = color
//        self.nameLabel.text = name
//        self.layoutSubviews()
//    }
//
//    
//    override func layoutSubviews() {
//        super.layoutSubviews()
//        let newHeight = self.frame.size.height - 10.0
//        nameContainer.frame.size.height = newHeight
//        nameLabel.frame.size.height = newHeight - 8.0
//    }
//    
//    
//}
