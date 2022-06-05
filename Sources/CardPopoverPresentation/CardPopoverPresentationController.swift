//
//  BlurPopoverPresentationController.swift
//  BlurPresentation
//
//  Created by Adam Wienconek on 15/05/2022.
//

import Foundation
import UIKit

public final class CardPopoverPresentationController: UIPresentationController {
    
    public var presentedViewSizeToParentInsets: CGSize = .init(width: 14, height: 44)
    public var dismissButtonTitle: String? = nil {
        didSet {
            guard let buttonTitle = dismissButtonTitle,
                  !buttonTitle.isEmpty else {
                dismissButton.isHidden = true
                return
            }
            if #available(iOS 15.0, *) {
                dismissButton.configuration?.title = buttonTitle
            } else {
                dismissButton.setTitle(buttonTitle, for: .normal)
            }
            dismissButton.isHidden = false
            containerView?.layoutIfNeeded()
        }
    }
    public var prefersBlurredBackground: Bool = true {
        didSet {
            containerView?.layoutIfNeeded()
        }
    }
    
    private var finalFrame: CGRect!
    
    private var frameChangeAnimator: UIViewPropertyAnimator?
    
    private lazy var blurOverlayView: UIVisualEffectView = {
        let fv = UIVisualEffectView(effect: nil)
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissPresentedView))
        fv.contentView.addGestureRecognizer(tap)
        
        return fv
    }()
    
    public private(set) lazy var dismissButton: UIButton = {
        lazy var action = UIAction() { [weak self] _ in
            self?.dismissPresentedView()
        }
        if #available(iOS 15.0, *) {
            var configuration = UIButton.Configuration.filled()
            configuration.cornerStyle = .capsule
            configuration.title = dismissButtonTitle
            
            return UIButton(configuration: configuration,
                            primaryAction: action)
        }
        let btn = UIButton(type: .system)
        if #available(iOS 14.0, *) {
            btn.addAction(action, for: .primaryActionTriggered)
        }
        else {
            btn.addTarget(self, action: #selector(dismissPresentedView), for: .touchUpInside)
        }
        btn.setTitle(dismissButtonTitle, for: .normal)
        
        return btn
    }()
    
    public override func presentationTransitionWillBegin() {
        super.presentationTransitionWillBegin()
        
        guard let containerView = containerView else {
            return
        }
        var constraints: [NSLayoutConstraint] = []
        
        containerView.addSubview(blurOverlayView)
        blurOverlayView.translatesAutoresizingMaskIntoConstraints = false
        constraints.append(contentsOf: [
            blurOverlayView.topAnchor.constraint(equalTo: containerView.topAnchor),
            blurOverlayView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            blurOverlayView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            blurOverlayView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor)
        ])
        
        dismissButton.alpha = 0
        containerView.addSubview(dismissButton)
        dismissButton.translatesAutoresizingMaskIntoConstraints = false
        constraints.append(contentsOf: [
            dismissButton.bottomAnchor.constraint(equalTo: containerView.safeAreaLayoutGuide.bottomAnchor, constant: -Constants.dismissButtonBottomSpacing),
            dismissButton.centerXAnchor.constraint(equalTo: containerView.safeAreaLayoutGuide.centerXAnchor)
        ])
        NSLayoutConstraint.activate(constraints)
        
        if let presentedView = presentedView {
            let modalContainerView = ModalContainerView(contentView: presentedView)
            containerView.addSubview(modalContainerView)
        }
        
        presentedViewController.transitionCoordinator?.animate(alongsideTransition: { context in
            self.blurOverlayView.effect = self.blurEffect
            self.dismissButton.alpha = 1
        }, completion: nil)
    }
    
    public override func dismissalTransitionWillBegin() {
        super.dismissalTransitionWillBegin()
        
        presentedViewController.transitionCoordinator?.animate(alongsideTransition: { context in
            self.blurOverlayView.effect = nil
            self.dismissButton.alpha = 0
        }, completion: nil)
    }
    
    public override func containerViewWillLayoutSubviews() {
        super.containerViewWillLayoutSubviews()
        dismissButton.isHidden = (dismissButtonTitle == nil)
        modalContainerView?.prefersBlurredBackground = !prefersBlurredBackground
        blurOverlayView.effect = prefersBlurredBackground ? blurEffect : nil
    }
    
    public override func containerViewDidLayoutSubviews() {
        super.containerViewDidLayoutSubviews()
        // insertShadowUnderPresentedView()
        guard !presentedViewController.isBeingDismissed else {
            return
        }
        updatePresentedViewFrame()
    }
    
    public override func size(forChildContentContainer container: UIContentContainer, withParentContainerSize parentSize: CGSize) -> CGSize {
        return frameOfPresentedViewInContainerView.size
    }
    
    public override var frameOfPresentedViewInContainerView: CGRect {
        guard let containerView = containerView else {
            return super.frameOfPresentedViewInContainerView
        }
        return frameOfPresentedView(inParent: containerView)
    }
    
    public override func preferredContentSizeDidChange(forChildContentContainer container: UIContentContainer) {
        super.preferredContentSizeDidChange(forChildContentContainer: container)
        guard !(presentedViewController.isBeingPresented || presentedViewController.isBeingDismissed) else {
            return
        }
        frameChangeAnimator = .runningPropertyAnimator(withDuration: Constants.frameUpdateAnimationDuration,
                                                       delay: 0,
                                                       options: [.allowUserInteraction],
                                                       animations: {
            self.updatePresentedViewFrame()
        })
    }
    
}

private extension CardPopoverPresentationController {
    
    enum Constants {
        static let frameUpdateAnimationDuration: TimeInterval = 0.34
        static let dismissButtonBottomSpacing: CGFloat = 24
    }
    
    var modalContainerView: ModalContainerView? {
        containerView?.subviews.first(where: { $0 is ModalContainerView }) as? ModalContainerView
    }
    
    var blurEffect: UIBlurEffect { .init(style: .prominent) }
    
    func updatePresentedViewFrame() {
        guard let containerView = containerView else {
            assertionFailure("containerView was nil.")
            return
        }
        modalContainerView?.frame = frameOfPresentedView(inParent: containerView)
    }
    
    func frameOfPresentedView(inParent parentView: UIView) -> CGRect {
        let parentFrame = parentView.frame
        let safeAreaFrame = parentView.safeAreaLayoutGuide.layoutFrame
        
        var size: CGSize = .zero
        size.width = parentFrame.width - (presentedViewSizeToParentInsets.width * 2)
        size.height = parentFrame.height - (presentedViewSizeToParentInsets.height * 2)
        
        let preferredContentSize = presentedViewController.preferredContentSize
        if preferredContentSize != .zero {
            if preferredContentSize.height != .zero, preferredContentSize.height < size.height {
                size.height = preferredContentSize.height
            }
            if preferredContentSize.width != .zero, preferredContentSize.width < size.width {
                size.width = preferredContentSize.width
            }
        }
        
        var origin: CGPoint = .zero
        origin.x = max((parentFrame.width - size.width) / 2,
                       safeAreaFrame.minX + presentedViewSizeToParentInsets.width)
        
        origin.y = max((parentFrame.height - size.height) / 2,
                       safeAreaFrame.minY + presentedViewSizeToParentInsets.height)
        
        var presentedViewFrame = CGRect(origin: origin, size: size)
        
        while !safeAreaFrame.contains(presentedViewFrame) {
            if presentedViewFrame.minY < safeAreaFrame.minY {
                let inset = (safeAreaFrame.minY - presentedViewFrame.minY)
                if safeAreaFrame.contains(presentedViewFrame.offsetBy(dx: 0, dy: inset)) {
                    presentedViewFrame.origin.y += inset
                } else {
                    presentedViewFrame.size.height -= inset
                }
            }
            else if presentedViewFrame.minX < safeAreaFrame.minX {
                let inset = (safeAreaFrame.minX - presentedViewFrame.minX)
                if safeAreaFrame.contains(presentedViewFrame.offsetBy(dx: inset, dy: 0)) {
                    presentedViewFrame.origin.x += inset
                } else {
                    presentedViewFrame.size.width -= inset
                }
            }
            else if presentedViewFrame.maxY > safeAreaFrame.maxY {
                let offset = (presentedViewFrame.maxY - safeAreaFrame.maxY)
                if safeAreaFrame.contains(presentedViewFrame.offsetBy(dx: 0, dy: -offset)) {
                    presentedViewFrame.origin.y -= offset
                } else {
                    presentedViewFrame.size.height -= offset
                }
            }
            else if presentedViewFrame.maxX > safeAreaFrame.maxX {
                let offset = (presentedViewFrame.maxX - safeAreaFrame.maxX)
                if safeAreaFrame.contains(presentedViewFrame.offsetBy(dx: -offset, dy: 0)) {
                    presentedViewFrame.origin.x -= offset
                } else {
                    presentedViewFrame.size.width -= offset
                }
            }
        }
        
        if !dismissButton.isHidden {
            let expandedButtonFrame = dismissButton.frame.insetBy(dx: 0, dy: -Constants.dismissButtonBottomSpacing)
            let buttonIntersection = presentedViewFrame.intersection(expandedButtonFrame)
            if !buttonIntersection.isNull {
                presentedViewFrame.size.height -= buttonIntersection.height
            }
        }
        
        return presentedViewFrame
    }
    
    func insertShadowUnderPresentedView() {
        let shadowViewTag = 1517910
        guard let presentedView = presentedView else {
            return
        }
        if let shadowView = containerView?.viewWithTag(shadowViewTag) {
            shadowView.frame = frameOfPresentedViewInContainerView
        }
        else {
            let shadowView = UIView()
            shadowView.tag = shadowViewTag
            shadowView.backgroundColor = .clear
            shadowView.frame = presentedView.frame
            shadowView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            
            shadowView.layer.shadowColor = UIColor.black.cgColor
            shadowView.layer.shadowOffset = .init(width: 0, height: 1)
            shadowView.layer.shadowRadius = 10
            shadowView.layer.shadowOpacity = 1.0
            
            containerView?.insertSubview(shadowView, belowSubview: presentedView)
        }
    }
    
    @objc func dismissPresentedView() {
        presentedViewController.dismiss(animated: true)
    }
    
}
