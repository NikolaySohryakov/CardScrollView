//
//  CardScrollViewCard.swift
//  CardScrollExample
//
//  Created by Nikolay Sohryakov on 05/10/16.
//  Copyright © 2016 Nikolay Sohryakov. All rights reserved.
//

import UIKit

open class CardScrollViewCard: UIView {
    public static let DefaultHeight: Float = 0
    
    internal var separatorHeight: Float = 1
    
    private lazy var bottomSeparator: UIView = {
        var separator = UIView()
        
        separator.autoresizingMask = [.flexibleWidth, .flexibleTopMargin]
        separator.frame = CGRect(x: 0, y:self.bounds.size.height - 1 , width: self.bounds.size.width, height: CGFloat(self.separatorHeight))
        
        return separator
    }()
    
    internal var separatorColor: UIColor {
        get {
            return self.bottomSeparator.backgroundColor ?? UIColor.clear
        }
        set {
            self.bottomSeparator.backgroundColor = newValue
        }
    }
    
    @IBInspectable private(set) public var reuseIdentifier: String?
    
    required public init(reuseIdentifier: String) {
        self.reuseIdentifier = reuseIdentifier
        super.init(frame: CGRect.null)
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    open func prepareForReuse(willCollapse: Bool) {
    }
    
    internal func setSeparator(visible: Bool) {
        if visible {
            self.addSubview(self.bottomSeparator)
        }
        else {
            self.bottomSeparator.removeFromSuperview()
        }
    }
}
