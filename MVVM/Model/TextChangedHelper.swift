//
//  TextChangedHelper.swift
//  yaroll
//
//  Created by Christina on 5/31/16.
//  Copyright © 2016 Math Camp. All rights reserved.
//

import Foundation

public enum TextChange {
  case newLine
  case addedText(text: String)
  case deletedChar
}

struct TextChangedHelper {
  typealias State = ConcreteTagModel.State
  
  static var MAX_TAG_LENGTH = 70
  
  static func handleNewLine(_ state: State) -> State {
    switch(state.mode){
    case .tagging(let text, let location):
      let trimmedText = text.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
      if !trimmedText.isEmpty {
        let newTag = TagCreationHelper.makeNewTag(trimmedText, location: location)
        let newSyncReq = SyncRequirement.update(action: .Create)
        let newTagData = TagViewData.userCreatedTag(tagInfo: newTag, state: .created, syncRequirement: newSyncReq)
        
        var newDict = state.tags
        newDict[newTagData.id] = newTagData
        return ConcreteTagModel.State(mode: .none, photoId: state.photoId, tags: newDict)
      }
      return ConcreteTagModel.State(mode: .none, photoId: state.photoId, tags: state.tags)
    case .taggingAndMentioning(_, _, _):
      //todo: create a new tag
      return ConcreteTagModel.State(mode: .none, photoId: state.photoId, tags: state.tags)
    case .deletingTag, .none:
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

  static func handleDeletion(_ state: State) -> State {
    //todo: handle whole word deletion in taggingAndMentioning case
    switch(state.mode){
    case .tagging(let text, let location):
      let newText: String = String(text.characters.dropLast())
      return State(mode: .tagging(text: newText, location: location), photoId: state.photoId, tags: state.tags)
    case .taggingAndMentioning(let text, let searchQuery, let location):
      let newText: String = String(text.characters.dropLast())
      let newSearchQuery: String = String(searchQuery.characters.dropLast())
      
      if (text.characters.last == "@") {
        return State(mode: .tagging(text: newText, location: location), photoId: state.photoId, tags: state.tags)
      }
      return State(mode: .taggingAndMentioning(text: newText, searchQuery: newSearchQuery, location: location), photoId: state.photoId, tags: state.tags)
    case .deletingTag, .none:
      //todo: figure out why we're hitting this case
      print("trying to change tag text from \(state.mode) mode, which should not be possible b")
      return state
    }
  }
  
  static func handleAddText(_ state: State, addedText: String) -> State {
    //todo: guard length!
    
    switch(state.mode){
    case .tagging(let text, let location):
      if text.characters.count >= self.MAX_TAG_LENGTH { return state }
      
      let newText: String = text + addedText
      if addedText == "@" {
        let newSearchQuery: String = ""
        return State(mode: .taggingAndMentioning(text: newText, searchQuery: newSearchQuery, location: location), photoId: state.photoId, tags: state.tags)
      }
      return State(mode: .tagging(text: newText, location: location), photoId: state.photoId, tags: state.tags)
      
    case .taggingAndMentioning(let text, let searchQuery, let location):
      if text.characters.count >= self.MAX_TAG_LENGTH { return state }
      
      let newText: String = text + addedText
      let newSearchQuery: String = searchQuery + addedText
      
      if addedText.characters.last == " " {
        return State(mode: .tagging(text: newText, location: location), photoId: state.photoId, tags: state.tags)
      }
      return State(mode: .taggingAndMentioning(text: newText, searchQuery: newSearchQuery, location: location), photoId: state.photoId, tags: state.tags)
      
    case .deletingTag, .none:
      //todo: figure out why we're hitting this case
      print("trying to change tag text from \(state.mode) mode, which should not be possible a")
      return state
    }
  }
}
