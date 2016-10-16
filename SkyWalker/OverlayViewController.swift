//
//  OverlayViewController.swift
//  SkyWalker
//
//  Created by Héctor Del Campo Pando on 27/9/16.
//  Copyright © 2016 Héctor Del Campo Pando. All rights reserved.
//

import UIKit

class OverlayViewController: UIViewController {
    
    //MARK: Properties
    
    @IBOutlet weak var rollLabel: UITextField!
    @IBOutlet weak var pitchLabel: UITextField!
    @IBOutlet weak var azimuthLabel: UITextField!
    
    
    let orientationSensor = OrientationSensor()
    
    var points : [PointOfInterest] = []

    //MARK: Functions
    override func viewDidLoad() {
        super.viewDidLoad()
        points.append(PointOfInterest(name: "Wally", x: 0, y: 0, z: 0))
        points.append(PointOfInterest(name: "Robin", x: 50, y: 0, z: 45))
        orientationSensor.registerEvents()
        if #available(iOS 10.0, *) {
            Timer.scheduledTimer(withTimeInterval: orientationSensor.updateRate,
                                 repeats: true,
                                 block: { _ -> Void in
                                    self.view.layer.sublayers?.forEach({ if $0 is CAShapeLayer {
                                        $0.removeFromSuperlayer()} })
                                    self.azimuthLabel.text = String(format: "Azimuth %.6f", self.orientationSensor.azimuth)
                                    self.pitchLabel.text = String(format: "Pitch %.6f", self.orientationSensor.pitch)
                                    self.rollLabel.text = String(format: "Roll %.6f", self.orientationSensor.roll)
                                    for point in self.points {
                                        if self.inSight(point: point) {
                                            self.draw(point: point)
                                        } else {
                                            self.drawIndicator(for: point)
                                        }
                                    }
            })
        } else {
            // Fallback on earlier versions
        }
        
    }
    
    private func drawIndicator(for point: PointOfInterest) {
        let x_center: Double = Double(self.view.frame.width) / 2,
            y_center: Double = Double(self.view.frame.height) / 2;
        
        let x = (orientationSensor.azimuth - Double(point.x)) / 180,
            y = (orientationSensor.pitch - Double(point.z)) / 90;
        
        let arcSize: Float = Float(M_PI) / 2
        
        let angle = getAngle(x: Float(x), y: Float(y)) - arcSize;
        
        let circlePath = UIBezierPath(arcCenter: CGPoint(x: x_center + x,
                                                         y: y_center + y),
                                      radius: CGFloat(20),
                                      startAngle: CGFloat(angle),
                                      endAngle: CGFloat(angle + arcSize),
                                      clockwise: true)
        
        let circleLayer = CAShapeLayer()
        circleLayer.path = circlePath.cgPath
        
        circleLayer.fillColor = UIColor.clear.cgColor
        circleLayer.strokeColor = UIColor.red.cgColor
        circleLayer.lineWidth = 3.0
        
        let text = CATextLayer()
        text.string = point.id
        text.fontSize = 12
        text.contentsScale = UIScreen.main.scale
        text.foregroundColor = UIColor.red.cgColor
        text.isWrapped = false
        text.bounds = CGRect(x: 0, y: 0, width: 50, height: 50)
        text.position = CGPoint(x: x_center + 20*Double(cos(angle)),
                                y: y_center + 20*Double(sin(angle)))
        circleLayer.addSublayer(text)
        
        view.layer.addSublayer(circleLayer)
    }
    
    private func getAngle(x: Float, y: Float) -> Float {
        return atan2(x, y)
    }
    
    /**
        Checks if a given point is in sight of camera's image.
    */
    private func inSight(point: PointOfInterest) -> Bool {
        let fovWidth = Camera.instance.horizontalFOV,
            fovHeight = Camera.instance.verticalFOV
        return (abs(orientationSensor.azimuth - Double(point.x)) <= Double(fovWidth/2) &&
            abs(orientationSensor.pitch - Double(point.z)) <= Double(fovHeight/2));
    }
    
    /**
        Draws a given point at actual image's position
    */
    private func draw(point: PointOfInterest) {
        let fovWidth = Camera.instance.horizontalFOV,
            fovHeight = Camera.instance.verticalFOV
        
        let x = Double(view.frame.width)/2 - (-orientationSensor.azimuth + Double(point.x))*Double(view.frame.width)/Double(fovWidth),
            y = Double(view.frame.height)/2 - (orientationSensor.pitch - Double(point.z))*Double(view.frame.height)/Double(fovHeight)
        
        let radius: Double = 20
        
        let circlePath = UIBezierPath(arcCenter: CGPoint(x: x,
                                                         y: y),
                                      radius: CGFloat(radius),
                                      startAngle: CGFloat(0),
                                      endAngle: CGFloat(M_PI*2),
                                      clockwise: true)
        
        let circleLayer = CAShapeLayer()
        circleLayer.path = circlePath.cgPath
        
        circleLayer.fillColor = UIColor.clear.cgColor
        circleLayer.strokeColor = UIColor.red.cgColor
        circleLayer.lineWidth = 3.0
        
        let directionLayer = CAShapeLayer()
        let directionPath = UIBezierPath()
        let a = point.direction * .pi/180
        let arrowSize = 2.0
        let arrowLength = 1.25
        
        directionPath.move(to: CGPoint(x: x + cos(a)*radius, y: y + sin(a)*radius))
        directionPath.addLine(to: CGPoint(x: x + cos(a)*radius, y: y + sin(a)*radius+arrowSize))
        directionPath.addLine(to: CGPoint(x: x + cos(a)*radius, y: y + sin(a)*radius-arrowSize))
        directionPath.addLine(to: CGPoint(x: x + cos(a)*radius*arrowLength, y: y + sin(a)*radius))
        directionPath.addLine(to: CGPoint(x: x + cos(a)*radius, y: y + sin(a)*radius+arrowSize))
        
        directionLayer.path = directionPath.cgPath
        directionLayer.strokeColor = UIColor.red.cgColor
        directionLayer.fillColor = UIColor.red.cgColor
        directionLayer.lineWidth = 3.0
        circleLayer.addSublayer(directionLayer)
        
        let text = CATextLayer()
        text.string = "\(point.id) \n\(point.distance) m\n\(point.velocity) m/s"
        text.fontSize = 12
        text.contentsScale = UIScreen.main.scale
        text.foregroundColor = UIColor.red.cgColor
        text.isWrapped = false
        text.bounds = CGRect(x: 0, y: 0, width: 50, height: 50)
        text.position = CGPoint(x: x + 45,
                                y: y + 20)
        circleLayer.addSublayer(text)
        
        view.layer.addSublayer(circleLayer)
        
    }

}
