//
//  CardPopoverPresentation.swift
//  BlurPresentation
//
//  Created by Adam Wienconek on 15/05/2022.
//

import Foundation
import UIKit

public final class CardPopoverPresentation: NSObject, UIViewControllerTransitioningDelegate {
    
    public enum SourceDirection {
        case fromTop, fromLeft, fromBottom, fromRight
    }
    
    public var transitionDuration: TimeInterval = 0.38
    public var sourceDirection: SourceDirection?
    
    public init(sourceDirection: SourceDirection? = nil) {
        self.sourceDirection = sourceDirection
    }
    
    private lazy var transitionAnimator: CardPopoverTransitionAnimator = .init(duration: transitionDuration)
    
    public func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        return CardPopoverPresentationController(presentedViewController: presented,
                                                 presenting: presenting)
    }
    
    public func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return configuredTransistionAnimator(forDismissing: false)
    }
    
    public func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return configuredTransistionAnimator(forDismissing: true)
    }
    
}

private extension CardPopoverPresentation {
    
    func configuredTransistionAnimator(forDismissing isDismissing: Bool) -> UIViewControllerAnimatedTransitioning {
        transitionAnimator.isDismissing = isDismissing
        transitionAnimator.source = sourceDirection
        transitionAnimator.duration = transitionDuration
        
        return transitionAnimator
    }
    
}
