//
//  PassThroughView.swift
//  Roll
//
//  Created by Ben Garrett on 10/28/14.
//  Copyright (c) 2014 Mathcamp. All rights reserved.
//

import UIKit

public class PassThroughView: UIView {
  
  public override func hitTest(point: CGPoint,
                               withEvent event: UIEvent!) -> UIView? {
    if let hitView = super.hitTest(point, withEvent:event) {
      if hitView == self {
        return nil
      }
      return hitView
    }
    return nil
  }
}
