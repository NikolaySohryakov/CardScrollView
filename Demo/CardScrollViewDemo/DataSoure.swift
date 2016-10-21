//
//  DataSoure.swift
//  CardScrollExample
//
//  Created by Nikolay Sohryakov on 08/10/2016.
//  Copyright © 2016 Nikolay Sohryakov. All rights reserved.
//

import UIKit
import CardScrollView

open class DataSoure: NSObject, CardScrollViewDataSource {
    fileprivate var data: [String] = {
        var result: [String] = []
        
        for i in 1...100 {
            let title = "Card \(i)"
            result.append(title)
        }
        
        return result
    }()
    
    public override init() {}
    
    open func numberOfCards() -> Int {
        return self.data.count
    }
    
    open func cardsCollection(cardsCollection:CardScrollView, cardAtIndex index: Int) -> CardScrollViewCard {
        guard let card = cardsCollection.dequeueСard(withIdentifier: "TextCard") as? TextCard else {
            fatalError("Could not dequeue cell")
        }
        
        card.header.text = self.data[index]
        
        card.cardAction = {[weak cardsCollection] (height: Float) -> Void in
            guard let collection = cardsCollection else {
                return
            }
            
            if height == CardScrollViewCard.DefaultHeight {
                collection.collapse(cardAtIndex: index, animated: true)
            }
            else {
                collection.expand(cardAtIndex: index, newHeight: height, animated: true)
            }
        }
        
        return card
    }
}
