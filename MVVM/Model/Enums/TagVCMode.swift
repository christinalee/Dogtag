//
//  TagVCMode.swift
//  MVVM
//
//  Created by Christina on 6/22/16.
//  Copyright © 2016 Christina. All rights reserved.
//

import Foundation

public enum TagVCMode {
  case tagging(text: String, location: TagViewLocation?)
  case taggingAndMentioning(text: String, searchQuery: String, location: TagViewLocation?)
  case deletingTag
  case none
  
  func shallowEquals(_ otherMode: TagVCMode) -> Bool {
    switch(self, otherMode) {
    case (.tagging(_, _), .tagging(_, _)),
         (.taggingAndMentioning(_, _, _), .taggingAndMentioning(_, _, _)),
         (.deletingTag, .deletingTag),
         (.none, .none):
      return true
    case (.tagging(_, _), _),
         (.taggingAndMentioning(_, _, _), _),
         (.deletingTag, _),
         (.none, _):
      return false
    }
  }
  
  func deepEquals(_ otherMode: TagVCMode) -> Bool {
    switch(self, otherMode) {
    case (.tagging(let text1, let location1), .tagging(let text2, let location2)):
      switch(location1, location2){
      case (.some(let sLocation1), .some(let sLocation2)):
        return text1 == text2 && sLocation1.deepEquals(sLocation2)
      case (.none, .none):
        return true
      case (.some(_), _),
           (.none, _):
        return false
      }
    case (.taggingAndMentioning(let text1, let searchString1, let location1), .taggingAndMentioning(let text2, let searchString2, let location2)):
      switch(location1, location2){
      case (.some(let sLocation1), .some(let sLocation2)):
        return text1 == text2 && searchString1 == searchString2 && sLocation1.deepEquals(sLocation2)
      case (.none, .none):
        return true
      case (.some(_), _),
           (.none, _):
        return false
      }
    case (.deletingTag, .deletingTag),
         (.none, .none):
      return true
    case (.tagging(_, _), _),
         (.taggingAndMentioning(_, _, _), _),
         (.deletingTag, _),
         (.none, _):
      return false
    }
  }
}

