//
//  TextChangedHelper.swift
//  yaroll
//
//  Created by Christina on 5/31/16.
//  Copyright © 2016 Math Camp. All rights reserved.
//

import Foundation

public enum TextChange {
  case NewLine
  case AddedText(text: String)
  case DeletedChar
}

struct TextChangedHelper {
  typealias State = ConcreteTagModel.State
  
  static var MAX_TAG_LENGTH = 70
  
  static func handleNewLine(state: State) -> State {
    switch(state.mode){
    case .Tagging(let text, let location):
      let trimmedText = text.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
      if !trimmedText.isEmpty {
        let newTag = TagCreationHelper.makeNewTag(trimmedText, location: location)
        let newSyncReq = SyncRequirement.Update(action: .Create)
        let newTagData = TagViewData.UserCreatedTag(tagInfo: newTag, state: .Created, syncRequirement: newSyncReq)
        
        var newDict = state.tags
        newDict[newTagData.id] = newTagData
        return ConcreteTagModel.State(mode: .None, photoId: state.photoId, tags: newDict)
      }
      return ConcreteTagModel.State(mode: .None, photoId: state.photoId, tags: state.tags)
    case .TaggingAndMentioning(_, _, _):
      //todo: create a new tag
      return ConcreteTagModel.State(mode: .None, photoId: state.photoId, tags: state.tags)
    case .DeletingTag, .None:
      //todo: figure out why we're hitting this case
      print("trying to change tag text from \(state.mode) mode, which should not be possible c")
      return state
      //fatalError("trying to change tag text from \(state.mode) mode, which should not be possible")
    }
  }
  
  
  //      case "": //deletion
//        let lastWord = textView.text.characters.split {$0 == " "}.map { String($0) }.last
//        if let lastWord = lastWord {
//          if lastWord.characters.first == "@" {
//            self.setTableHidden(false, animated: true)
//          }
//        }
//        if textView.text.characters.last == "@" {
//          self.setTableHidden(true, animated: true)
//        }

  static func handleDeletion(state: State) -> State {
    //todo: handle whole word deletion in taggingAndMentioning case
    switch(state.mode){
    case .Tagging(let text, let location):
      let newText: String = String(text.characters.dropLast())
      return State(mode: .Tagging(text: newText, location: location), photoId: state.photoId, tags: state.tags)
    case .TaggingAndMentioning(let text, let searchQuery, let location):
      let newText: String = String(text.characters.dropLast())
      let newSearchQuery: String = String(searchQuery.characters.dropLast())
      
      if (text.characters.last == "@") {
        return State(mode: .Tagging(text: newText, location: location), photoId: state.photoId, tags: state.tags)
      }
      return State(mode: .TaggingAndMentioning(text: newText, searchQuery: newSearchQuery, location: location), photoId: state.photoId, tags: state.tags)
    case .DeletingTag, .None:
      //todo: figure out why we're hitting this case
      print("trying to change tag text from \(state.mode) mode, which should not be possible b")
      return state
    }
  }
  
  static func handleAddText(state: State, addedText: String) -> State {
    //todo: guard length!
    
    switch(state.mode){
    case .Tagging(let text, let location):
      if text.characters.count >= self.MAX_TAG_LENGTH { return state }
      
      let newText: String = text + addedText
      if addedText == "@" {
        let newSearchQuery: String = ""
        return State(mode: .TaggingAndMentioning(text: newText, searchQuery: newSearchQuery, location: location), photoId: state.photoId, tags: state.tags)
      }
      return State(mode: .Tagging(text: newText, location: location), photoId: state.photoId, tags: state.tags)
      
    case .TaggingAndMentioning(let text, let searchQuery, let location):
      if text.characters.count >= self.MAX_TAG_LENGTH { return state }
      
      let newText: String = text + addedText
      let newSearchQuery: String = searchQuery + addedText
      
      if addedText.characters.last == " " {
        return State(mode: .Tagging(text: newText, location: location), photoId: state.photoId, tags: state.tags)
      }
      return State(mode: .TaggingAndMentioning(text: newText, searchQuery: newSearchQuery, location: location), photoId: state.photoId, tags: state.tags)
      
    case .DeletingTag, .None:
      //todo: figure out why we're hitting this case
      print("trying to change tag text from \(state.mode) mode, which should not be possible a")
      return state
    }
  }
}