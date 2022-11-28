//
//  File.swift
//  
//
//  Created by Adam Wienconek on 08/07/2022.
//

import UIKit

public extension UIViewController {
    
    var cardPopoverPresentationController: CardPopoverPresentationController? {
        presentationController as? CardPopoverPresentationController
    }
    
}
