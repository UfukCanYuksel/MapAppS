//
//  ViewController.swift
//  MapsApp
//
//  Created by ufuk can yüksel on 16.06.2023.
//

import UIKit
import CoreLocation
import MapKit
import CoreData

class ViewController: UIViewController , MKMapViewDelegate , CLLocationManagerDelegate {

    @IBOutlet weak var nameText: UITextField!
    @IBOutlet weak var commentText: UITextField!
    @IBOutlet weak var mapView: MKMapView!
    
    var locationManager = CLLocationManager()
    var chooseLatitude = Double()
    var chooseLongitude = Double()
    
    var selectedTitle = ""
    var selectedTitleId : UUID?
    
    var annotationTitle = ""
    var annotationSubtitle = ""
    var annotationLatitude = Double()
    var annotationLongitude = Double()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        mapView.delegate = self
        locationManager.delegate = self
        
        // kullanıcının yerinin ne kadar doğru hesaplanmasını belirlediğim yer.
        locationManager.desiredAccuracy = kCLLocationAccuracyBest // best en iyi
        
        // kullanıcıdan location kullanma izni için , info dan izin için açıklama yazılabilir.
        locationManager.requestWhenInUseAuthorization() // whenInUseAutHorization = Uygulamayı kullanırken
        
        locationManager.startUpdatingLocation() // kullanıcı location'ı almaya başlıyorım
        
        // klavye kapatma
        let gestureRecognizer2 = UITapGestureRecognizer(target: self, action: #selector(hideKeyboard))
        view.addGestureRecognizer(gestureRecognizer2)
        
        
        // pinleme için
        let gestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(chooseLocation(gestureRecgnizer:)))
        gestureRecognizer.minimumPressDuration = 2
        mapView.addGestureRecognizer(gestureRecognizer)
        
      
        if selectedTitle != ""{
            // CoreData
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            let content = appDelegate.persistentContainer.viewContext
            
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Places")
            let idString = selectedTitleId!.uuidString
            fetchRequest.predicate = NSPredicate(format: "id = %@", idString)
            fetchRequest.returnsObjectsAsFaults = false
            
            do{
                let results = try content.fetch(fetchRequest)
                if results.count > 0 {
                    for result in results as! [NSManagedObject] {
                        
                        if let title = result.value(forKey: "title") as? String{
                            annotationTitle = title
                            if let subtitle = result.value(forKey: "subtitle") as? String{
                                annotationSubtitle = subtitle
                                if let latitude  = result.value(forKey: "latitude") as? Double{
                                    annotationLatitude = latitude
                                    if let longitude = result.value(forKey: "longitude") as? Double {
                                        annotationLongitude = longitude
                                        
                                        let annotation = MKPointAnnotation()
                                        annotation.title = annotationTitle
                                        annotation.subtitle = subtitle
                                        let coordinate = CLLocationCoordinate2D(latitude: annotationLatitude, longitude: annotationLongitude)
                                        annotation.coordinate = coordinate
                                        
                                        mapView.addAnnotation(annotation)
                                        nameText.text = annotationTitle
                                        commentText.text = annotationSubtitle
                                        
                                        locationManager.stopUpdatingLocation()
                                        
                                        let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                                        let region = MKCoordinateRegion(center: coordinate, span: span)
                                        mapView.setRegion(region, animated: true)
                                    }
                                }
                            }
                            
                        }
                    }
                }
                
            }catch{
                
                print("error3")
            }
            
            
        }else{
            // add new data
        }
       
        
        
    }
    // hide Keyboard
    @objc func hideKeyboard( ){
        view.endEditing(true)
        
    }
    
    @objc func chooseLocation(gestureRecgnizer : UILongPressGestureRecognizer){
        
        // tıklama işlemi başarılıysa
        if gestureRecgnizer.state == .began {
            // dokunulmuş noktayı almak için kullanılır
            let touchPoint = gestureRecgnizer.location(in: self.mapView)
            
            // dokunulan noktayı koordinata çevirmek için
            let touchCoordinates = self.mapView.convert(touchPoint, toCoordinateFrom: self.mapView)
            
            chooseLatitude = touchCoordinates.latitude
            chooseLongitude = touchCoordinates.longitude
            
            // pin oluşturma
            let annotation = MKPointAnnotation( )
            annotation.coordinate = touchCoordinates
            annotation.title = nameText.text
            annotation.subtitle = commentText.text
            
            
            self.mapView.addAnnotation(annotation)
        }
        
    }
    
    // kullanıcının yerini aldığımızda ne yapacağımızı yazıyoruz
    // Update edilen lokasyonları dizi içerisinde vermekte
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        if selectedTitle == ""{
            // güncel lokasyona ulaşıp zoomlayarak göstermek için
            // latitude = enlem     , Longtude = boylam
            let location = CLLocationCoordinate2D(latitude: locations[0].coordinate.latitude , longitude: locations[0].coordinate.longitude)
            
            // zoom seviyesi için span oluştur.
            let span = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            
            // location ve span'ı kullanacağım region lazım
            let region = MKCoordinateRegion(center: location , span: span)
            // mapView e set ediyorum.// latitude = enlem     , Longtude = boylam
            mapView.setRegion(region, animated: true)
        }
       
        
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        if annotation is MKUserLocation {
            return nil
        }
        
        var resuId = "myAnnotation"
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: resuId) as? MKMarkerAnnotationView
        
        if pinView == nil {
            pinView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: resuId)
            pinView?.canShowCallout = true
            
            let button = UIButton(type: UIButton.ButtonType.detailDisclosure)
            pinView?.rightCalloutAccessoryView = button
        }else{
            pinView?.annotation = annotation
        }
        
        return pinView
        
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        
        if selectedTitle != "" {
            
            let requestLocation = CLLocation(latitude: annotationLatitude, longitude: annotationLongitude)
            
            CLGeocoder().reverseGeocodeLocation(requestLocation) { (placemarks , eror) in
                
                if let placemark = placemarks{
                    if placemark.count > 0 {
                        let newPlaceMark = MKPlacemark(placemark: placemark[0])
                        let item = MKMapItem(placemark: newPlaceMark)
                        item.name = self.annotationTitle
                        
                        let launchOption = [MKLaunchOptionsDirectionsModeKey :  MKLaunchOptionsDirectionsModeDriving]
                        item.openInMaps(launchOptions: launchOption)
                        
                        
                    }
                }
                
            }
            
        }
    }
    
    
    
    @IBAction func saveButton(_ sender: Any) {
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let content = appDelegate.persistentContainer.viewContext
        
        let newPlace = NSEntityDescription.insertNewObject(forEntityName: "Places", into: content)
        
        if nameText.text != ""{
            newPlace.setValue(nameText.text, forKey: "title")
        }else{
            alert(x: "Name")
        }
        if commentText.text != ""{
            newPlace.setValue(commentText.text, forKey: "subtitle")
        }else{
            alert(x: "Comment")
        }
        
        newPlace.setValue(chooseLatitude, forKey: "latitude")
        newPlace.setValue(chooseLongitude, forKey: "longitude")
        newPlace.setValue(UUID(), forKey: "id")
        
        do{
            try content.save()
            print("success")
        }catch{
            print("error 1")
        }
        
        NotificationCenter.default.post(name: NSNotification.Name("newPlace"), object: nil)
        navigationController?.popViewController(animated: true)
       
    }
    
    func alert(x : String ){
        let alert = UIAlertController(title: "\(x) Error ", message: "Place enter \(x)", preferredStyle: UIAlertController.Style.alert)
        let okButton = UIAlertAction(title: "Ok", style: UIAlertAction.Style.default)
        alert.addAction(okButton)
        self.present(alert, animated: true)
    }
    

}

