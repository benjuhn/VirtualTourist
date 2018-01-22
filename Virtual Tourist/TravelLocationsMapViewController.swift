//
//  TravelLocationsMapViewController.swift
//  Virtual Tourist
//
//  Created by Ben Juhn on 7/24/17.
//  Copyright © 2017 Ben Juhn. All rights reserved.
//

import UIKit
import MapKit

class TravelLocationsMapViewController: UIViewController, MKMapViewDelegate {

    var firstLaunch = false
    
    let mapView = MKMapView()
    let deleteLabel = UILabel()
    let deleteLabelConstant: CGFloat = 80
    var editMode = false
    var editButton = UIBarButtonItem()
    var doneButton = UIBarButtonItem()
    var longPress = UILongPressGestureRecognizer()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureUI()
        
        if firstLaunch {
            showInstructions()
            firstLaunch = false
        }
    }
    
    func dropPin(_ sender: UILongPressGestureRecognizer) {
        if sender.state == .began {
            let annotation = MKPointAnnotation()
            let point = sender.location(in: mapView)
            annotation.coordinate = mapView.convert(point, toCoordinateFrom: mapView)
            mapView.addAnnotation(annotation)
            FlickrClient.shared.findNumberOfPhotos(annotation.coordinate) {
                (photosCount, error) in
                if error != nil {
                    CoreDataStack.shared.savePin(annotation, 0)
                } else {
                    CoreDataStack.shared.savePin(annotation, photosCount!)
                }
            }
        }
    }
    
    // MARK: - Map view delegate
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        guard let annotation = view.annotation else {
            return
        }
        if editMode {
            mapView.removeAnnotation(annotation)
            CoreDataStack.shared.deletePin(annotation)
        } else {
            mapView.deselectAnnotation(annotation, animated: false)
            
            let flowLayout = UICollectionViewFlowLayout()
            let photoAlbumVC = PhotoAlbumCollectionViewController(collectionViewLayout: flowLayout)
            photoAlbumVC.annotation = annotation
            photoAlbumVC.pin = CoreDataStack.shared.fetchPin(annotation)
            navigationController?.pushViewController(photoAlbumVC, animated: true)
        }
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        var pin = mapView.dequeueReusableAnnotationView(withIdentifier: "TouristPin") as? MKPinAnnotationView
        
        if pin == nil {
            pin = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "TouristPin")
        }
        
        pin?.animatesDrop = true
        pin?.annotation = annotation
        return pin
    }
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        UserDefaults.standard.set(mapView.region.center.latitude, forKey: "CenterLat")
        UserDefaults.standard.set(mapView.region.center.longitude, forKey: "CenterLong")
        UserDefaults.standard.set(mapView.region.span.latitudeDelta, forKey: "SpanLatDelta")
        UserDefaults.standard.set(mapView.region.span.longitudeDelta, forKey: "SpanLongDelta")
    }
    
    // MARK: - Button functions
    
    func showInstructions() {
        let instructions = UIAlertController(title: "Welcome to Virtual Tourist!", message: "\n1.) Drop a pin at your desired destination by using a long-press (tap with a short hold). \n\n2.) Then tap on that pin to see a collection of photos associated with that location.", preferredStyle: .alert)
        let closeInstructions = UIAlertAction(title: "Ready to travel virtually!", style: .default, handler: nil)
        instructions.addAction(closeInstructions)
        present(instructions, animated: true, completion: nil)
    }
    
    func toggleEditMode() {
        if editMode {
            editMode = false
            navigationItem.rightBarButtonItem = editButton
            longPress.isEnabled = true
            UIView.animate(withDuration: 0.3, animations: {
                self.mapView.frame.origin.y += self.deleteLabelConstant
                self.deleteLabel.frame.origin.y += self.deleteLabelConstant
            })
        } else {
            editMode = true
            navigationItem.rightBarButtonItem = doneButton
            longPress.isEnabled = false
            UIView.animate(withDuration: 0.3, animations: {
                self.mapView.frame.origin.y -= self.deleteLabelConstant
                self.deleteLabel.frame.origin.y -= self.deleteLabelConstant
            })
        }
    }
    
    // MARK: - Configuration helper functions
    
    func configureUI() {
        // Set navigation bar properties
        title = "Virtual Tourist"
        let instructionsButton = UIBarButtonItem(title: "How to Travel?", style: .plain, target: self, action: #selector(showInstructions))
        navigationItem.leftBarButtonItem = instructionsButton
        
        editButton = UIBarButtonItem(barButtonSystemItem: .edit, target: self, action: #selector(toggleEditMode))
        doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(toggleEditMode))
        navigationItem.rightBarButtonItem = editButton
        
        let okButton = UIBarButtonItem(title: "OK", style: .plain, target: nil, action: nil)
        navigationItem.backBarButtonItem = okButton
        
        // Configure map view
        loadRegion()
        mapView.delegate = self
        mapView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(mapView)
        
        let attributes: [NSLayoutAttribute] = [.top, .bottom, .leading, .trailing]
        for attribute in attributes {
            addConstraintEqualToView(mapView, attribute)
        }
        
        let savedPins = CoreDataStack.shared.loadPins()
        mapView.addAnnotations(savedPins)
        
        // Configure delete label
        deleteLabel.text = "Tap Pins to Delete"
        deleteLabel.textAlignment = .center
        deleteLabel.textColor = .white
        deleteLabel.backgroundColor = .red
        deleteLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(deleteLabel)
        
        let deleteLabelHeight = NSLayoutConstraint(item: deleteLabel, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: deleteLabelConstant)
        let deleteLabelTop = NSLayoutConstraint(item: deleteLabel, attribute: .top, relatedBy: .equal, toItem: mapView, attribute: .bottom, multiplier: 1, constant: 0)
        view.addConstraints([deleteLabelHeight, deleteLabelTop])
        addConstraintEqualToView(deleteLabel, .leading)
        addConstraintEqualToView(deleteLabel, .trailing)
        
        // Configure gesture recognizer
        longPress = UILongPressGestureRecognizer(target: self, action: #selector(dropPin))
        mapView.addGestureRecognizer(longPress)
    }
    
    func addConstraintEqualToView(_ subview: UIView, _ attribute: NSLayoutAttribute) {
        let constraint = NSLayoutConstraint(item: subview, attribute: attribute, relatedBy: .equal, toItem: view, attribute: attribute, multiplier: 1, constant: 0)
        view.addConstraint(constraint)
    }

    func loadRegion() {
        let latitude = UserDefaults.standard.double(forKey: "CenterLat")
        let longitude = UserDefaults.standard.double(forKey: "CenterLong")
        let latitudeDelta = UserDefaults.standard.double(forKey: "SpanLatDelta")
        let longitudeDelta = UserDefaults.standard.double(forKey: "SpanLongDelta")
        let center = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        let span = MKCoordinateSpan(latitudeDelta: latitudeDelta, longitudeDelta: longitudeDelta)
        mapView.region = MKCoordinateRegion(center: center, span: span)
    }
    
}
