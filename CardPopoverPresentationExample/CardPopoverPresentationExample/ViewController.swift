//
//  ViewController.swift
//  CardPopoverPresentationExample
//
//  Created by Adam Wienconek on 05/06/2022.
//

import UIKit
import CardPopoverPresentation

class ViewController: UIViewController {
    
    private lazy var transitionManager: CardPopoverPresentation = {
        let manager = CardPopoverPresentation()
        manager.sourceDirection = .fromLeft
        
        return manager
    }()
    
    @IBAction func buttonPressed(_ sender: UIButton) {
        let controllers: [UIViewController] = [UIColor.systemCyan, .systemRed, .systemGreen]
            .map { color in
                let vc = UIViewController()
                vc.view.backgroundColor = color
                return vc
            }
        let vc = UINavigationController(rootViewController: TableViewController())
        vc.transitioningDelegate = transitionManager
        vc.modalPresentationStyle = .custom
        if let popo = vc.presentationController as? CardPopoverPresentationController {
            popo.embeedView = true
            popo.overrideUserInterfaceStyle = .dark
            popo.bottomView = {
                let toggleButton = UIButton(type: .system, primaryAction: UIAction() { [unowned popo] _ in
                    popo.showsDismissButton.toggle()
                })
                toggleButton.configuration = UIButton.Configuration.borderedTinted()
                toggleButton.configuration?.title = "Hide/Show button"
                
                let toggleSize = UIButton(type: .system, primaryAction: UIAction() { [unowned vc] _ in
                    let height = vc.preferredContentSize.height
                    vc.preferredContentSize.height = (height >= 140) ? 0 : 140
                })
                toggleSize.configuration = UIButton.Configuration.borderedTinted()
                toggleSize.configuration?.title = "Toggle size"
                
                let stack = UIStackView(arrangedSubviews: [toggleButton, toggleSize])
                stack.axis = .horizontal
                stack.spacing = 8
                stack.frame.size = stack.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)

                return stack
            }()
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
        cell.backgroundColor = .clear
        
        return cell
    }
    
}
