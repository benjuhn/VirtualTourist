
//  PhotoAlbumCollectionViewController.swift
//  Virtual Tourist
//
//  Created by Ben Juhn on 7/26/17.
//  Copyright © 2017 Ben Juhn. All rights reserved.
//

import UIKit
import MapKit

private let reuseIdentifier = "Cell"

class PhotoAlbumCollectionViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout {
    
    var annotation: MKAnnotation!
    let mapConstant: CGFloat = 150
    let zoomRange: CLLocationDistance = 10000
    
    let button = UIButton()
    let buttonConstant: CGFloat = 50
    let label = UILabel()
    
    let padding: CGFloat = 5
    var pin: Pin!
    var savedPhotos = [Photo]()
    var selectedPhotos = [Int]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureUI()
        loadData()

        // Register cell classes
        self.collectionView!.register(PhotoAlbumCollectionViewCell.self, forCellWithReuseIdentifier: reuseIdentifier)
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        guard let flowLayout = collectionView?.collectionViewLayout as? UICollectionViewFlowLayout else {
            return
        }
        
        flowLayout.invalidateLayout()
    }

    // MARK: UICollectionViewDataSource

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }


    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return Int(pin.numPhotos)
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! PhotoAlbumCollectionViewCell
        
        cell.activityIndicator.startAnimating()
        
        if savedPhotos.count > indexPath.item {
            if let imageData = savedPhotos[indexPath.item].image as Data? {
                cell.imageView.image = UIImage(data: imageData)
            }
            cell.activityIndicator.stopAnimating()
        } else {
            cell.imageView.image = UIImage()
        }
        
        return cell
    }

    // MARK: UICollectionViewDelegate

    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if selectedPhotos.count == 0 {
            button.setTitle("Remove Selected Pictures", for: .normal)
        }
        
        let cell = collectionView.cellForItem(at: indexPath)
        cell?.alpha = 0.3
        selectedPhotos.append(indexPath.item)
    }
    
    override func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath)
        cell?.alpha = 1
        if let index = selectedPhotos.index(of: indexPath.item) {
            selectedPhotos.remove(at: index)
        }
        
        if selectedPhotos.count == 0 {
            button.setTitle("Load New Collection", for: .normal)
        }
    }
    
    // MARK: - UICollectionViewDelegateFlowLayout
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let dimension = (view.frame.size.width - (4 * padding)) / 3
        return CGSize(width: dimension, height: dimension)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: padding, left: padding, bottom: padding, right: padding)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return padding
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return padding
    }
    
    // MARK: - Configuration helper functions
    
    func configureUI() {
        // Configure map view
        let mapView = MKMapView()
        mapView.isUserInteractionEnabled = false
        mapView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(mapView)
        
        mapView.addAnnotation(annotation)
        mapView.setRegion(MKCoordinateRegionMakeWithDistance(annotation.coordinate, zoomRange, zoomRange), animated: false)
        
        let mapTop = NSLayoutConstraint(item: mapView, attribute: .top, relatedBy: .equal, toItem: topLayoutGuide, attribute: .bottom, multiplier: 1, constant: 0)
        let mapHeight = NSLayoutConstraint(item: mapView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: mapConstant)
        view.addConstraints([mapTop, mapHeight])
        makeHorizontalConstraints(mapView, view)
        
        // Configure button
        button.setTitle("Load New Collection", for: .normal)
        button.setTitleColor(.blue, for: .normal)
        button.addTarget(self, action: #selector(buttonAction), for: .touchUpInside)
        button.backgroundColor = .white
        button.layer.borderColor = UIColor.darkGray.cgColor
        button.layer.borderWidth = 1
        button.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(button)
        
        let buttonHeight = NSLayoutConstraint(item: button, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: buttonConstant)
        view.addConstraint(buttonHeight)
        makeConstraint(button, view, .bottom, 0)
        makeHorizontalConstraints(button, view)
        
        // Configure collection view
        self.automaticallyAdjustsScrollViewInsets = false
        
        collectionView?.delegate = self
        collectionView?.dataSource = self
        collectionView?.allowsMultipleSelection = true
        collectionView?.backgroundColor = .white
        collectionView?.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(collectionView!)
        
        let collectionTop = NSLayoutConstraint(item: collectionView!, attribute: .top, relatedBy: .equal, toItem: mapView, attribute: .bottom, multiplier: 1, constant: 0)
        let collectionBottom = NSLayoutConstraint(item: collectionView!, attribute: .bottom, relatedBy: .equal, toItem: button, attribute: .top, multiplier: 1, constant: 0)
        view.addConstraints([collectionTop, collectionBottom])
        makeHorizontalConstraints(collectionView!, view)
    }
    
    func configureLabel() {
        label.text = "This pin has no images."
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)
        view.bringSubview(toFront: label)
        
        let labelHeight = NSLayoutConstraint(item: label, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: buttonConstant)
        view.addConstraint(labelHeight)
        makeConstraint(label, view, .centerX, 0)
        makeConstraint(label, view, .centerY, 0)
    }
    
    func makeHorizontalConstraints(_ subview: UIView, _ superview: UIView) {
        makeConstraint(subview, superview, .leading, 0)
        makeConstraint(subview, superview, .trailing, 0)
    }
    
    func makeConstraint(_ subview: UIView, _ superview: UIView, _ attribute: NSLayoutAttribute, _ inset: CGFloat) {
        var constant = inset
        if attribute == .trailing || attribute == .bottom {
            constant *= -1
        }
        let constraint = NSLayoutConstraint(item: subview, attribute: attribute, relatedBy: .equal, toItem: superview, attribute: attribute, multiplier: 1, constant: constant)
        superview.addConstraint(constraint)
    }
    
    // MARK: - Photo album data functions
    
    func loadData() {
        // Check for photos in core data
        savedPhotos = CoreDataStack.shared.fetchPhotos(pin)
        savedPhotos.sort(by: { $0.indexPath < $1.indexPath })
        
        // If no photos in core data, download from Flickr
        if savedPhotos.count < Int(pin.numPhotos) {
            getPhotosFromFlickr(Int(pin.numPhotos) - savedPhotos.count)
        }
        
        // If no photos associated with pin, show label
        if pin.numPhotos == 0 {
            configureLabel()
            button.isEnabled = true
            button.setTitleColor(.blue, for: .normal)
        }
    }
    
    func getPhotosFromFlickr(_ count: Int) {
        var returnedThreads = Int(pin.numPhotos) - count
        for i in 0 ..< count {
            var index: Int?
            if count < 21 {
                index = i
            } else {
                index = nil
            }
            FlickrClient.shared.findPhoto(annotation.coordinate, index) {
                (image, title, error) in
                DispatchQueue.main.async {
                    if error != nil {
                        CoreDataStack.shared.updatePhotoCount(self.annotation, Int(self.pin.numPhotos) - 1)
                    } else {
                        if let newPhoto = CoreDataStack.shared.savePhoto(image!, title!, returnedThreads, self.pin) {
                            self.savedPhotos.append(newPhoto)
                        }
                    }
                    returnedThreads += 1
                    self.collectionView?.reloadData()
                    
                    if returnedThreads < Int(self.pin.numPhotos) {
                        self.button.isEnabled = false
                        self.button.setTitleColor(.gray, for: .normal)
                    } else {
                        self.button.isEnabled = true
                        self.button.setTitleColor(.blue, for: .normal)
                    }
                }
            }
        }
    }
    
    // MARK: - Button functions
    
    func buttonAction() {
        if button.title(for: .normal) == "Load New Collection" {
            loadNewCollection()
        } else {
            removeSelectedPictures()
        }
    }
    
    func loadNewCollection() {
        // Remove current photos
        CoreDataStack.shared.removeAllPhotos(pin)
        savedPhotos.removeAll()
        
        // Update count for new set of photos
        FlickrClient.shared.findNumberOfPhotos(annotation.coordinate) {
            (photosCount, error) in
            if error != nil {
                CoreDataStack.shared.updatePhotoCount(self.annotation, 0)
            } else {
                CoreDataStack.shared.updatePhotoCount(self.annotation, photosCount!)
            }
            
            if self.pin.numPhotos > 0 {
                self.label.isHidden = true
            }
            
            // Download new set of photos
            self.getPhotosFromFlickr(Int(self.pin.numPhotos))
        }
    }
    
    func removeSelectedPictures() {
        // Update core data
        CoreDataStack.shared.removeSelectedPhotos(selectedPhotos, savedPhotos)
        CoreDataStack.shared.updatePhotoCount(annotation, Int(pin.numPhotos) - selectedPhotos.count)
        
        // Update collection view
        var adjustment = 0
        selectedPhotos.sort()
        for index in selectedPhotos {
            let adjustedIndex = index - adjustment
            savedPhotos.remove(at: adjustedIndex)
            adjustment += 1
        }
        selectedPhotos.removeAll()
        collectionView?.reloadData()
        
        // Reset button text
        button.setTitle("Load New Collection", for: .normal)
    }
    
}
