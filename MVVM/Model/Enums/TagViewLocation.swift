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
  case CustomLocation(point: CGPoint)
  case Default
  
 func shallowEquals(otherLocation: TagViewLocation) -> Bool {
    switch(self, otherLocation){
    case (.CustomLocation(_), .CustomLocation(_)),
         (.Default, .Default):
      return true
    case (.CustomLocation(_), _),
         (.Default, _):
      return false
    }
  }
  
  func deepEquals(otherLocation: TagViewLocation) -> Bool {
    switch(self, otherLocation){
    case (.CustomLocation(let point1), .CustomLocation(let point2)):
      return point1 == point2
    case (.Default, .Default):
      return true
    case (.CustomLocation(_), _),
         (.Default, _):
      return false
    }
  }
}

