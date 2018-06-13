//
//  TravelMapViewController.swift
//  Virtual Tourist
//
//  Created by Hao Wu on 13/6/18.
//  Copyright © 2018 S&J. All rights reserved.
//

import UIKit
import MapKit

class TravelMapViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {

    @IBOutlet weak var mapView: MKMapView!
    
    @objc func foundTap(_ sender: UITapGestureRecognizer) {
        let point = sender.location(in: mapView)
        let tapPoint = mapView.convert(point, toCoordinateFrom: mapView)
        let annotation = MKPointAnnotation()
        annotation.coordinate = tapPoint
        mapView.addAnnotation(annotation)
    }
    
    var locationManager: CLLocationManager!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if (CLLocationManager.locationServicesEnabled())
        {
            locationManager = CLLocationManager()
            locationManager.delegate = self
            locationManager.requestAlwaysAuthorization()
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            locationManager.requestAlwaysAuthorization()
            locationManager.startUpdatingLocation()
        }
 
        let singleTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.foundTap(_:)))
        singleTapRecognizer.delegate = self
        mapView.addGestureRecognizer(singleTapRecognizer)
        
        mapView.delegate = self
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    


    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }

}

// MARK: CLLocationManagerDelegate

extension TravelMapViewController {
    
    func locationManager(manager: CLLocationManager!, didUpdateLocations locations: [AnyObject]!) {
        let location = locations.last as! CLLocation
        
        let center = CLLocationCoordinate2D(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
        let region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
        
        self.mapView.setRegion(region, animated: true)
    }
}

extension TravelMapViewController {
    
    func mapView(_ mapView: MKMapView, didAdd views: [MKAnnotationView]) {
        print("Annotation added")
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        print("Annotation Selected")
    }
}

extension TravelMapViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        return !(touch.view is MKPinAnnotationView)
    }
}
