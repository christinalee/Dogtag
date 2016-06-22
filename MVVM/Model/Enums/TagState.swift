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
  case None
  case DeleteMode
  case Deleted
  case Panning(locationInView: CGPoint)
  case Liked(tagLocation: CGPoint)
  case Created
  case Updated
  
  //this is a shallow equals and ignores enum args
  func shallowEquals(otherState: TagState) -> Bool {
    switch (self, otherState) {
    case (.None, .None),
         (.DeleteMode, .DeleteMode),
         (.Deleted, .Deleted),
         (.Panning, .Panning),
         (.Liked, .Liked),
         (.Created, .Created),
         (.Updated, .Updated):
      return true
    case (.None, _),
         (.DeleteMode, _),
         (.Deleted, _),
         (.Panning(_), _),
         (.Liked(_), _),
         (.Created, _),
         (.Updated, _):
      return false
    }
  }
  
  func deepEquals(otherState: TagState) -> Bool {
    switch (self, otherState) {
    case (.None, .None),
         (.DeleteMode, .DeleteMode),
         (.Deleted, .Deleted),
         (.Created, .Created),
         (.Updated, .Updated):
      return true
    case (.Panning(let location), .Panning(let location2)):
      return location == location2
    case (.Liked(let location), .Liked(let location2)):
      return location == location2
    case (.None, _),
         (.DeleteMode, _),
         (.Deleted, _),
         (.Panning(_), _),
         (.Liked(_), _),
         (.Created, _),
         (.Updated, _):
      return false
    }
  }
}

