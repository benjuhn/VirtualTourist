//
//  PhotoAlbumCollectionViewCell.swift
//  Virtual Tourist
//
//  Created by Ben Juhn on 8/12/17.
//  Copyright © 2017 Ben Juhn. All rights reserved.
//

import UIKit

class PhotoAlbumCollectionViewCell: UICollectionViewCell {
    
    let imageView = UIImageView()
    let activityIndicator = UIActivityIndicatorView()
    
    override func layoutSubviews() {
        backgroundColor = .darkGray
        
        activityIndicator.frame = bounds.insetBy(dx: 10, dy: 10)
        activityIndicator.layer.cornerRadius = 10
        activityIndicator.backgroundColor = UIColor(red: 29/255.0, green: 41/255.0, blue: 81/255.0, alpha: 1)
        activityIndicator.activityIndicatorViewStyle = .whiteLarge
        activityIndicator.hidesWhenStopped = true
        self.addSubview(activityIndicator)
        
        imageView.frame = bounds
        imageView.clipsToBounds = true
        imageView.contentMode = .scaleAspectFill
        self.addSubview(imageView)
    }
    
}
