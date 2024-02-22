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

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    
    @IBAction func buttonPressed(_ sender: UIButton) {
        let vc = UINavigationController(rootViewController: TableViewController())
        vc.transitioningDelegate = transitionManager
        vc.modalPresentationStyle = .custom
        //vc.preferredContentSize = .init(width: 650, height: 600)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self, weak vc] in
            //vc?.preferredContentSize.height = 200
            if let presentationController = vc?.presentationController as? CardPopoverPresentationController {
                self?.transitionManager.sourceDirection = .fromRight
                presentationController.prefersBlurredBackground.toggle()
                presentationController.buttonsView.addButton(UIButton())
            }
            self?.view.backgroundColor = .systemBackground
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
        cell.backgroundConfiguration = {
            var configuration = UIBackgroundConfiguration.listPlainCell()
            configuration.backgroundColor = .clear
            
            return configuration
        }()
        
        return cell
    }
    
}


