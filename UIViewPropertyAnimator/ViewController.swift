//
//  ViewController.swift
//  UIViewPropertyAnimator
//
//  Created by Yash on 23/04/20.
//  Copyright © 2020 Yash Thaker. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    @IBOutlet weak var blurEffectView: UIVisualEffectView!
    
    var yViewLoaded = false
    var topArea: CGFloat = 0.0
    var bottomArea: CGFloat = 0.0
    
    enum CardState {
        case expanded
        case collapsed
    }
    
    var cardVisible = false
    
    var nextState: CardState {
        return cardVisible ? .collapsed : .expanded
    }
    
    lazy var cardViewController: CardViewController = {
        return self.storyboard?.instantiateViewController(withIdentifier: "CardViewController") as! CardViewController
    }()
    
    let cardHeight: CGFloat = 600.0
    var cardInitialHeight: CGFloat = 44.0
    
    var runningAnimators = [UIViewPropertyAnimator]()
    
    var animationProgress = [CGFloat]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if yViewLoaded { return }
        yViewLoaded = true
        
        topArea = view.safeAreaInsets.top
        bottomArea = view.safeAreaInsets.bottom
        
        cardInitialHeight += bottomArea
        
        blurEffectView.effect = nil
               
        setupCardView()
    }
    
    func setupCardView() {
        addChild(cardViewController)
        view.addSubview(cardViewController.view)
        let yPos = view.frame.height - (cardInitialHeight + bottomArea)
        cardViewController.view.frame = CGRect(x: 0, y: yPos, width: view.frame.width, height: cardHeight)
        
        let panGesture = InstantPanGestureRecognizer(target: self, action: #selector(handleViewPan(_:)))
        cardViewController.handleAreaView.addGestureRecognizer(panGesture)
    }
    
    @objc func handleViewPan(_ recognizer: UIPanGestureRecognizer) {
        switch recognizer.state {
        case .began:
           
            animateTransitionIfNeeded(state: nextState, duration: 0.7)
            runningAnimators.forEach { $0.pauseAnimation() }
            animationProgress = runningAnimators.map { $0.fractionComplete }
            
        case .changed:
            
            let translation = recognizer.translation(in: cardViewController.handleAreaView)
            var fractionComplete = translation.y / cardHeight
            fractionComplete = cardVisible ? fractionComplete : -fractionComplete
            
            for (index, animator) in runningAnimators.enumerated() {
                animator.fractionComplete = fractionComplete + animationProgress[index]
            }
            
        case .ended:
            
            let yVelocity = recognizer.velocity(in: cardViewController.handleAreaView).y
            let shouldFinish = yVelocity < 0
            
            if yVelocity == 0 {
                runningAnimators.forEach { $0.continueAnimation(withTimingParameters: nil, durationFactor: 0) }
                break
            }
            
            switch nextState {
            case .expanded:
                if !shouldFinish && !runningAnimators[0].isReversed { runningAnimators.forEach { $0.isReversed = !$0.isReversed } }
                if shouldFinish && runningAnimators[0].isReversed { runningAnimators.forEach { $0.isReversed = !$0.isReversed } }
            case .collapsed:
                if shouldFinish && !runningAnimators[0].isReversed { runningAnimators.forEach { $0.isReversed = !$0.isReversed } }
                if !shouldFinish && runningAnimators[0].isReversed { runningAnimators.forEach { $0.isReversed = !$0.isReversed } }
            }
            
            runningAnimators.forEach { $0.continueAnimation(withTimingParameters: nil, durationFactor: 0) }
            
        default: break
        }
    }
    
    func animateTransitionIfNeeded(state: CardState, duration: TimeInterval) {
        if !runningAnimators.isEmpty { return }
        
        let animator = UIViewPropertyAnimator(duration: duration, dampingRatio: 1.0) {
            switch state {
            case .expanded:
                self.cardViewController.view.frame.origin.y = self.view.frame.height - self.cardHeight
                self.cardViewController.overlayView.alpha = 0.0
                self.cardViewController.handleAreaView.layer.cornerRadius = 12.0
                
            case .collapsed:
                self.cardViewController.view.frame.origin.y = self.view.frame.height - self.cardInitialHeight
                self.cardViewController.overlayView.alpha = 1.0
                self.cardViewController.handleAreaView.layer.cornerRadius = 0.0
            }
        }
        animator.addCompletion { position in
            switch position {
            case .start:
                break
            case .end:
                self.cardVisible = !self.cardVisible
            case .current:
                break
            default:
                break
            }
            self.runningAnimators.removeAll()
        }
        animator.startAnimation()
        runningAnimators.append(animator)
        
        let blurAnimator = UIViewPropertyAnimator(duration: duration, curve: .linear) {
            switch state {
            case .expanded:
                self.blurEffectView.effect = UIBlurEffect(style: .dark)
            case .collapsed:
                self.blurEffectView.effect = nil
            }
        }
        blurAnimator.startAnimation()
        runningAnimators.append(blurAnimator)
    }
    
}

class InstantPanGestureRecognizer: UIPanGestureRecognizer {
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        if (self.state == .began) { return }
        super.touchesBegan(touches, with: event)
        self.state = .began
    }
    
}
