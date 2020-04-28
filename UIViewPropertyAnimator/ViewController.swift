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
        return self.storyboard?.instantiateViewController(identifier: "CardViewController") as! CardViewController
    }()
    
    let cardHeight: CGFloat = 600.0
    var cardInitialHeight: CGFloat = 44.0
    
    var runningAnimations = [UIViewPropertyAnimator]()
    var animationProgressWhenInterrupted: CGFloat = 0.0
    
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
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleViewTap(_:)))
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handleViewPan(_:)))
        
        cardViewController.handleAreaView.addGestureRecognizer(tapGesture)
        cardViewController.handleAreaView.addGestureRecognizer(panGesture)
    }
    
    @objc func handleViewTap(_ recognizer: UITapGestureRecognizer) {
        animateTransitionIfNeeded(state: nextState, duration: 0.7)
    }
    
    @objc func handleViewPan(_ recognizer: UIPanGestureRecognizer) {
        switch recognizer.state {
        case .began:
            startInteractiveTransition(state: nextState, duration: 0.7)
        case .changed:
            let translation = recognizer.translation(in: cardViewController.handleAreaView)
            var fractionComplete = translation.y / cardHeight
            fractionComplete = cardVisible ? fractionComplete : -fractionComplete
            updateInteractiveTransition(fractionCompleted: fractionComplete)
        case .ended:
            continueInteractiveTransition()
        default: break
        }
    }
    
    func animateTransitionIfNeeded(state: CardState, duration: TimeInterval) {
        if !runningAnimations.isEmpty { return }
        
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
        animator.addCompletion { _ in
            self.cardVisible = !self.cardVisible
            self.runningAnimations.removeAll()
        }
        animator.startAnimation()
        runningAnimations.append(animator)
        
        let blurAnimator = UIViewPropertyAnimator(duration: duration, curve: .linear) {
            switch state {
            case .expanded:
                self.blurEffectView.effect = UIBlurEffect(style: .dark)
            case .collapsed:
                self.blurEffectView.effect = nil
            }
        }
        blurAnimator.startAnimation()
        runningAnimations.append(blurAnimator)
    }
    
    func startInteractiveTransition(state: CardState, duration: TimeInterval) {
        if runningAnimations.isEmpty {
            animateTransitionIfNeeded(state: state, duration: duration)
        }
        runningAnimations.forEach { animator in
            animator.pauseAnimation()
            animationProgressWhenInterrupted = animator.fractionComplete
        }
    }
    
    func updateInteractiveTransition(fractionCompleted: CGFloat) {
        runningAnimations.forEach { animator in
            animator.fractionComplete = animationProgressWhenInterrupted + fractionCompleted
        }
    }
    
    func continueInteractiveTransition() {
        runningAnimations.forEach { animator in
            animator.continueAnimation(withTimingParameters: nil, durationFactor: 0.0)
        }
    }
    
}

