//
//  CoreDataStack.swift
//  Virtual Tourist
//
//  Created by Ben Juhn on 7/25/17.
//  Copyright © 2017 Ben Juhn. All rights reserved.
//

import CoreData
import MapKit

class CoreDataStack {
    
    static let shared = CoreDataStack()
    private init() {}
    
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "VirtualTouristData")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()
    
    func saveContext () {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
    
    // MARK: - Travel locations map functions
    
    func loadPins() -> [MKPointAnnotation] {
        var savedPins = [MKPointAnnotation]()
        let context = persistentContainer.viewContext
        let fr = NSFetchRequest<Pin>(entityName: "Pin")
        do {
            let pins = try context.fetch(fr)
            for pin in pins {
                let annotation = MKPointAnnotation()
                annotation.coordinate = CLLocationCoordinate2D(latitude: pin.latitude, longitude: pin.longitude)
                savedPins.append(annotation)
            }
        } catch {}
        return savedPins
    }
    
    func savePin(_ annotation: MKPointAnnotation, _ photosCount: Int) {
        let context = persistentContainer.viewContext
        if let entity = NSEntityDescription.entity(forEntityName: "Pin", in: context) {
            let addedPin = Pin(entity: entity, insertInto: context)
            addedPin.latitude = annotation.coordinate.latitude
            addedPin.longitude = annotation.coordinate.longitude
            addedPin.numPhotos = Int64(photosCount)
            saveContext()
        }
    }
    
    func deletePin(_ annotation: MKAnnotation) {
        let context = persistentContainer.viewContext
        let fr = NSFetchRequest<Pin>(entityName: "Pin")
        let latitudePredicate = NSPredicate(format: "latitude == %@", argumentArray: [annotation.coordinate.latitude])
        let longitudePredicate = NSPredicate(format: "longitude == %@", argumentArray: [annotation.coordinate.longitude])
        fr.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [latitudePredicate, longitudePredicate])
        do {
            let pins = try context.fetch(fr)
            if pins.count > 0 {
                context.delete(pins[0])
                saveContext()
            }
        } catch {}
    }
    
    func fetchPin(_ annotation: MKAnnotation) -> Pin? {
        let context = persistentContainer.viewContext
        let fr = NSFetchRequest<Pin>(entityName: "Pin")
        let latitudePredicate = NSPredicate(format: "latitude == %@", argumentArray: [annotation.coordinate.latitude])
        let longitudePredicate = NSPredicate(format: "longitude == %@", argumentArray: [annotation.coordinate.longitude])
        fr.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [latitudePredicate, longitudePredicate])
        do {
            let pins = try context.fetch(fr)
            if pins.count > 0 {
                return pins[0]
            }
        } catch {}
        return nil
    }
    
    // MARK: - Photo album functions
    
    func fetchPhotos(_ pin: Pin) -> [Photo] {
        var savedPhotos = [Photo]()
        let context = persistentContainer.viewContext
        let fr = NSFetchRequest<Photo>(entityName: "Photo")
        fr.predicate = NSPredicate(format: "pin == %@", argumentArray: [pin])
        do {
            let photos = try context.fetch(fr)
            for photo in photos {
                savedPhotos.append(photo)
            }
        } catch {}
        return savedPhotos
    }
    
    func savePhoto(_ image: Data, _ title: String, _ indexPath: Int, _ pin: Pin) -> Photo? {
        let context = persistentContainer.viewContext
        if let entity = NSEntityDescription.entity(forEntityName: "Photo", in: context) {
            let addedPhoto = Photo(entity: entity, insertInto: context)
            addedPhoto.image = image as NSData?
            addedPhoto.title = title
            addedPhoto.indexPath = Int64(indexPath)
            addedPhoto.pin = pin
            saveContext()
            return addedPhoto
        }
        return nil
    }
    
    func removeAllPhotos(_ pin: Pin) {
        let context = persistentContainer.viewContext
        let fr = NSFetchRequest<NSFetchRequestResult>(entityName: "Photo")
        fr.predicate = NSPredicate(format: "pin == %@", argumentArray: [pin])
        let batchDelete = NSBatchDeleteRequest(fetchRequest: fr)
        do {
            try context.execute(batchDelete)
            saveContext()
        } catch {}
    }
    
    func updatePhotoCount(_ annotation: MKAnnotation, _ photosCount: Int) {
        let context = self.persistentContainer.viewContext
        let fr = NSFetchRequest<Pin>(entityName: "Pin")
        let latitudePredicate = NSPredicate(format: "latitude == %@", argumentArray: [annotation.coordinate.latitude])
        let longitudePredicate = NSPredicate(format: "longitude == %@", argumentArray: [annotation.coordinate.longitude])
        fr.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [latitudePredicate, longitudePredicate])
        do {
            let pins = try context.fetch(fr)
            if pins.count > 0 {
                pins[0].numPhotos = Int64(photosCount)
            }
        } catch {}
    }
    
    func removeSelectedPhotos(_ selectedPhotos: [Int], _ savedPhotos: [Photo]) {
        let context = persistentContainer.viewContext
        for index in selectedPhotos {
            let photo = savedPhotos[index]
            context.delete(photo)
            saveContext()
        }
    }
    
}
