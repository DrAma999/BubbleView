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
    let frequency: CGFloat = 15
    let elasticity: CGFloat = 1.4
    let density: CGFloat = 2
    
    var containerView: UIView!
    var animator:UIDynamicAnimator!
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    func commonInit() {
        // add containerView and constraints
        createContainerView()
        // crea i nodi delle view
        setupViews()
        // aggiungi i behaviour
        addAttachmentBehavior()
        // disegna il bordo
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
        }
        let centerView = UIView(frame: CGRect(x:0,y:0, width: 2, height: 2))
        centerView.center = center
        centerView.tag = tagDelta + numberOfNodes - 1
        centerView.backgroundColor = UIColor.yellowColor()
        containerView.addSubview(centerView)
    }
    func addAttachmentBehavior() {
            animator = UIDynamicAnimator(referenceView: containerView)
            let centerView = containerView.viewWithTag(tagDelta + numberOfNodes - 1)!
            //Connect center to all the other view
            for index in 0..<(numberOfNodes-1) {
                let view = containerView.viewWithTag(tagDelta + index)!
                let attachBeh = UIAttachmentBehavior(item: view , attachedToItem: centerView)
                attachBeh.damping = damping
                attachBeh.frequency = frequency
                animator.addBehavior(attachBeh)
                
                let dynBh = UIDynamicItemBehavior(items: [view]);
                dynBh.elasticity = elasticity;
                dynBh.density = density;
                animator.addBehavior(dynBh);
            }
            // Connect circonference views
            var lastView = containerView.viewWithTag(tagDelta)!
            for index in 1..<(numberOfNodes-1) {
                let view = containerView.viewWithTag(tagDelta + index)!
                let attachBeh = UIAttachmentBehavior(item: lastView , attachedToItem: view)
                attachBeh.damping = damping
                attachBeh.frequency = frequency
                animator.addBehavior(attachBeh)
                lastView = view
            }
            
            let view = containerView.viewWithTag(tagDelta)!
            let attachBeh = UIAttachmentBehavior(item: lastView , attachedToItem: view)
            attachBeh.damping = damping
            attachBeh.frequency = frequency
            animator.addBehavior(attachBeh)
            
        }
 
        
    }
    func drawInterpolation() {
        
    }
    func buildPointWithRad(radians:CGFloat, center:CGPoint, radius:CGFloat) -> CGPoint {
        let point = CGPoint(x: center.x + (radius * cos(radians)), y: center.y + (radius * sin(radians)))
        return point;
    }
    
    func startAnimation() {
        
        
        // crea timer pertubazioni

    }
    
    /*
    // Only override drawRect: if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func drawRect(rect: CGRect) {
        // Drawing code
    }
    */

}
