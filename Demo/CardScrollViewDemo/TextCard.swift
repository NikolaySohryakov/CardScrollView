//
//  ConcreteCell.swift
//  CardScrollExample
//
//  Created by Nikolay Sohryakov on 08/10/2016.
//  Copyright © 2016 Nikolay Sohryakov. All rights reserved.
//

import UIKit
import CardScrollView

class TextCard: CardScrollViewCard {
    typealias CardAction = (_ height: Float) -> Void
    
    @IBOutlet weak var header: UILabel!
    @IBOutlet weak var textField: UITextView!
    @IBOutlet weak var actionButton: UIButton!
    
    open var cardAction: CardAction?
    open var expanded: Bool = false {
        didSet {
            let title = expanded ? "Show me less!" : "Show me more!"
            self.actionButton.setTitle(title, for: .normal)
        }
    }
    
    open override func prepareForReuse(willCollapse: Bool) {
        self.expanded = !willCollapse
    }
    
    fileprivate func calculateExpandedCellHeight() -> Float {
        let oldHeight = self.textField.bounds.size.height
        let maxWidth = self.textField.bounds.size.width
        
        let newHeight = self.textField.sizeThatFits(CGSize(width: maxWidth, height: CGFloat.greatestFiniteMagnitude)).height
        
        let heightDelta = newHeight - oldHeight
        
        return heightDelta < 0 ? CardScrollViewCard.DefaultHeight : Float(self.bounds.size.height + heightDelta)
    }
    
    @IBAction func expandCell(_ sender: AnyObject) {
        if self.expanded {
            self.cardAction?(CardScrollViewCard.DefaultHeight)
        }
        else {
            self.cardAction?(self.calculateExpandedCellHeight())
        }
        
        self.expanded = !self.expanded
    }
}
