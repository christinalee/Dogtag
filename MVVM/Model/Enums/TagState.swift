//
//  TagState.swift
//  MVVM
//
//  Created by Christina on 6/22/16.
//  Copyright © 2016 Christina. All rights reserved.
//

import Foundation
import UIKit

public enum TagState {
  case none
  case deleteMode
  case deleted
  case panning(locationInView: CGPoint)
  case liked(tagLocation: CGPoint)
  case created
  case updated
  
  //this is a shallow equals and ignores enum args
  func shallowEquals(_ otherState: TagState) -> Bool {
    switch (self, otherState) {
    case (.none, .none),
         (.deleteMode, .deleteMode),
         (.deleted, .deleted),
         (.panning, .panning),
         (.liked, .liked),
         (.created, .created),
         (.updated, .updated):
      return true
    case (.none, _),
         (.deleteMode, _),
         (.deleted, _),
         (.panning(_), _),
         (.liked(_), _),
         (.created, _),
         (.updated, _):
      return false
    }
  }
  
  func deepEquals(_ otherState: TagState) -> Bool {
    switch (self, otherState) {
    case (.none, .none),
         (.deleteMode, .deleteMode),
         (.deleted, .deleted),
         (.created, .created),
         (.updated, .updated):
      return true
    case (.panning(let location), .panning(let location2)):
      return location == location2
    case (.liked(let location), .liked(let location2)):
      return location == location2
    case (.none, _),
         (.deleteMode, _),
         (.deleted, _),
         (.panning(_), _),
         (.liked(_), _),
         (.created, _),
         (.updated, _):
      return false
    }
  }
}

