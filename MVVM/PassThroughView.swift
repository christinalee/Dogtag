//
//  PassThroughView.swift
//  Roll
//
//  Created by Ben Garrett on 10/28/14.
//  Copyright (c) 2014 Mathcamp. All rights reserved.
//

import UIKit

open class PassThroughView: UIView {
  
  open override func hitTest(_ point: CGPoint,
                               with event: UIEvent!) -> UIView? {
    if let hitView = super.hitTest(point, with:event) {
      if hitView == self {
        return nil
      }
      return hitView
    }
    return nil
  }
}
