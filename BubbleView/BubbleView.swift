//
//  BubbleView.swift
//  BubbleView
//
//  Created by Andrea Finollo on 12/06/15.
//  Copyright (c) 2015 CloudInTouch. All rights reserved.
//

import UIKit

let tagDelta = 555

class BubbleView: UIView {
    let numberOfNodes: Int = 9
    let damping: CGFloat = 0.4
    let frequency: CGFloat = 40
    let elasticity: CGFloat = 1.4
    let density: CGFloat = 10

    lazy var shapeLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.fillColor = self.backgroundColor?.CGColor
        self.containerView.layer.addSublayer(layer)
        return layer
    }()
    
    var containerView: UIView!
    var animator: UIDynamicAnimator!
    var centerView: UIView!
    var circumferenceViews = [UIView]()
    
    var dispLink: CADisplayLink?
    
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
    
    
    func commonInit() {
        // add containerView and constraints
        createContainerView()
        // crea i nodi delle view
        setupViews()
        // aggiungi i behaviour
        addAttachmentBehavior()
        // disegna il bordo
        modifyShapeLayer()
    }
    func createContainerView() {
        let insets = UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
        containerView = UIView(frame: UIEdgeInsetsInsetRect(bounds, insets))
        containerView.autoresizingMask = .FlexibleWidth | .FlexibleHeight
        containerView.backgroundColor = UIColor.redColor()
        self.addSubview(containerView)
    }
    
    func setupViews() {
        let center = CGPoint(x: containerView.bounds.midX, y: containerView.bounds.midY)
        let radius = CGFloat(containerView.bounds.midX)
        for index in 0..<(numberOfNodes-1) {
            let rad =  CGFloat(2*M_PI)*(CGFloat(index)/CGFloat(numberOfNodes-1))
            let position = buildPointWithRad(rad, center: center, radius: radius)
            let subview = UIView(frame: CGRect(x: 0, y: 0, width: 2, height: 2))
            subview.center = position
            subview.backgroundColor = UIColor.yellowColor()
            subview.tag = tagDelta + index
            containerView.addSubview(subview)
            circumferenceViews.append(subview)
        }
        let ctrView = UIView(frame: CGRect(x:0,y:0, width: 2, height: 2))
        ctrView.center = center
        ctrView.tag = tagDelta + numberOfNodes - 1
        ctrView.backgroundColor = UIColor.yellowColor()
        containerView.addSubview(ctrView)
        centerView = ctrView
        
    }
    
    func addAttachmentBehavior() {
        animator = UIDynamicAnimator(referenceView: containerView)
        //Connect center to all the other view
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
        shapeLayer.path = self.drawInterpolation().CGPath
    }
    
    func drawInterpolation() -> UIBezierPath {
        let bezierPath = UIBezierPath()
        bezierPath.lineWidth = 4.0
        let radius = CGFloat(containerView.bounds.midX)

        var lastView = circumferenceViews.last!
        bezierPath.moveToPoint(lastView.center)
        for (index,view) in enumerate(circumferenceViews) {
            bezierPath.addQuadCurveToPoint(view.center, controlPoint: centerView.center)

            lastView = view
        }
        return bezierPath
    }
    
    func buildPointWithRad(radians:CGFloat, center:CGPoint, radius:CGFloat) -> CGPoint {
        let point = CGPoint(x: center.x + (radius * cos(radians)), y: center.y + (radius * sin(radians)))
        return point;
    }
    
    func startAnimation() {
        for view in circumferenceViews {
            let randomX = CGFloat(arc4random()) /  CGFloat(UInt32.max) - 0.5
            let randomY = CGFloat(arc4random()) /  CGFloat(UInt32.max) - 0.5
            println(" RandomX \(randomX) RandomY \(randomY)")
            let push = UIPushBehavior(items: [view], mode: .Instantaneous)
            push.pushDirection = CGVector(dx: randomX, dy: randomY)
            push.magnitude = 0.001//CGFloat(arc4random()) /  CGFloat(UInt32.max)
            push.active = true
            animator.addBehavior(push)
        }
        if let link = dispLink {
            link.invalidate()
            dispLink = nil;
        }
        else {
            dispLink = CADisplayLink(target: self, selector:Selector("reDraw"))
            dispLink!.addToRunLoop(NSRunLoop.currentRunLoop(), forMode: NSRunLoopCommonModes)
        }
    }
    
    func stopAnimating() {
        if let link = dispLink {
            link.invalidate()
            dispLink = nil;
        }
    }
    
    func reDraw() {
        modifyShapeLayer()
    }

}

