//
//  ViewController.swift
//  CardPopoverPresentationExample
//
//  Created by Adam Wienconek on 05/06/2022.
//

import UIKit
import CardPopoverPresentation
import AWPageViewController

class ViewController: UIViewController {
    
    private lazy var transitionManager: CardPopoverPresentation = {
        let manager = CardPopoverPresentation()
        manager.sourceDirection = .fromLeft
        
        return manager
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    
    @IBAction func buttonPressed(_ sender: UIButton) {
        let controllers: [UIViewController] = [UIColor.systemCyan, .systemRed, .systemGreen]
            .map { color in
                let vc = UIViewController()
                vc.view.backgroundColor = color
                return vc
            }
//        let vc = AWPageViewController(
//            viewControllers: controllers,
//            transitionStyle: .scroll,
//            orientation: .horizontal
//        )
//        vc.shouldDisplayPageControl = false
        
        let vc = UINavigationController(rootViewController: TableViewController())
       // vc.preferredContentSize.height = 120
        vc.transitioningDelegate = transitionManager
    //    vc.overrideUserInterfaceStyle = .dark
        vc.modalPresentationStyle = .custom
        if let popo = vc.presentationController as? CardPopoverPresentationController {
            popo.overrideTraitCollection = UITraitCollection(userInterfaceStyle: .dark)
            popo.containerView?.overrideUserInterfaceStyle = .dark
            //popo.ignoredSafeAreaEdges = [.bottom, .top]
            //popo.presentedViewInsets.width = .zero
         //   popo.presentedViewInsets = .zero
            popo.embeedView = true
        //    popo.dismissButtonInsets.width = 64
    //        popo.bottomViewSpacing = 160
   //         popo.prefersBlurredBackground = false
//            if #available(iOS 17.0, *) {
//                popo.traitOverrides.userInterfaceStyle = .dark
//            } else {
//                // Fallback on earlier versions
//            }
       //    popo.showsDismissButton = false
            
            popo.bottomView = {
                let btn = UIButton(type: .system, primaryAction: UIAction() { [unowned vc, weak popo] _ in
                    let height = vc.preferredContentSize.height
                    vc.preferredContentSize.height = (height >= 140) ? 0 : 140
                    popo?.showsDismissButton.toggle()
                })
                btn.configuration = UIButton.Configuration.borderedTinted()
                btn.configuration?.title = "Siema"
                btn.sizeToFit()
                
                return btn
            }()
        }
//        vc.preferredContentSize.height = 240
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self, weak vc] in
 //           vc?.preferredContentSize.height = 200
            if let presentationController = vc?.presentationController as? CardPopoverPresentationController {
//                presentationController.showsDismissButton = false
//
            }
//            self?.view.backgroundColor = .systemBackground
        }
        present(vc, animated: true)
    }


}

final class TableViewController: UITableViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "Table view"
        view.backgroundColor = .clear
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        50
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell: UITableViewCell! = tableView.dequeueReusableCell(withIdentifier: "cell")
        if cell == nil {
            cell = .init(style: .default, reuseIdentifier: "cell")
        }
        cell.contentConfiguration = {
            var configuration = UIListContentConfiguration.cell()
            configuration.text = "Cell: \(indexPath.row)"
            return configuration
        }()
//        cell.backgroundConfiguration = {
//            var configuration = UIBackgroundConfiguration.listPlainCell()
//            configuration.backgroundColor = .clear
//            
//            return configuration
//        }()
        cell.backgroundColor = .clear
        
        return cell
    }
    
}

final class Page: AWPageViewController {
    
}
