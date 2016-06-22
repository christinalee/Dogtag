//
//  TagVCMode.swift
//  MVVM
//
//  Created by Christina on 6/22/16.
//  Copyright © 2016 Christina. All rights reserved.
//

import Foundation

public enum TagVCMode {
  case Tagging(text: String, location: TagViewLocation?)
  case TaggingAndMentioning(text: String, searchQuery: String, location: TagViewLocation?)
  case DeletingTag
  case None
  
  func shallowEquals(otherMode: TagVCMode) -> Bool {
    switch(self, otherMode) {
    case (.Tagging(_, _), .Tagging(_, _)),
         (.TaggingAndMentioning(_, _, _), .TaggingAndMentioning(_, _, _)),
         (.DeletingTag, .DeletingTag),
         (.None, .None):
      return true
    case (.Tagging(_, _), _),
         (.TaggingAndMentioning(_, _, _), _),
         (.DeletingTag, _),
         (.None, _):
      return false
    }
  }
  
  func deepEquals(otherMode: TagVCMode) -> Bool {
    switch(self, otherMode) {
    case (.Tagging(let text1, let location1), .Tagging(let text2, let location2)):
      switch(location1, location2){
      case (.Some(let sLocation1), .Some(let sLocation2)):
        return text1 == text2 && sLocation1.deepEquals(sLocation2)
      case (.None, .None):
        return true
      case (.Some(_), _),
           (.None, _):
        return false
      }
    case (.TaggingAndMentioning(let text1, let searchString1, let location1), .TaggingAndMentioning(let text2, let searchString2, let location2)):
      switch(location1, location2){
      case (.Some(let sLocation1), .Some(let sLocation2)):
        return text1 == text2 && searchString1 == searchString2 && sLocation1.deepEquals(sLocation2)
      case (.None, .None):
        return true
      case (.Some(_), _),
           (.None, _):
        return false
      }
    case (.DeletingTag, .DeletingTag),
         (.None, .None):
      return true
    case (.Tagging(_, _), _),
         (.TaggingAndMentioning(_, _, _), _),
         (.DeletingTag, _),
         (.None, _):
      return false
    }
  }
}

