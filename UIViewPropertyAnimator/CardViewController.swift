//
//  CardViewController.swift
//  UIViewPropertyAnimator
//
//  Created by Yash on 25/04/20.
//  Copyright © 2020 Yash Thaker. All rights reserved.
//

import UIKit

class CardViewController: UIViewController {
    
    @IBOutlet weak var handleAreaView: UIView!
    @IBOutlet weak var handleView: UIView!
    
    @IBOutlet weak var overlayView: UIView!

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        handleAreaView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        handleView.layer.cornerRadius = 3.0
    }
    
}

extension CardViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 50
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell")!
        cell.textLabel?.text = "\(indexPath.row)"
        return cell
    }
}
