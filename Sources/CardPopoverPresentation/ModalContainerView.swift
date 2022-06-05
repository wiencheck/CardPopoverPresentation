//
//  File.swift
//  
//
//  Created by Adam Wienconek on 04/06/2022.
//

import UIKit

final class ModalContainerView: UIView {
        
    private lazy var visualEffectView: UIVisualEffectView = {
        let view = UIVisualEffectView(effect: nil)
        view.contentView.backgroundColor = .systemBackground
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.cornerRadius = Properties.cornerRadius
        view.layer.masksToBounds = true
        
        return view
    }()
    
    private lazy var shadowView: UIView = {
        let sideLength = Properties.cornerRadius * 5
        let image = resizableShadowImage(withSideLength: sideLength)
        
        let view = UIImageView(image: image)
        view.translatesAutoresizingMaskIntoConstraints = false
        
        return view
    }()
    
    var contentView: UIView { visualEffectView.contentView }
    
    var prefersBlurredBackground: Bool {
        get {
            visualEffectView.effect != nil
        } set {
            visualEffectView.effect = newValue ? blurEffect : nil
            contentView.backgroundColor = newValue ? .clear : .systemBackground
        }
    }
    
    convenience init(frame: CGRect = .zero, contentView view: UIView) {
        self.init(frame: frame)
        
        contentView.addSubview(view)
        view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            view.topAnchor.constraint(equalTo: contentView.topAnchor),
            view.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            view.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            view.leadingAnchor.constraint(equalTo: contentView.leadingAnchor)
        ])
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        fatalError()
    }
    
}

private extension ModalContainerView {
    
    enum Properties {
        static let blurStyle: UIBlurEffect.Style = .prominent
        static let cornerRadius: CGFloat = 10.0
        static let blurRadius: CGFloat = 6.0
    }
    
    var blurEffect: UIBlurEffect { .init(style: Properties.blurStyle) }
    
    func commonInit() {
        backgroundColor = .clear
        
        addSubview(shadowView)
        var constraints: [NSLayoutConstraint] = [
            shadowView.topAnchor.constraint(equalTo: topAnchor, constant: -Properties.blurRadius),
            shadowView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: Properties.blurRadius),
            shadowView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: Properties.blurRadius),
            shadowView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: -Properties.blurRadius)
        ]
        
        addSubview(visualEffectView)
        constraints.append(contentsOf: [
            visualEffectView.topAnchor.constraint(equalTo: topAnchor),
            visualEffectView.leadingAnchor.constraint(equalTo: leadingAnchor),
            visualEffectView.trailingAnchor.constraint(equalTo: trailingAnchor)
                .withPriority(.defaultHigh),
            visualEffectView.bottomAnchor.constraint(equalTo: bottomAnchor)
                .withPriority(.defaultHigh)
        ])
        
        NSLayoutConstraint.activate(constraints)
    }
    
    func resizableShadowImage(withSideLength sideLength: CGFloat,
                              cornerRadius: CGFloat = Properties.cornerRadius,
                              shadowBlur: CGFloat = Properties.blurRadius,
                              shadowColor: UIColor = .darkGray,
                              shadowOffset: CGSize = .zero) -> UIImage {
        // The image is a square, which makes it easier to set up the cap insets.
        //
        // Note: this implementation assumes an offset of CGSize(0, 0)
        
        let lengthAdjustment = sideLength + (shadowBlur * 2.0)
        let graphicContextSize = CGSize(width: lengthAdjustment, height: lengthAdjustment)
        
        let capInset = cornerRadius + shadowBlur
        let edgeInsets = UIEdgeInsets(top: capInset, left: capInset, bottom: capInset, right: capInset)
        
        return UIGraphicsImageRenderer(size: graphicContextSize)
            .image {
                let context = $0.cgContext
                let roundedRect = CGRect(x: shadowBlur,
                                         y: shadowBlur,
                                         width: sideLength,
                                         height: sideLength)
                let shadowPath = UIBezierPath(roundedRect: roundedRect, cornerRadius: cornerRadius)
                let color = shadowColor.cgColor
                
                // Cut out the middle
                context.addRect(context.boundingBoxOfClipPath)
                context.addPath(shadowPath.cgPath)
                context.clip(using: .evenOdd)
                
                context.setStrokeColor(color)
                context.addPath(shadowPath.cgPath)
                context.setShadow(offset: shadowOffset,
                                  blur: shadowBlur,
                                  color: color)
                context.fillPath()
            }
            .resizableImage(withCapInsets: edgeInsets,
                            resizingMode: .tile)
    }
    
}

fileprivate extension NSLayoutConstraint {
    
    func withPriority(_ priority: UILayoutPriority) -> Self {
        self.priority = priority
        return self
    }
    
}
