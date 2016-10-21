//
//  ViewController.swift
//  CardScrollViewDemo
//
//  Created by Nikolay Sohryakov on 21/10/2016.
//  Copyright © 2016 Nikolay Sohryakov. All rights reserved.
//

import UIKit
import CardScrollView

class ViewController: UIViewController {
    @IBOutlet weak var cardScrollView: CardScrollView! {
        didSet {
            cardScrollView.cardScrollViewDataSource = self.dataSource
            
            cardScrollView.register(nib: UINib(nibName: "TextCard", bundle: nil),
                                    forReuseIdentifier: "TextCard")
        }
    }
    
    fileprivate lazy var dataSource: DataSoure = DataSoure()
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
}

