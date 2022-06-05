//
//  BlurPopoverTransitionAnimator.swift
//  BlurPresentation
//
//  Created by Adam Wienconek on 15/05/2022.
//

import Foundation
import UIKit

class CardPopoverTransitionAnimator: NSObject {
    
    private var runningAnimator: UIViewPropertyAnimator? {
        willSet { runningAnimator?.stopAnimation(true) }
        didSet { runningAnimator?.startAnimation() }
    }
    
    var isDismissing: Bool = false
    var source: CardPopoverPresentation.SourceDirection?
    var duration: TimeInterval
    
    init(source: CardPopoverPresentation.SourceDirection? = .fromLeft,
         duration: TimeInterval) {
        self.source = source
        self.duration = duration
    }
    
}

extension CardPopoverTransitionAnimator: UIViewControllerAnimatedTransitioning {
        
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return duration
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        isDismissing ? animateDismissing(usingTransitionContext: transitionContext) : animatePresenting(usingTransitionContext: transitionContext)
    }

}

private extension CardPopoverTransitionAnimator {
    
    enum Constants {
        static let initialPresentedViewAlpha: CGFloat = 0.4
        static let additionalOffsetForInitialTransform: CGFloat = 16
        static let animatorDampingRatio: CGFloat = 0.7
    }
    
    func initialTransformForPresentedView() -> CGAffineTransform {
        var offsetX: CGFloat = 0
        var offsetY: CGFloat = 0
        
        if let source = source {
            switch source {
            case .fromTop:
                offsetY -= Constants.additionalOffsetForInitialTransform
            case .fromLeft:
                offsetX -= Constants.additionalOffsetForInitialTransform
            case .fromBottom:
                offsetY += Constants.additionalOffsetForInitialTransform
            case .fromRight:
                offsetX += Constants.additionalOffsetForInitialTransform
            }
        }
        
        let translationTransform = CGAffineTransform(translationX: offsetX,
                                                     y: offsetY)
        return translationTransform
    }
    
    func animatePresenting(usingTransitionContext context: UIViewControllerContextTransitioning) {
        guard let presentedViewController = context.viewController(forKey: .to),
              let presentedViewContainer = context.containerView.subviews.first(where: { $0 is ModalContainerView }) else {
            assertionFailure("Presented view was nil")
            return
        }
        presentedViewContainer.frame = context.finalFrame(for: presentedViewController)
        presentedViewContainer.transform = initialTransformForPresentedView()
        presentedViewContainer.alpha = (source == nil) ? 0 : Constants.initialPresentedViewAlpha
        
        context.containerView.addSubview(presentedViewContainer)

        let animator = UIViewPropertyAnimator(duration: duration,
                                              dampingRatio: Constants.animatorDampingRatio)
        animator.addAnimations {
            presentedViewContainer.alpha = 1
            presentedViewContainer.transform = .identity
        }
        animator.addCompletion { position in
            guard position == .end,
                !context.transitionWasCancelled else {
                return
            }
            context.completeTransition(true)
        }
        runningAnimator = animator
    }
    
    func animateDismissing(usingTransitionContext context: UIViewControllerContextTransitioning) {
        guard let presentedViewContainer = context.containerView.subviews.first(where: { $0 is ModalContainerView }) else {
            assertionFailure("Presented view was nil")
            return
        }
        let animator = UIViewPropertyAnimator(duration: duration,
                                              dampingRatio: Constants.animatorDampingRatio)
        animator.addAnimations {
            presentedViewContainer.transform = self.initialTransformForPresentedView()
            presentedViewContainer.alpha = 0
        }
        animator.addCompletion { position in
            guard position == .end,
                !context.transitionWasCancelled else {
                return
            }
            presentedViewContainer.removeFromSuperview()
            context.completeTransition(true)
        }
        runningAnimator = animator
    }
    
}
