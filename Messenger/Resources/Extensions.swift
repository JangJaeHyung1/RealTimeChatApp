//
//  Extensions.swift
//  Messenger
//
//  Created by jh on 2021/03/02.
//

import Foundation
import UIKit

extension UIView{
    public var width: CGFloat{
        return self.frame.size.width
    }
    public var height: CGFloat{
        return self.frame.size.height
    }
    public var top: CGFloat{
        return self.frame.origin.y
    }
    public var bottom: CGFloat{
        return self.frame.origin.y + self.frame.size.height
    }
    public var left: CGFloat{
        return self.frame.origin.x
    }
    public var right: CGFloat{
        return self.frame.size.width + self.frame.origin.x
    }
}

extension Notification.Name{
    static let didLogInNotification = Notification.Name("didLogInNotification")
}
