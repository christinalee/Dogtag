//
//  TagViewLocation.swift
//  MVVM
//
//  Created by Christina on 6/22/16.
//  Copyright © 2016 Christina. All rights reserved.
//

import Foundation
import UIKit

public enum TagViewLocation {
  case customLocation(point: CGPoint)
  case `default`
  
 func shallowEquals(_ otherLocation: TagViewLocation) -> Bool {
    switch(self, otherLocation){
    case (.customLocation(_), .customLocation(_)),
         (.default, .default):
      return true
    case (.customLocation(_), _),
         (.default, _):
      return false
    }
  }
  
  func deepEquals(_ otherLocation: TagViewLocation) -> Bool {
    switch(self, otherLocation){
    case (.customLocation(let point1), .customLocation(let point2)):
      return point1 == point2
    case (.default, .default):
      return true
    case (.customLocation(_), _),
         (.default, _):
      return false
    }
  }
}

