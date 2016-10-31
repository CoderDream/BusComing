//
//  DisplayViewController.swift
//  BusComing
//
//  Created by Peng Liu on 16-10-29.
//  Copyright (c) 2016 LiuPeng. All rights reserved.
//

import UIKit

class DisplayViewController: UIViewController, MAMapViewDelegate {

    var route: Route?
    var mapView: MAMapView?
    var myLocation: MAPointAnnotation?
    
    var isPlaying: Bool = false
    var currentLocationIndex: Int = 0
    var averageSpeed: Double = 2
    
    override func viewDidLoad() {
        
        self.view.backgroundColor = UIColor.gray
        
        initMapView()
        
        initToolBar()
        
        showRoute()
        
        //initVariates()
    }
    
    func initMapView() {
        
        mapView = MAMapView(frame: self.view.bounds)
        mapView!.delegate = self
        self.view.addSubview(mapView!)
        self.view.sendSubview(toBack: mapView!)
    }
    
    func initToolBar() {
        
        let playButtonItem: UIBarButtonItem = UIBarButtonItem(image: UIImage(named: "icon_play.png"), style: UIBarButtonItemStyle.plain, target: self, action: #selector(DisplayViewController.actionPlayAndStop))
        
        navigationItem.rightBarButtonItem = playButtonItem
    }
    
    func showRoute() {
        
        if route == nil || route!.locations.count == 0 {
            print("Invalid route")
            return
        }
        
        let starPoint = MAPointAnnotation()
        starPoint.coordinate = route!.startLocation()!.coordinate
        starPoint.title = "Start"
        
        mapView!.addAnnotation(starPoint)
        
        
        let endPoint = MAPointAnnotation()
        endPoint.coordinate = route!.endLocation()!.coordinate
        endPoint.title = "End"
        
        mapView!.addAnnotation(endPoint)
        
        var coordiantes: [CLLocationCoordinate2D] = route!.coordinates()
        
        let polyline = MAPolyline.init(coordinates: &coordiantes, count: UInt(coordiantes.count))

        mapView!.add(polyline)
        
        mapView!.showAnnotations(mapView!.annotations, animated: true)
        
        // average Speed
        averageSpeed = route!.totalDistance() / route!.totalDuration()
    }
    
    func initVariates() {
        isPlaying = false;
        currentLocationIndex = 0;
        averageSpeed = 2;
    }
    
    //MARK:- Helpers
    
    func actionPlayAndStop() {
        
        
        if route == nil {
            return
        }
        
        isPlaying = !isPlaying
        
        if isPlaying {
            print("actionPlay")
            navigationItem.rightBarButtonItem!.image = UIImage(named: "icon_stop.png")
            
            if myLocation == nil {
                myLocation = MAPointAnnotation()
                myLocation!.title = "AMap"
                myLocation!.coordinate = route!.startLocation()!.coordinate
                
                mapView!.addAnnotation(myLocation)
            }
            
            animateToNextCoordinate()
        }
        else {
            print("actionStop")
            navigationItem.rightBarButtonItem!.image = UIImage(named: "icon_play.png")
            
            let view: MAAnnotationView? = mapView!.view(for: myLocation)
            if view != nil {
                view!.layer.removeAllAnimations()
            }
            
        }
    }
    
    func coordinateHeading(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> Double {
        
        if !CLLocationCoordinate2DIsValid(from) || !CLLocationCoordinate2DIsValid(to) {
            return 0.0
        }
        
        let delta_lat_y: Double = to.latitude - from.latitude
        let delta_lon_x: Double = to.longitude - from.longitude
        
        if fabs(delta_lat_y) < 0.000001 {
            return delta_lon_x < 0.0 ? 270.0 : 90.0
        }
        
        var heading: Double = atan2(delta_lon_x, delta_lat_y) / M_PI * 180.0
        
        if heading < 0.0 {
            heading += 360.0
        }
        return heading
    }
    
    func animateToNextCoordinate() {
        
        if myLocation == nil {
            return
        }
        
        //print("currentLocationIndex: \(currentLocationIndex)")
        
        let coordiantes: [CLLocationCoordinate2D] = route!.coordinates()
        
        if currentLocationIndex == coordiantes.count {
            currentLocationIndex = 0
            actionPlayAndStop()
            return
        }

        let nextCoord: CLLocationCoordinate2D = coordiantes[currentLocationIndex]
        
        let prevCoord: CLLocationCoordinate2D = currentLocationIndex == 0 ? nextCoord : myLocation!.coordinate
        
        let heading: Double = coordinateHeading(from: prevCoord, to: nextCoord)
        
        let distance: CLLocationDistance  = MAMetersBetweenMapPoints(MAMapPointForCoordinate(nextCoord), MAMapPointForCoordinate(prevCoord));
       
        let duration: TimeInterval = distance / (averageSpeed * 100)

        UIView.animate(
            withDuration: duration,
            animations: {
                () -> Void in
                self.myLocation!.coordinate = nextCoord
                return
            },
            completion: { (stop: Bool) -> Void in
                self.currentLocationIndex += 1
                if stop {
                    self.animateToNextCoordinate()
                }
                return
        })
        
        let view: MAAnnotationView? = mapView!.view(for: myLocation)
        if view != nil {
            view!.transform = CGAffineTransform.init(rotationAngle: CGFloat(heading / 180.0 * M_PI));
        }
    }
    
    //MARK:- MAMapViewDelegate
    
    func mapView(_ mapView: MAMapView, viewFor annotation: MAAnnotation) -> MAAnnotationView? {
        
        if annotation.isEqual(myLocation) {
            
            let annotationIdentifier = "myLcoationIdentifier"
            
            var poiAnnotationView = mapView.dequeueReusableAnnotationView(withIdentifier: annotationIdentifier)
            if poiAnnotationView == nil {
                poiAnnotationView = MAAnnotationView.init(annotation: annotation, reuseIdentifier: annotationIdentifier)
            }
            
            poiAnnotationView?.image = UIImage.init(named: "aeroplane.png")
            poiAnnotationView!.canShowCallout = false
            
            return poiAnnotationView;
        }
        
        if annotation.isKind(of: MAPointAnnotation.self) {
            let annotationIdentifier = "lcoationIdentifier"
            
            var poiAnnotationView = mapView.dequeueReusableAnnotationView(withIdentifier: annotationIdentifier) as? MAPinAnnotationView
            
            if poiAnnotationView == nil {
                poiAnnotationView = MAPinAnnotationView.init(annotation: annotation, reuseIdentifier: annotationIdentifier)
            }
            
            poiAnnotationView!.animatesDrop   = true
            poiAnnotationView!.canShowCallout = true
            
            return poiAnnotationView;
        }
        
        return nil
    }

    func mapView(_ mapView: MAMapView, rendererFor overlay: MAOverlay) -> MAOverlayRenderer? {
        
        if overlay.isKind(of: MAPolyline.self) {
            let renderer: MAPolylineRenderer = MAPolylineRenderer.init(overlay: overlay)
            renderer.strokeColor = UIColor.red
            renderer.lineWidth = 6.0
            
            return renderer
        }
        
        return nil
    }

}
