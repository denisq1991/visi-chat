//
//  KoladaView.swift
//  nv-comms
//
//  Created by Denis Quaid on 21/04/2017.
//  Copyright © 2017 dquaid. All rights reserved.
//

import Foundation
import Koloda

// MARK: - Kolada Delegate & DataSource

extension ViewController: KolodaViewDelegate {
    
    func kolodaDidRunOutOfCards(_ koloda: KolodaView) {
        self.kolodaView.resetCurrentCardIndex()
    }
    
    func kolodaShouldApplyAppearAnimation(_ koloda: KolodaView) -> Bool {
        return false
    }
    
    func kolodaShouldMoveBackgroundCard(_ koloda: KolodaView) -> Bool {
        return false
    }
}

extension ViewController: KolodaViewDataSource {
    public func kolodaSpeedThatCardShouldDrag(_ koloda: KolodaView) -> DragSpeed {
        return .default
    }
    
    
    func kolodaNumberOfCards(_ koloda:KolodaView) -> Int {
        return self.items.count
    }
    
    func koloda(_ koloda: KolodaView, viewForCardAt index: Int) -> UIView {
        let item = self.items[index]
        guard let title = item.value(forKeyPath: "title") as? String,
            let date = item.value(forKeyPath: "date") as? Date else {
                return UITableViewCell()
        }
        
        let swipeCard = Bundle.main.loadNibNamed("SwipeCardView", owner: self, options: nil)?[0] as! SwipeCardView
        guard let imageView = swipeCard.imageView,
            let daysLabel = swipeCard.daysLabel else {
                return UIView()
        }
        
        if date.daysFromToday().range(of:"-") != nil{
            swipeCard.daysToGoLabel?.text = "days ago"
        }
        daysLabel.text = date.daysFromToday().replacingOccurrences(of: "-", with: "", options: .literal, range: nil)
        imageView.image = title.loadImageFromPath()
        
        return swipeCard
    }
    
    func koloda(koloda: KolodaView, viewForCardOverlayAt index: Int) -> OverlayView? {
        return Bundle.main.loadNibNamed("OverlayView", owner: self, options: nil)?[0] as? OverlayView
    }
}
