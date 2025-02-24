//
//  BlurPopoverPresentationController.swift
//  BlurPresentation
//
//  Created by Adam Wienconek on 15/05/2022.
//

import Foundation
import UIKit
import Combine

public final class CardPopoverPresentationController: UIPresentationController {
    
    internal static let presentedViewTag = 7810571
    
    // MARK: Settable properties
    
    /**
     Defines whether presented view gets embeeded inside additional stylized container view.
     
     The default styling which includes rounded corners and nice shadows is a result of placing view inside `ModalContainerView`.
     If you opt out of this behaviour you still get provided transition animation as well as background overlay but the view will be plain rectangle without any stylization.
     
     `ModalContainerView` is publicly exposed by this library so you can still make use of it if your scenario requires it.
     
     Default value is `true`.
     */
    public var embeedView: Bool = true {
        didSet { containerView?.setNeedsLayout() }
    }
    
    /**
     Determines whether button that is used for dismissing controller is visible.
     
     Default value is `true`.
     */
    public var showsDismissButton: Bool {
        get {
            !_dismissButton.isHidden
        }
        set {
            _dismissButton.isHidden = !newValue
            containerView?.setNeedsLayout()
        }
    }
    
    /**
     Insets controlling placement of all subviews used to create the presentation.
     */
    public var presentedViewInsets: CGSize = .init(width: 8, height: 8) {
        didSet { containerView?.setNeedsLayout() }
    }
    
    /**
     Optional view that is displayed under the presented controller's view.
     
     Before assignment the size of the view's frame should already be calculated.
     */
    public var bottomView: UIView? {
        didSet {
            oldValue?.removeFromSuperview()
            if let bottomView {
                containerView?.addSubview(bottomView)
            }
            containerView?.setNeedsLayout()
        }
    }
    
    /**
     Size of insets which are used to position dismiss button.
     
     By default the button follows presented view's top right corner but in some cases you might want to fine tune its position.
     
     Height defines space in points between button and presented view.
     Width defines space in points between right edge of the button and right edge of presented view.
     */
    public var dismissButtonInsets = CGSize(width: 0, height: 6) {
        didSet { containerView?.setNeedsLayout() }
    }
    
    /**
     Amount of space in points between bottom view and presented view's bottom edge.
     
     If there is no `bottomView` this parameter is ignored.
     */
    public var bottomViewSpacing: CGFloat = 4 {
        didSet { containerView?.setNeedsLayout() }
    }
    
    /**
     
     */
    public var ignoredSafeAreaEdges: UIRectEdge = [] {
        didSet { containerView?.setNeedsLayout() }
    }
    
    public var prefersBlurredBackground: Bool = true {
        didSet { containerView?.setNeedsLayout() }
    }
    
    public var prefersDimmedPresenentingView: Bool = true {
        didSet { containerView?.setNeedsLayout() }
    }
    
    /**
     Defines whether presented controller can be dismissed by tapping presentation container background.
     
     Default value is `true`.
     */
    public var backgroundTapDismisses: Bool = true
    
    // MARK: Private properties
    
    private let _isDebuggingFrames = false
    private var _presentationDidEnd = false
    
    private var frameChangeAnimator: UIViewPropertyAnimator? {
        willSet { frameChangeAnimator?.stopAnimation(true) }
        didSet { frameChangeAnimator?.startAnimation() }
    }
    
    private lazy var _dismissButton: UIButton = {
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
    
    // MARK: Overrides
        
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
        
        if _isDebuggingFrames {
            let sf = UIView()
            sf.backgroundColor = .red
            containerView.addSubview(sf)
            sf.translatesAutoresizingMaskIntoConstraints = false
            constraints.append(
                contentsOf: [
                    sf.topAnchor.constraint(equalTo: containerView.safeAreaLayoutGuide.topAnchor),
                    sf.leadingAnchor.constraint(equalTo: containerView.safeAreaLayoutGuide.leadingAnchor),
                    sf.bottomAnchor.constraint(equalTo: containerView.safeAreaLayoutGuide.bottomAnchor),
                    sf.trailingAnchor.constraint(equalTo: containerView.safeAreaLayoutGuide.trailingAnchor)
                ]
            )
        }
        
        _dismissButton.alpha = 0
        containerView.addSubview(_dismissButton)
        
        if let bottomView {
            bottomView.alpha = 0
            containerView.addSubview(bottomView)
        }
        
        NSLayoutConstraint.activate(constraints)
        
        if let presentedView {
            let subview: UIView = embeedView ? ModalContainerView(contentView: presentedView) : presentedView
            subview.tag = Self.presentedViewTag
            containerView.addSubview(subview)
        }
        
        presentedViewController.transitionCoordinator?.animate(alongsideTransition: { context in
            self.blurOverlayView.effect = self.blurEffect
            self._dismissButton.alpha = 1
            self.bottomView?.alpha = 1
            self.dimmingView.alpha = 0.24
        }, completion: nil)
    }
    
    public override func presentationTransitionDidEnd(_ completed: Bool) {
        super.presentationTransitionDidEnd(completed)
        _presentationDidEnd = completed
    }
    
    public override func dismissalTransitionWillBegin() {
        super.dismissalTransitionWillBegin()
        
        presentedViewController.transitionCoordinator?.animate(alongsideTransition: { context in
            self.blurOverlayView.effect = nil
            self._dismissButton.alpha = 0
            self.bottomView?.alpha = 0
            self.dimmingView.alpha = 0
        }, completion: nil)
    }
    
    public override func containerViewWillLayoutSubviews() {
        super.containerViewWillLayoutSubviews()
        
        _dismissButton.sizeToFit()
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
        updatePresentedViewFrame(animated: true)
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
            updatePresentedViewFrame(animated: false)
        }
        else {
            updatePresentedViewFrame(animated: true)
        }
    }
    
}

private extension CardPopoverPresentationController {
    
    enum Constants {
        static var frameUpdateAnimationDuration: TimeInterval { 0.18 }
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
    
    var blurEffect: UIBlurEffect { .init(style: .systemMaterial) }
    
    func updatePresentedViewFrame(animated: Bool) {
        guard let containerView, let _presentedView else {
            return
        }
        func updates() {
            _presentedView.frame = frameOfPresentedView(inParent: containerView)
            _updateCloseButtonFrameIfNeeded(attachedView: _presentedView)
            _updateBottomViewFrameIfNeeded(attachedView: _presentedView)
        }
        // If presentation didn't complete ignore animated parameter.
        guard _presentationDidEnd, animated else {
            return updates()
        }
        frameChangeAnimator = {
            let animator = UIViewPropertyAnimator(
                duration: Constants.frameUpdateAnimationDuration,
                curve: .easeInOut,
                animations: updates
            )
            animator.isUserInteractionEnabled = true
            return animator
        }()
    }
    
    func _updateCloseButtonFrameIfNeeded(attachedView: UIView) {
        guard showsDismissButton else { return }
        
        _dismissButton.sizeToFit()
        let buttonFrame = _dismissButton.frame
        _dismissButton.frame.origin = CGPoint(
            x: attachedView.frame.maxX - buttonFrame.width - dismissButtonInsets.width.grtZ,
            y: attachedView.frame.minY - buttonFrame.height - dismissButtonInsets.height.grtZ
        )
    }
    
    func _updateBottomViewFrameIfNeeded(attachedView: UIView) {
        guard let bottomView else { return }
        
        let bottomFrame = bottomView.frame
        bottomView.frame.origin = CGPoint(
            x: attachedView.frame.midX - (bottomFrame.width / 2),
            y: attachedView.frame.maxY + bottomViewSpacing.grtZ
        )
    }
    
    func frameOfPresentedView(inParent parentView: UIView) -> CGRect {
        /*
         Get the containing frame, by default we assume it's equal to safe area
         but if it's to be ignored we'll add its insets to the resulting frame.
         */
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
        
        /*
         Calculate maximum possible size for the presented view frame.
         The result should be equal to containingFrame minus the insets, frames of dismiss button and bottom view
         and spacing between those elements.
         */
        var maxSize: CGSize = containingFrame.size
        
        maxSize.width -= (2 * presentedViewInsets.width.grtZ)
        maxSize.height -= (2 * presentedViewInsets.height.grtZ)
        if showsDismissButton {
            maxSize.height -= (_dismissButton.frame.height + dismissButtonInsets.height.grtZ) * 2 // Why 2? I don't really know
        }
        if let bottomView {
            maxSize.height -= (bottomView.frame.height + bottomViewSpacing.grtZ)
        }
        
        var presentedViewFrame: CGRect = .zero
        
        /*
         If presented controller defines its preferred size we can use it
         unless it does not exceed the value of maxSize.
         */
        let preferredContentSize = presentedViewController.preferredContentSize
        if preferredContentSize.width > .zero && preferredContentSize.width <= maxSize.width {
            presentedViewFrame.size.width = preferredContentSize.width
        }
        else {
            presentedViewFrame.size.width = maxSize.width
        }
        if preferredContentSize.height > .zero && preferredContentSize.height <= maxSize.height {
            presentedViewFrame.size.height = preferredContentSize.height
        }
        else {
            presentedViewFrame.size.height = maxSize.height
        }
        
        /*
         We want presented view to sit in the center of container frame so we adjust
         its origin to achieve that now that we know its size.
         */
        presentedViewFrame.origin = CGPoint(
            x: containingFrame.midX - (presentedViewFrame.width / 2), // Center horizontally
            y: containingFrame.midY - (presentedViewFrame.height / 2) // Center vertically
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

fileprivate extension CGFloat {
    
    /// Returns value that is greater or equal to zero.
    var grtZ: CGFloat {
        Swift.max(self, 0)
    }
    
}
