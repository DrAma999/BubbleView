//
//  BubbleView.swift
//  BubbleView
//
//  Created by Andrea Finollo on 12/06/15.
//  Copyright (c) 2015 CloudInTouch. All rights reserved.
//

import UIKit
let viewSize = 10
let tagDelta = 555

class BubbleView: UIView {
    
    var viewFillColor = UIColor.yellowColor()
    var viewBorderColor = UIColor.clearColor()
    var viewBorderWidth: CGFloat?
    
    private(set) var damping: CGFloat = 0.4
    private(set) var frequency: CGFloat = 20
    private(set) var elasticity: CGFloat = 1.4
    private(set) var density: CGFloat = 10
    private(set) var containerView: UIView!
    private(set) var animator: UIDynamicAnimator!
    private(set) var centerView: UIView!
    private(set) var circumferenceViews = [UIView]()
    private(set) var coordinatesArray: [(firstControlView:UIView, secondControlView:UIView, arcEndView:UIView)] = []
    
    private var numberOfNodes: Int = 17
    private var dispLink: CADisplayLink?
    private var perturbationTimer: NSTimer?
    private lazy var shapeLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        self.containerView.layer.addSublayer(layer)
        return layer
        }()
    

    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    override func removeFromSuperview() {
        self.stopAnimating()
        super.removeFromSuperview()
    }
    init(frame: CGRect, damping:CGFloat, elasticity:CGFloat, density:CGFloat, frequency: CGFloat) {
        self.damping = damping
        self.elasticity = elasticity
        self.density = density
        self.frequency = frequency
        super.init(frame: frame)
    }
    
    func commonInit() {
        // add containerView and constraints
        createContainerView()
        // crea i nodi delle view
        setupViews()
        // aggiungi i behaviour
        addAttachmentBehavior()
//        // disegna il bordo
//        modifyShapeLayer()
    }
    func createContainerView() {
        let insets = UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
        containerView = UIView(frame: UIEdgeInsetsInsetRect(bounds, insets))
        containerView.autoresizingMask = .FlexibleWidth | .FlexibleHeight
        containerView.backgroundColor = UIColor.redColor()
        self.addSubview(containerView)
    }
    func createControlPointView(coordinates:CGPoint) -> UIView {
        let controlPointView = UIView(frame: CGRect(x: 0, y: 0, width: viewSize, height: viewSize))
        controlPointView.backgroundColor = UIColor.yellowColor()
        controlPointView.center = coordinates
        containerView.addSubview(controlPointView)
        circumferenceViews.append(controlPointView)
        return controlPointView
    }
    func createArcView(coordinates:CGPoint)->UIView {
        let arcView = UIView(frame: CGRect(x: 0, y: 0, width: viewSize, height: viewSize))
        arcView.backgroundColor = UIColor.blueColor()
        arcView.center = coordinates
        containerView.addSubview(arcView)
        circumferenceViews.append(arcView)
        return arcView
    }
    
    func setupViews() {
        let center = CGPoint(x: containerView.bounds.midX, y: containerView.bounds.midY)
        let radius = CGFloat(containerView.bounds.midX)
        //TODO: devo lavorare sui punti di controllo non su quelli di connessione, sono 8 archi, ogni arco ha 2 pti di controllo
        var progressiveAngle:CGFloat = 0
        let angleStep = CGFloat(M_PI * 2) / CGFloat((numberOfNodes-1)/2)
        for index in 0..<(numberOfNodes-1)/2 {
            let coordinates = buildBezierPathControlPointsWith(progressiveAngle, endAngle: progressiveAngle + angleStep , center: center, radius: radius)
            progressiveAngle += angleStep
            let first = createControlPointView(coordinates.firstControlPoint)
            let second = createControlPointView(coordinates.secondControlPoint)
            let arc = createArcView(coordinates.arcEndPoint)
            coordinatesArray.append((firstControlView: first, secondControlView: second, arcEndView: arc))
        }
        let ctrView = UIView(frame: CGRect(x:0,y:0, width: viewSize, height: viewSize))
        ctrView.center = center
        ctrView.tag = tagDelta + numberOfNodes - 1
        ctrView.backgroundColor = UIColor.yellowColor()
        containerView.addSubview(ctrView)
        centerView = ctrView
        
    }
    
    func addAttachmentBehavior() {
        animator = UIDynamicAnimator(referenceView: containerView)
        //Connect center to all the other view
        println("\(circumferenceViews)")
        for circView in circumferenceViews {
            let attachBeh = UIAttachmentBehavior(item: circView , attachedToItem: centerView)
            attachBeh.damping = damping
            attachBeh.frequency = frequency
            animator.addBehavior(attachBeh)

            let dynBh = UIDynamicItemBehavior(items: [circView]);
            dynBh.elasticity = elasticity;
            dynBh.density = density;
            dynBh.allowsRotation = false
            animator.addBehavior(dynBh);
        }
        // Connect circonference views
        var lastView = circumferenceViews.last!
        for view in circumferenceViews {
            let attachBeh = UIAttachmentBehavior(item: lastView , attachedToItem: view)
            attachBeh.damping = damping
            attachBeh.frequency = frequency
            animator.addBehavior(attachBeh)
            lastView = view
        }
   
        //Connect the center view to the container virew
        let attachBehToCenter = UIAttachmentBehavior(item: centerView , attachedToItem: containerView)
        animator.addBehavior(attachBehToCenter)
        
        let containerBeh = UIDynamicItemBehavior(items: [containerView])
        containerBeh.density = 1000
        containerBeh.allowsRotation = false
        animator.addBehavior(containerBeh)
       
        let centerBeh = UIDynamicItemBehavior(items: [centerView])
        centerBeh.allowsRotation = false
        animator.addBehavior(centerBeh)
        
    }
    
    func modifyShapeLayer() {
        shapeLayer.fillColor = viewFillColor.CGColor
        if let border = viewBorderWidth where viewBorderWidth != 0{
            shapeLayer.borderColor = viewBorderColor.CGColor
            shapeLayer.borderWidth = border
        }
        
        shapeLayer.path = self.drawInterpolation().CGPath
    }
    
    func drawInterpolation() -> UIBezierPath {
        let bezierPath = UIBezierPath()
        bezierPath.lineWidth = 4.0
        let radius = CGFloat(containerView.bounds.midX)

        let lastView = coordinatesArray.last!.arcEndView
        bezierPath.moveToPoint(lastView.center)
        
        for (firstControlView:UIView, secondControlView:UIView, arcEndView:UIView) in coordinatesArray {
            bezierPath.addCurveToPoint(arcEndView.center, controlPoint1: firstControlView.center, controlPoint2: secondControlView.center)
        }

        return bezierPath
    }
    
    func buildBezierPathControlPointsWith(startAngle:CGFloat, endAngle:CGFloat, center:CGPoint, radius:CGFloat) -> (firstControlPoint:CGPoint, secondControlPoint:CGPoint, arcStartPoint:CGPoint, arcEndPoint:CGPoint) {
        // The formula to get the correct control point distance to approximate a circle is dist = r * (4/3) * tan(pi/(2 * n) with n number of segments
        // Compute all four points for an arc that subtends the same total angle but is centered on the X-axis
        
        let arcAngle = (endAngle - startAngle) / 2
        var startRadiusXComponent = CGFloat(radius * cos(arcAngle))
        var startRadiusYComponent = CGFloat(radius * sin(arcAngle))
        
        var endRadiusXComponent = startRadiusXComponent
        var endRadiusYComponent = -startRadiusYComponent
        
        let d = 2 * (numberOfNodes-1) / 2
        let constant = (4.0/3.0) * tan(CGFloat(M_PI/Double(d)))
        
        var firstControlPoint = CGPoint(x: endRadiusXComponent + constant * startRadiusYComponent, y:  endRadiusYComponent + constant * startRadiusXComponent)
        var secondControlPoint = CGPoint(x: firstControlPoint.x, y:  -(firstControlPoint.y))
        
        // Find the arc points actual locations by computing x1,y1 and x4,y4
        // and rotating the control points by a + a1
        
        let arc = arcAngle + startAngle
        let cosArc = cos(arc)
        let senArc = sin(arc)
        
        endRadiusXComponent = radius * cos(endAngle) + center.x
        endRadiusYComponent = radius * sin(endAngle) + center.y
        startRadiusXComponent = radius * cos(startAngle) + center.x
        startRadiusYComponent = radius * sin(startAngle) + center.y
        
        firstControlPoint = CGPoint(x: firstControlPoint.x * cosArc - firstControlPoint.y * senArc + center.x, y: firstControlPoint.x * senArc + firstControlPoint.y * cosArc + center.y)
        secondControlPoint = CGPoint(x: secondControlPoint.x * cosArc - secondControlPoint.y * senArc + center.x, y: secondControlPoint.x * senArc + secondControlPoint.y * cosArc + center.y)
        
        return (firstControlPoint, secondControlPoint, CGPoint(x: startRadiusXComponent, y: startRadiusYComponent), CGPoint(x: endRadiusXComponent, y: endRadiusYComponent));
    }
    
    func buildPointWithRad(radians:CGFloat, center:CGPoint, radius:CGFloat) -> CGPoint {
        let point = CGPoint(x: center.x + (radius * cos(radians)), y: center.y + (radius * sin(radians)))
        return point
    }
    
    func perturbation() {
        for view in circumferenceViews {
            let randomX = CGFloat(arc4random()) /  CGFloat(UInt32.max) - 0.5
            let randomY = CGFloat(arc4random()) /  CGFloat(UInt32.max) - 0.5
            println(" RandomX \(randomX) RandomY \(randomY)")
            let push = UIPushBehavior(items: [view], mode: .Instantaneous)
            push.pushDirection = CGVector(dx: randomX, dy: randomY)
            push.magnitude = (CGFloat(arc4random()) /  CGFloat(UInt32.max) - 0.5) / 100
            push.active = true
            animator.addBehavior(push)
        }
    }
    
    func startAnimation() {
//        perturbation()
        if let link = dispLink {
            link.invalidate()
            dispLink = nil;
        }
        else {
            dispLink = CADisplayLink(target: self, selector:Selector("reDraw"))
            dispLink!.addToRunLoop(NSRunLoop.currentRunLoop(), forMode: NSRunLoopCommonModes)
        }
        
        // Perturbation timer
        if perturbationTimer == nil {
            perturbationTimer = NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: Selector("perturbation"), userInfo: nil, repeats: true)
            perturbationTimer!.fire()
        }

    }
    
    func stopAnimating() {
        if let link = dispLink {
            link.invalidate()
            dispLink = nil;
        }
        if let timer = perturbationTimer {
            
        }
    }
    
    func reDraw() {
        modifyShapeLayer()
    }

}
//let rad =  CGFloat(2*M_PI)*(CGFloat(index)/CGFloat(numberOfNodes-1))
//let position = buildPointWithRad(rad, center: center, radius: radius)
//let subview = UIView(frame: CGRect(x: 0, y: 0, width: 2, height: 2))
//subview.center = position
//subview.backgroundColor = UIColor.yellowColor()
//subview.tag = tagDelta + index
//containerView.addSubview(subview)
//circumferenceViews.append(subview)


/**
*  Cubic bezier approximation of a circular arc centered at the origin,
*  from (radians) a1 to a2, where a2-a1 < pi/2.  The arc's radius is r.
*
*  Returns an object with four points, where x1,y1 and x4,y4 are the arc's end points
*  and x2,y2 and x3,y3 are the cubic bezier's control points.
*
*  This algorithm is based on the approach described in:
*  A. Riškus, "Approximation of a Cubic Bezier Curve by Circular Arcs and Vice Versa,"
*  Information Technology and Control, 35(4), 2006 pp. 371-378.
*/
//private static function createSmallArc(r:Number, a1:Number, a2:Number):Object
//{
//    // Compute all four points for an arc that subtends the same total angle
//    // but is centered on the X-axis
//    
//    const a:Number = (a2 - a1) / 2.0; //
//    
//    const x4:Number = r * Math.cos(a);
//    const y4:Number = r * Math.sin(a);
//    const x1:Number = x4;
//    const y1:Number = -y4
//    
//    const k:Number = 0.5522847498;
//    const f:Number = k * Math.tan(a);
//    
//    const x2:Number = x1 + f * y4;
//    const y2:Number = y1 + f * x4;
//    const x3:Number = x2;
//    const y3:Number = -y2;
//    
//    // Find the arc points actual locations by computing x1,y1 and x4,y4
//    // and rotating the control points by a + a1
//    
//    const ar:Number = a + a1;
//    const cos_ar:Number = Math.cos(ar);
//    const sin_ar:Number = Math.sin(ar);
//    
//    return {
//        x1: r * Math.cos(a1),
//        y1: r * Math.sin(a1),
//        x2: x2 * cos_ar - y2 * sin_ar,
//        y2: x2 * sin_ar + y2 * cos_ar,
//        x3: x3 * cos_ar - y3 * sin_ar,
//        y3: x3 * sin_ar + y3 * cos_ar,
//        x4: r * Math.cos(a2),
//        y4: r * Math.sin(a2)};
//}
