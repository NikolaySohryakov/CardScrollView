//
//  CardScrollView.swift
//  CardScrollExample
//
//  Created by Nikolay Sohryakov on 05/10/16.
//  Copyright © 2016 Nikolay Sohryakov. All rights reserved.
//

import UIKit

// MARK: - Delegate

public protocol CardScrollViewDelegate {
    func cardCollection(cardsCollection: CardScrollView, estimatedHeightForCardAtIndex index: Int) -> Float?
}

// MARK: - Data Source

public protocol CardScrollViewDataSource {
    func numberOfCards() -> Int
    func cardsCollection(cardsCollection: CardScrollView, cardAtIndex index: Int) -> CardScrollViewCard
}

// MARK: - Card Scroll View

public class CardScrollView: UIScrollView {
    fileprivate enum ScrollDirection {
        case up // content is moving downwards
        case down // content is moving upwards
    }
    
    public enum Edge {
        case top
        case bottom
    }
    
    /// Concrete card descriptor that is used to cache a card-related data
    fileprivate struct CardDetails {
        var startPositionY: Float
        var height: Float
        weak var cachedСard: CardScrollViewCard? = nil
        
        init(startPositionY: Float, height: Float) {
            self.startPositionY = startPositionY
            self.height = height
        }
    }
    
    override open var contentOffset: CGPoint {
        didSet {
            self.layoutCards()
        }
    }
    
    // MARK: - Public Definitions

    public var cardScrollViewDelegate: CardScrollViewDelegate?

    public var cardScrollViewDataSource: CardScrollViewDataSource?

    /// A threshold that user should pass scrolling the content for scroll view to switch to another card
    public var scrollThreshold: Float = 150

    /// If true, then expanded card will be collapsed back to minimal size when scrolled out of the screen
    public var collapsecardsWhenHidden: Bool = true
    
    /// Expand/Collapse animation duration
    public var animationDuration: TimeInterval = 0.1
    
    public var separatorHeight: Float = 1
    
    public var separatorColor: UIColor = UIColor.gray
    
    // MARK: - Private Definitions
    
    fileprivate lazy var lastContentOffset: CGPoint = self.contentOffset
    fileprivate var lastScrollDirection: ScrollDirection?
    
    fileprivate lazy var reusePool: [CardScrollViewCard] = []
    fileprivate lazy var reuseIdentifiers: [String: Any] = [:]
    fileprivate lazy var cardsDetails: [CardDetails] = []
    fileprivate lazy var visibleCardsIndexes: Set<Int> = Set<Int>()
    
    /// Cards height is alwasy at lease the same as scroll view height
    fileprivate var minimalCardHeight: Float {
        get {
            return Float(self.bounds.height) + self.separatorHeight
        }
    }
    
    /// Last known scroll view frame before it was changed
    fileprivate var lastFrame: CGRect = CGRect()

    // MARK: - Initializers
    
    convenience init() {
        self.init(frame: CGRect.null)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setUpScrollView()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.setUpScrollView()
    }
    
    deinit {
        self.cardScrollViewDataSource = nil
        self.cardScrollViewDelegate = nil

        self.reusePool.removeAll()
        self.reuseIdentifiers.removeAll()
        self.cardsDetails.removeAll()
        self.visibleCardsIndexes.removeAll()
    }
    
    fileprivate func setUpScrollView() {
        self.delegate = self
        self.decelerationRate = UIScrollViewDecelerationRateFast
        self.isDirectionalLockEnabled = true
        self.translatesAutoresizingMaskIntoConstraints = false
    }
    
    override open func layoutSubviews() {
        super.layoutSubviews()
        
        if self.frame != self.lastFrame {
            self.lastFrame = self.frame
            self.handleFrameChange()
        }
    }
}

// MARK: - Reuse Logic

extension CardScrollView {
    // MARK: - private
    
    /// Extract card from a reuse pool and prepare it for reuse.
    ///
    /// - parameter reuseIdentifier: Reuse identifier for card.
    ///
    /// - returns: card if it was found in reuse pool, nil otherwise.
    fileprivate func reuseCard(reuseIdentifier: String) -> CardScrollViewCard? {
        guard self.reuseIdentifiers[reuseIdentifier] != nil else {
            fatalError("Identifier \(reuseIdentifier) is not registered")
        }
        
        var resultingcard: CardScrollViewCard? = nil
        
        let availablecards = self.reusePool.filter { $0.reuseIdentifier == reuseIdentifier }
        
        if availablecards.count > 0 {
            resultingcard = availablecards.first
            
            let index = self.reusePool.index { $0 == resultingcard }
            
            guard let unwrappedIndex = index else {
                fatalError("Internal inconsistency error")
            }
            
            self.reusePool.remove(at: unwrappedIndex)
        }
        
        resultingcard?.prepareForReuse(willCollapse: self.collapsecardsWhenHidden)
        
        return resultingcard
    }
    
    /// Try to retrieve a card view object at specified index from cache and if it's not there,
    /// request a new one from data source.
    ///
    /// - parameter index: Index of a card.
    ///
    /// - returns: Card object if found in cache or returned by data source, nil otherwise.
    fileprivate func prepareCard(atIndex index: Int) -> CardScrollViewCard? {
        guard index < self.cardsDetails.count else {
            fatalError("Internal inconsistency error")
        }
        
        guard let card = self.cardsDetails[index].cachedСard else {
            return self.cardScrollViewDataSource?.cardsCollection(cardsCollection: self, cardAtIndex: index)
        }
        
        card.separatorColor = self.separatorColor
        card.setSeparator(visible: true)
        
        return card
    }
    
    /// Move a card at specified index to the reuse pool.
    ///
    /// - parameter index: Index of a card.
    fileprivate func recycleCard(atIndex index: Int) {
        guard index < self.cardsDetails.count, index > 0,
              let cachedCard = self.cardsDetails[index].cachedСard else {
            return
        }
        
        self.reusePool.append(cachedCard)
        cachedCard.removeFromSuperview()
        self.cardsDetails[index].cachedСard = nil
        
        if self.collapsecardsWhenHidden {
            self.collapse(cardAtIndex: index, animated: false)
        }
    }
    
    /// Pass through all the cards that are gone off the screen and move them to the reuse pool.
    ///
    /// - parameter indexes: indexes of cards that are currently on the screen.
    fileprivate func recycleNotVisibleCards(withVisibleCardsIndexes indexes: Set<Int>) {
        self.visibleCardsIndexes.subtract(indexes)
        for cardIndex in self.visibleCardsIndexes {
            guard self.cardsDetails[cardIndex].cachedСard != nil else {
                continue
            }
            
            self.recycleCard(atIndex: cardIndex)
        }
        
        self.visibleCardsIndexes = indexes
    }
    
    // MARK: - public
    
    /// Reload all cards.
    public func reloadData() {
        self.recycleNotVisibleCards(withVisibleCardsIndexes:[])
        self.setUpHeightAndOffsetData()
        self.layoutCards()
    }
    
    
    /// Register a card class with reuse identifier.
    ///
    /// - parameter aClass:          a class object for the card.
    /// - parameter reuseIdentifier: reuse identifier for the card.
    public func register(class aClass: CardScrollViewCard.Type, forReuseIdentifier reuseIdentifier: String) {
        guard self.reuseIdentifiers[reuseIdentifier] == nil else {
            fatalError("Reuse Identifier \(reuseIdentifier) is already registered for \(self.reuseIdentifiers[reuseIdentifier])")
        }
        
        self.reuseIdentifiers[reuseIdentifier] = aClass
    }
    
    /// Register a nib object with reuse identifier.
    ///
    /// - parameter nib:             nib object for the card.
    /// - parameter reuseIdentifier: reuse identifier for the card.
    public func register(nib: UINib, forReuseIdentifier reuseIdentifier: String) {
        guard self.reuseIdentifiers[reuseIdentifier] == nil else {
            fatalError("Reuse Identifier \(reuseIdentifier) is already registered for \(self.reuseIdentifiers[reuseIdentifier])")
        }
        
        self.reuseIdentifiers[reuseIdentifier] = nib
    }
    
    /// Dequeue a card from the reuse pool with specified reuse identifier.
    ///
    /// - parameter reuseIdentifier: Reuse identifier for a card.
    ///
    /// - returns: Card view object.
    public func dequeueСard(withIdentifier reuseIdentifier: String) -> CardScrollViewCard {
        guard self.reuseIdentifiers[reuseIdentifier] != nil else {
            fatalError("Identifier \(reuseIdentifier) is not registered")
        }
        
        guard let reusedcard = self.reuseCard(reuseIdentifier: reuseIdentifier) else {
            let cardObject = self.reuseIdentifiers[reuseIdentifier]
            
            switch cardObject {
            case let nib as UINib:
                guard let unwrappedView = nib.instantiate(withOwner: nil, options: nil).first as? CardScrollViewCard else {
                    fatalError("Expected to receive \(String(describing: CardScrollViewCard.self)) but got something else")
                }
                return unwrappedView
            case let classObject as CardScrollViewCard.Type: //TODO: wrong case let condition
                return classObject.init(reuseIdentifier: reuseIdentifier)
            default:
                fatalError("card reuse identifier is not registered")
            }
        }
        
        return reusedcard
    }
    
    /// Get a list of all currently visible cards.
    ///
    /// - returns: an array ob visible CardScrollViewcard objects
    public func visibleCards() -> [CardScrollViewCard] {
        var resultingcards: [CardScrollViewCard] = []
        for cardIndex in self.visibleCardsIndexes {
            guard let unwrappedCard = self.cardsDetails[cardIndex].cachedСard else {
                fatalError("Internal inconsistency error")
            }
            
            resultingcards.append(unwrappedCard)
        }
        
        return resultingcards
    }
    
    /// Scroll to a card at index.
    ///
    /// - parameter index: Index of a card.
    /// - parameter edge:  Edge where card will snap.
    public func scrollToCard(atIndex index: Int, snapToEdge edge: Edge = .top) {
        guard index < self.cardsDetails.count else {
            return
        }
        
        var yPosition = self.cardsDetails[index].startPositionY
        
        switch edge {
        case .top:
            //don't need to adjust
            break
        case .bottom:
            yPosition += Float(abs(CGFloat(self.cardsDetails[index].height) - self.bounds.height))
        }
        
        self.setContentOffset(CGPoint(x: CGFloat(0), y: CGFloat(yPosition)), animated: true)
    }
}

// MARK: - Layout logic

extension CardScrollView {
    // MARK: - Public
    
    /// Expand card vertically.
    ///
    /// - parameter index:     Index of a card.
    /// - parameter newHeight: New card height. If less than minimal allowed, then minimal value will be used.
    /// - parameter animated:  Should animate expanding or not.
    public func expand(cardAtIndex index:Int, newHeight: Float, animated: Bool) {
        guard index < self.cardsDetails.count, index > 0 else {
            return
        }
        
        self.setCardHeight(newHeight: newHeight, atIndex: index, animated: animated) //TODO: check the animation
    }
    
    /// Collapse the card vertically to minimal height value.
    ///
    /// - parameter index:    Index of a card.
    /// - parameter animated: Should animate collapsing or nor.
    public func collapse(cardAtIndex index:Int, animated: Bool) {
        guard index < self.cardsDetails.count, index > 0 else {
            return
        }
        
        self.setCardHeight(newHeight: self.minimalCardHeight, atIndex: index, animated: animated)
    }
    
    // MARK: - Private
    
    /// Reset cache when scroll view frame changed and relayout cards inside.
    fileprivate func handleFrameChange() {
        guard let activeCardIndex = self.visibleCardsIndexes.first else {
            self.setUpHeightAndOffsetData()
            return
        }
        
        self.setUpHeightAndOffsetData()
        self.layoutCards()
        self.scrollToCard(atIndex: activeCardIndex)
    }
    
    /// Set card height.
    ///
    /// - parameter newHeight: New card height.
    /// - parameter index:     Index of a card.
    /// - parameter animated:  Should animate change or not.
    fileprivate func setCardHeight(newHeight: Float, atIndex index: Int, animated: Bool) {
        guard index < self.cardsDetails.count, index > 0 else {
            return
        }
        
        let delta = newHeight - self.cardsDetails[index].height
        
        guard delta != 0 else {
            //nothing to collapse/expand
            return
        }
        
        self.cardsDetails[index].height = newHeight
        
        let nextCardIndex = index + 1
        for cardIndex in nextCardIndex..<self.cardsDetails.count {
            self.cardsDetails[cardIndex].startPositionY += delta
        }
        
        var newContentSize = self.contentSize
        newContentSize.height += CGFloat(delta)
        
        if !animated {
            if delta < 0 && self.contentOffset.y != 0 {
                self.contentOffset.y += CGFloat(delta)
            }
        }
        
        if let reuseCard = self.cardsDetails[index].cachedСard {
            var newFrame = reuseCard.frame
            newFrame.size.height += CGFloat(delta)
            
            if animated {
                let animations = {() -> Void in
                    reuseCard.frame = newFrame
                    reuseCard.layoutIfNeeded()
                    
                    self.contentOffset.y = CGFloat(self.cardsDetails[index].startPositionY)
                }
                
                let completion = {(completed: Bool) -> Void in
                    self.contentSize = newContentSize
                }
                
                UIView.animate(withDuration: self.animationDuration, animations: animations, completion: completion)
            }
            else {
                UIView.performWithoutAnimation {
                    reuseCard.frame = newFrame
                    self.contentOffset.y = CGFloat(self.cardsDetails[index].startPositionY)
                    self.contentSize = newContentSize
                }
            }
        }
    }
    
    /// Calculate heights and offsets for cards and cache these values.
    fileprivate func setUpHeightAndOffsetData() {
        var currentOffset: Float = 0.0

        let numberOfCards = self.cardScrollViewDataSource?.numberOfCards() ?? 0
        
        var cardsDetails: [CardDetails] = []
        
        for i in 0..<numberOfCards {
            var estimatedCardHeight = self.cardScrollViewDelegate?.cardCollection(cardsCollection: self, estimatedHeightForCardAtIndex: i) ?? 0
            if estimatedCardHeight < self.minimalCardHeight {
                estimatedCardHeight = self.minimalCardHeight
            }
            
            cardsDetails.append(CardDetails(startPositionY: currentOffset, height: estimatedCardHeight))
            
            currentOffset += estimatedCardHeight
        }
        
        self.cardsDetails = cardsDetails
        self.contentSize = CGSize(width: 0, height: CGFloat(currentOffset))
    }
    
    /// Find a card index at specified offset.
    ///
    /// - parameter y:     Offset.
    /// - parameter range: Range of cards where to perform a search.
    ///
    /// - returns: Index of a card if found, nil otherwise.
    fileprivate func cardIndex(yOffset y: Float, inRange range: Range<Int>) -> Int? {
        guard !range.isEmpty else {
            return nil
        }
        
        var cardIndex = range.lowerBound
        
        while cardIndex < range.upperBound {
            guard cardIndex < self.cardsDetails.count else {
                return nil
            }
            
            if y < self.cardsDetails[cardIndex].startPositionY {
                return (cardIndex < 1) ? cardIndex : cardIndex - 1
            }
            
            cardIndex += 1
        }
        cardIndex -= 1
        
        return cardIndex
    }
    
    /// Layout all the cards in the scroll view.
    fileprivate func layoutCards() {
        let currentStartY: Float = Float(self.contentOffset.y)
        let currentEndY: Float = currentStartY + Float(self.bounds.size.height)
        
        guard var cardIndexToDisplay = self.cardIndex(yOffset: currentStartY, inRange: 0..<self.cardsDetails.count) else {
            //nothing to layout
            return
        }
        
        var newVisibleCards: Set<Int> = Set<Int>()
        
        let xOrigin: Float = 0
        var yOrigin: Float = 0
        var cardHeight: Float = 0
        
        repeat {
            guard let card = self.prepareCard(atIndex: cardIndexToDisplay) else {
                fatalError("Could not get a card")
            }
            
            newVisibleCards.insert(cardIndexToDisplay)
            self.cardsDetails[cardIndexToDisplay].cachedСard = card
            
            yOrigin = self.cardsDetails[cardIndexToDisplay].startPositionY
            cardHeight = self.cardsDetails[cardIndexToDisplay].height
            card.frame = CGRect(x: CGFloat(xOrigin), y: CGFloat(yOrigin), width: CGFloat(self.bounds.size.width), height: CGFloat(cardHeight))
            
            self.addSubview(card)
            
            cardIndexToDisplay += 1
        } while yOrigin + cardHeight < currentEndY && cardIndexToDisplay < self.cardsDetails.count
        
        self.recycleNotVisibleCards(withVisibleCardsIndexes: newVisibleCards)
    }
    
    /// Depending on the current offset and cards position, adjust offset to have one card on the screen.
    fileprivate func adjustScrollOffset() {
        guard self.visibleCardsIndexes.count > 1 else {
            //no need to adjust something if there is only 1 visible card
            return
        }
        
        guard self.visibleCardsIndexes.count <= 2 else {
            fatalError("Internal inconsistency error. There are \(self.visibleCardsIndexes.count) cards visible at the same time.")
        }
        
        let sortedCardsIndexes = self.visibleCardsIndexes.sorted(by: {(lhs: Int, rhs: Int) -> Bool in
            return lhs < rhs
        })
        
        guard let firstCardIndex = sortedCardsIndexes.first,
              let secondCardIndex = sortedCardsIndexes.last else {
            fatalError("Internal inconsistency error. Exactly 2 cards should be visible at the same time.")
        }
        
        var cardIndexToFocus: Int?
        
        let scrollDelta = Float(abs(self.contentOffset.y - self.lastContentOffset.y))
        var edgeToSnap: Edge = .top
        
        if scrollDelta > self.scrollThreshold {
            switch self.lastScrollDirection {
            case .down?:
                cardIndexToFocus = secondCardIndex
                edgeToSnap = .bottom
            case .up?:
                cardIndexToFocus = firstCardIndex
            default:
                break
            }
        }
        else {
            switch self.lastScrollDirection {
            case .down?:
                cardIndexToFocus = firstCardIndex
                edgeToSnap = .bottom
            case .up?:
                cardIndexToFocus = secondCardIndex
            default:
                break
            }
        }
        
        if let unwrappedCardIndex = cardIndexToFocus {
            self.scrollToCard(atIndex: unwrappedCardIndex, snapToEdge: edgeToSnap)
        }
    }
}

// MARK: - UIScrollView Delegate

extension CardScrollView: UIScrollViewDelegate {
    public func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        self.lastContentOffset = scrollView.contentOffset
    }
    
    public func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        let scrollDelta = Float(targetContentOffset.pointee.y - self.lastContentOffset.y)
        let scrollDirection = scrollDelta > 0 ? ScrollDirection.down : ScrollDirection.up
        self.lastScrollDirection = scrollDirection
        
        guard self.visibleCardsIndexes.count > 1 else {
            return
        }
        
        guard self.visibleCardsIndexes.count <= 2 else {
            fatalError("Internal inconsistency error. There are \(self.visibleCardsIndexes.count) cards visible at the same time.")
        }
        
        let sortedCardsIndexes = self.visibleCardsIndexes.sorted(by: {(lhs: Int, rhs: Int) -> Bool in
            return lhs < rhs
        })
        
        guard let firstCardIndex = sortedCardsIndexes.first,
              let secondCardIndex = sortedCardsIndexes.last else {
                fatalError("Internal inconsistency error. Exactly 2 cards should be visible at the same time.")
        }
        
        var cardIndexToFocus: Int
        var offsetAdjustent: Float = 0
        
        if abs(scrollDelta) > self.scrollThreshold {
            switch scrollDirection {
            case .down:
                cardIndexToFocus = secondCardIndex
            case .up:
                cardIndexToFocus = firstCardIndex
                offsetAdjustent = Float(abs(CGFloat(self.cardsDetails[cardIndexToFocus].height) - scrollView.bounds.height))
            }
        }
        else {
            switch scrollDirection {
            case .down:
                cardIndexToFocus = firstCardIndex
                offsetAdjustent = Float(abs(CGFloat(self.cardsDetails[cardIndexToFocus].height) - scrollView.bounds.height))
            case .up:
                cardIndexToFocus = secondCardIndex
            }
        }
        
        targetContentOffset.pointee.y = CGFloat(self.cardsDetails[cardIndexToFocus].startPositionY + offsetAdjustent)
    }
    
    public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            self.adjustScrollOffset()
        }
    }
    
    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        self.lastContentOffset = scrollView.contentOffset
        
        self.adjustScrollOffset()
    }
}
