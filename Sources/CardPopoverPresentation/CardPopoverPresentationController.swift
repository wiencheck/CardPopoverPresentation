//
//  BlurPopoverPresentationController.swift
//  BlurPresentation
//
//  Created by Adam Wienconek on 15/05/2022.
//

import Foundation
import UIKit
import Combine
import ScrollingButtons

public final class CardPopoverPresentationController: UIPresentationController {
    
    internal static let presentedViewTag = 7810571
    
    public private(set) lazy var closeButton: UIButton = {
        let btn = UIButton(type: .close)
        btn.addAction(
            UIAction(
                handler: { [weak self] _ in
                    self?.presentedViewController.dismiss(animated: true)
                }
            ),
            for: .primaryActionTriggered
        )
        
        return btn
    }()
    
    public var bottomView: UIView?
    
    // MARK: Settable properties
    
    public var embeedView: Bool = true {
        didSet { containerView?.setNeedsLayout() }
    }
    
    public var presentedViewInsets: CGSize = .init(width: 8, height: 14) {
        didSet { containerView?.setNeedsLayout() }
    }
    
    public var closeButtonInsets: CGSize = CGSize(width: 0, height: 6) {
        didSet { containerView?.setNeedsLayout() }
    }
    
    public var backgroundTapDismisses: Bool = true {
        didSet { containerView?.setNeedsLayout() }
    }
    
    public var ignoredSafeAreaEdges: UIRectEdge = [] {
        didSet { containerView?.setNeedsLayout() }
    }
    
    public var prefersBlurredBackground: Bool = true {
        didSet { containerView?.setNeedsLayout() }
    }
    
    public var prefersDimmedPresenentingView: Bool = true {
        didSet { containerView?.setNeedsLayout() }
    }
    
    private var finalFrame: CGRect!
    
    private var frameChangeAnimator: UIViewPropertyAnimator? {
        willSet { frameChangeAnimator?.stopAnimation(true) }
        didSet { frameChangeAnimator?.startAnimation() }
    }
    
    private lazy var blurOverlayView: UIVisualEffectView = {
        let fv = UIVisualEffectView(effect: nil)
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissPresentedView))
        fv.contentView.addGestureRecognizer(tap)
        
        return fv
    }()
    
    private lazy var dimmingView: UIView = {
        let v = UIView(frame: .zero)
        v.backgroundColor = .black
        v.alpha = 0
        
        return v
    }()
    
    private var _closeButtonHiddenObservation: NSKeyValueObservation!
    
    public override func presentationTransitionWillBegin() {
        super.presentationTransitionWillBegin()
        
        guard let containerView else { return }
        var constraints: [NSLayoutConstraint] = []
        
        containerView.addSubview(dimmingView)
        dimmingView.translatesAutoresizingMaskIntoConstraints = false
        constraints.append(contentsOf: [
            dimmingView.topAnchor.constraint(equalTo: containerView.topAnchor),
            dimmingView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            dimmingView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            dimmingView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor)
        ])
        
        containerView.addSubview(blurOverlayView)
        blurOverlayView.translatesAutoresizingMaskIntoConstraints = false
        constraints.append(contentsOf: [
            blurOverlayView.topAnchor.constraint(equalTo: containerView.topAnchor),
            blurOverlayView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            blurOverlayView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            blurOverlayView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor)
        ])
        
        closeButton.alpha = 0
        containerView.addSubview(closeButton)
        
        NSLayoutConstraint.activate(constraints)
        
        if let presentedView {
            let subview: UIView = embeedView ? ModalContainerView(contentView: presentedView) : presentedView
            subview.tag = Self.presentedViewTag
            containerView.addSubview(subview)
        }
        
        presentedViewController.transitionCoordinator?.animate(alongsideTransition: { context in
            self.blurOverlayView.effect = self.blurEffect
            self.closeButton.alpha = 1
            self.dimmingView.alpha = 0.24
        }, completion: nil)
    }
    
    public override func presentationTransitionDidEnd(_ completed: Bool) {
        super.presentationTransitionDidEnd(completed)
        guard completed else { return }
        
        _closeButtonHiddenObservation = closeButton.observe(\.isHidden, options: .new) { [weak self] _, change in
            if change.newValue == nil { return }
            self?.updatePresentedViewFrame()
        }
    }
    
    public override func dismissalTransitionWillBegin() {
        super.dismissalTransitionWillBegin()
        
        presentedViewController.transitionCoordinator?.animate(alongsideTransition: { context in
            self.blurOverlayView.effect = nil
            self.closeButton.alpha = 0
            self.dimmingView.alpha = 0
        }, completion: nil)
    }
    
    public override func containerViewWillLayoutSubviews() {
        super.containerViewWillLayoutSubviews()
        
        closeButton.sizeToFit()
        modalContainerView?.prefersBlurredBackground = !prefersBlurredBackground
        blurOverlayView.effect = prefersBlurredBackground ? blurEffect : nil
        dimmingView.isHidden = !prefersDimmedPresenentingView
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
        frameOfPresentedViewInContainerView.size
    }
    
    public override var frameOfPresentedViewInContainerView: CGRect {
        guard let containerView else {
            return super.frameOfPresentedViewInContainerView
        }
        return frameOfPresentedView(inParent: containerView)
    }
    
    public override func preferredContentSizeDidChange(forChildContentContainer container: UIContentContainer) {
        super.preferredContentSizeDidChange(forChildContentContainer: container)
        guard containerView != nil else {
            return
        }
        if presentedViewController.isBeingPresented || presentedViewController.isBeingDismissed {
            updatePresentedViewFrame()
        }
        else {
            frameChangeAnimator = {
                let animator = UIViewPropertyAnimator(duration: Constants.frameUpdateAnimationDuration,
                                                      curve: .linear) {
                    self.updatePresentedViewFrame()
                }
                animator.isUserInteractionEnabled = true
                return animator
            }()
        }
    }
    
}

private extension CardPopoverPresentationController {
    
    enum Constants {
        static var frameUpdateAnimationDuration: TimeInterval { 0.18 }
        static var dismissButtonBottomSpacing: CGFloat { 14 }
        static var dimmingViewAlpha: CGFloat { 0.24 }
    }
    
    var _presentedView: UIView? {
        containerView?.subviews.first(where: {
            $0 is ModalContainerView
        }) ?? presentedView
    }
    
    var modalContainerView: ModalContainerView? {
        containerView?.subviews.first(where: { $0 is ModalContainerView }) as? ModalContainerView
    }
    
    var blurEffect: UIBlurEffect { .init(style: .prominent) }
    
    func updatePresentedViewFrame() {
        guard let containerView, let _presentedView else {
            return
        }
        _presentedView.frame = frameOfPresentedView(inParent: containerView)
        if !closeButton.isHidden {
            updateCloseButtonFrame(attachedView: _presentedView)
        }
    }
    
    func updateCloseButtonFrame(attachedView: UIView) {
        let buttonFrame = closeButton.frame
        
        closeButton.frame.origin = CGPoint(
            x: attachedView.frame.maxX - buttonFrame.width - closeButtonInsets.width,
            y: attachedView.frame.minY - buttonFrame.height - closeButtonInsets.height
        )
    }
    
    func frameOfPresentedView(inParent parentView: UIView) -> CGRect {
        var containingFrame: CGRect = parentView.safeAreaLayoutGuide.layoutFrame
        
        if ignoredSafeAreaEdges.contains(.top) {
            containingFrame.origin.y = parentView.frame.minY
            containingFrame.size.height += parentView.safeAreaInsets.top
        }
        if ignoredSafeAreaEdges.contains(.left) {
            containingFrame.origin.x = parentView.frame.minX
            containingFrame.size.width += parentView.safeAreaInsets.left
        }
        if ignoredSafeAreaEdges.contains(.bottom) {
            containingFrame.size.height += parentView.safeAreaInsets.bottom
        }
        if ignoredSafeAreaEdges.contains(.right) {
            containingFrame.size.width += parentView.safeAreaInsets.right
        }
        if !closeButton.isHidden {
            let offset = closeButton.frame.height + closeButtonInsets.height
            containingFrame.origin.y += offset
            containingFrame.size.height -= offset
        }
        
        var size: CGSize = .zero
        let controllerPreferredContentSize = presentedViewController.preferredContentSize
        
        if controllerPreferredContentSize.width != .zero {
            size.width = controllerPreferredContentSize.width
        }
        else {
            size.width = containingFrame.width - (presentedViewInsets.width * 2)
        }
        if controllerPreferredContentSize.height != .zero {
            size.height = controllerPreferredContentSize.height
        }
        else {
            size.height = containingFrame.height - (presentedViewInsets.height * 2)
        }
        
        let presentedViewFrame = CGRect(
            x: containingFrame.midX - (size.width / 2), // Center horizontally
            y: containingFrame.midY - (size.height / 2), // Center vetically
            width: size.width,
            height: size.height
        )
        
        return presentedViewFrame
    }
    
    func insertShadowUnderPresentedView() {
        let shadowViewTag = 1517910
        guard let presentedView, let containerView else {
            return
        }
        if let shadowView = containerView.viewWithTag(shadowViewTag) {
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
            
            containerView.insertSubview(shadowView, belowSubview: presentedView)
        }
    }
    
    @objc func dismissPresentedView() {
        guard backgroundTapDismisses else { return }
        presentedViewController.dismiss(animated: true)
    }
    
}
