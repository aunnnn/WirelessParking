//
//  BoardView.swift
//  WirelessParking
//
//  Created by Wirawit Rueopas on 11/9/2558 BE.
//  Copyright © 2558 Wirawit Rueopas. All rights reserved.
//

import UIKit

class BoardView: UIView {

    var availableSpaces: [CGPoint]
    let spacing: CGFloat = 2
    init(availableSpaces: [CGPoint]) {
        self.availableSpaces = availableSpaces
        super.init(frame: CGRectZero)
    }

    required init?(coder aDecoder: NSCoder) {
        availableSpaces = []
        super.init(coder: aDecoder)
    }
    // Only override drawRect: if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func drawRect(rect: CGRect) {
        // Drawing code
        guard let cntx = UIGraphicsGetCurrentContext() else {
            return
        }
        CGContextSetFillColorWithColor(cntx, UIColor.lightGrayColor().CGColor)
        CGContextFillRect(cntx, rect)
        let ratioW = rect.width/600.0
        let ratioH = rect.height/600.0
        CGContextSetFillColorWithColor(cntx, UIColor.greenColor().CGColor)
        for var i = 0; i < availableSpaces.count; i++ {
            let cur = availableSpaces[i]
            let pointrect = CGRect(x: cur.x*ratioW, y: cur.y*ratioH, width: 10, height: 10)
            CGContextFillEllipseInRect(cntx, pointrect)
            
        }
    }


}
