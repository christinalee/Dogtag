//
//  TagVCIntents.swift
//  yaroll
//
//  Created by Christina on 5/31/16.
//  Copyright © 2016 Math Camp. All rights reserved.
//

import Foundation
import RxSwift

public struct TagVCIntents {
  let toggleTagMode: PublishSubject<TagViewLocation?> = PublishSubject()
  let backgroundTapped: PublishSubject<()> = PublishSubject()
  let tagButtonTapped: PublishSubject<()> = PublishSubject()
  let textChanged: PublishSubject<String> = PublishSubject()
  let tagRemovedFromVC: PublishSubject<String> = PublishSubject()
//  let upperCardChanged: PublishSubject<PhotoData>  = PublishSubject()
//  let photoDataChanged: PublishSubject<PhotoData>  = PublishSubject()
  let syncWithServer: PublishSubject<()>  = PublishSubject()
}

struct TagVCIntentsHelper {
  typealias State = ConcreteTagModel.State
  
  static func reduce(_ intents: TagVCIntents) -> Observable<(State) -> State>{
    let backgroundTap = intents.backgroundTapped.map {
      TagVCIntentsHelper.backgroundTappedReducer()
    }
    
    let tagButtonTapped = intents.tagButtonTapped.map {
      TagVCIntentsHelper.tagButtonTappedReducer()
    }
    
    let toggleTagMode = intents.toggleTagMode.map { location in
      TagVCIntentsHelper.toggleTagModeReducer(location)
    }
    
    let textChanged = intents.textChanged.map{ text in
      switch(text){
      case "\n":
        return TextChange.newLine
      case "":
        return TextChange.deletedChar
      default:
        return TextChange.addedText(text: text)
      }
      }.map { text in
        TagVCIntentsHelper.textChangedReducer(text)
    }
    
    let tagRemovedFromVC = intents.tagRemovedFromVC.map { (tagId) in
      TagVCIntentsHelper.tagRemovedFromVCReducer(tagId)
    }
    
    let syncWithServer = intents.syncWithServer.map{ _ in
      TagVCIntentsHelper.syncWithServerReducer()
    }
    
    return Observable.of(
      backgroundTap,
      tagButtonTapped,
      toggleTagMode,
      textChanged,
      tagRemovedFromVC,
      syncWithServer
      ).merge()
  }
  
  static func backgroundTappedReducer() -> (State) -> State {
    print("background tapped")
    return { state in
      switch(state.mode) {
      case .deletingTag:
        let updatedTags = self.backgroundTappedFromDelete(state)
        return State(mode: .none, photoId: state.photoId, tags: updatedTags)
        
      case .none:
        return state
        
      case .tagging(let text, let location), .taggingAndMentioning(let text, _, let location):
        let tagDict = self.conditionallyUpdateTagsDict(text, location: location, currentTags: state.tags)
        return State(mode: .none, photoId: state.photoId, tags: tagDict)
      }
    }
  }
  
  fileprivate static func backgroundTappedFromDelete(_ state: State) -> Dictionary<String, TagViewData> {
    var newTags = state.tags
    state.tags.values.filter({ (tagViewData) -> Bool in
      switch(tagViewData){
      case .serverTag(_, let state, _):
        return state.shallowEquals(.deleteMode)
      case .userCreatedTag(_, let state, _):
        return state.shallowEquals(.deleteMode)
      }
    }).forEach({ (tagViewData) in
      switch(tagViewData){
      case .serverTag(let tagInfo, _, let syncRequirement):
        newTags[tagInfo.tagId] = TagViewData.serverTag(tagInfo: tagInfo, state: .none, syncRequirement: syncRequirement)
      case .userCreatedTag(let tagInfo, _, let syncRequirement):
        newTags[tagInfo.id] = TagViewData.userCreatedTag(tagInfo: tagInfo, state: .none, syncRequirement: syncRequirement)
      }
    })
    return newTags
  }
  
  //todo: figure out how to combine this with the background Reducer (maybe). only diff case is none I believe
  static func toggleTagModeReducer(_ location: TagViewLocation?) -> (State) -> State {
    return { state in
      switch(state.mode){
        
      case .deletingTag:
        var newDict = state.tags
        newDict.values.filter({ (tagViewData) -> Bool in
          return tagViewData.state.shallowEquals(.deleteMode)
        }).forEach({ (tagViewData) in
          switch (tagViewData) {
          case .serverTag(let tagInfo, _, let syncRequirement):
            newDict[tagInfo.tagId] = TagViewData.serverTag(tagInfo: tagInfo, state: .none, syncRequirement: syncRequirement)
          case .userCreatedTag(let tagInfo, _, let syncRequirement):
            newDict[tagInfo.id] = TagViewData.userCreatedTag(tagInfo: tagInfo, state: .none, syncRequirement: syncRequirement)
          }
        })
        return State(mode: .none, photoId: state.photoId, tags: newDict)
        
      case .none:
        return State(mode: .tagging(text: "", location: location), photoId: state.photoId, tags: state.tags)
        
      case .tagging(let text, let location):
        let tagDict = self.conditionallyUpdateTagsDict(text, location: location, currentTags: state.tags)
        return State(mode: .none, photoId: state.photoId, tags: tagDict)
        
      case .taggingAndMentioning(let text, _, let location):
        //todo: what to do here? go back to tagging? go back to none? -> I think none is correct
        let tagDict = self.conditionallyUpdateTagsDict(text, location: location, currentTags: state.tags)
        return State(mode: .none, photoId: state.photoId, tags: tagDict)
      }
    }
  }
  
  fileprivate static func conditionallyUpdateTagsDict(_ text: String, location: TagViewLocation?, currentTags: Dictionary<String, TagViewData>) -> Dictionary<String, TagViewData> {
    if !text.isEmpty {
      let newTag = TagCreationHelper.makeNewTag(text, location: location)
      let syncReq: SyncRequirement = .update(action: .Create)
      let newTagViewData = TagViewData.userCreatedTag(tagInfo: newTag, state: .created, syncRequirement: syncReq)
      
      var newDict = currentTags
      newDict[newTagViewData.id] = newTagViewData
      return newDict
    }
    return currentTags
  }
  
  static func tagButtonTappedReducer() -> (State) -> State {
    print("tag button tapped")
    
    //todo: figure out if this actually differs from toggleTag and if not remove; else, impl
    return toggleTagModeReducer(nil)
  }
  
  static func textChangedReducer(_ textChange: TextChange) -> (State) -> State {
    return { state in
      switch(textChange){
      case .addedText(let text):
        return TextChangedHelper.handleAddText(state, addedText: text)
      case .deletedChar:
        return TextChangedHelper.handleDeletion(state)
      case .newLine:
        return TextChangedHelper.handleNewLine(state)
      }
    }
  }
  
  static func tagRemovedFromVCReducer(_ tagId: String) -> (State) -> State {
   return { state in
      if let _ = state.tags[tagId] {
        var newDict = state.tags
        newDict.removeValue(forKey: tagId)
        return State(mode: state.mode, photoId: state.photoId, tags: newDict)
      }
      print("freak out! trying to remove a nonexistant tag \(tagId)")
      return state
    }
  }
  
//  static func upperCardChangedReducer(photoData: PhotoData) -> (State) -> State {
//    //todo: need to trigger sync
//    let photoId = photoData.photo()?.photoId
//    let idReducer: (State) -> State = TagVCIntentsHelper.photoIdChangedReducer(photoId)
//    let dataReducer: (State) -> State = TagVCIntentsHelper.photoDataChangedReducer(photoData)
//    
//    return { state in
//      return dataReducer(idReducer(state))
//    }
//  }
//  
//  static func photoIdChangedReducer(photoId: String?) -> (State) -> State {
//    return { state in
//      return State(mode: state.mode, photoId: photoId, tags: state.tags)
//    }
//  }
//  
//  static func photoDataChangedReducer(photoData: PhotoData) -> (State) -> State {
//    return { state in
//      if let tagData = photoData.photo()?.tags {
//        if let photo = photoData.photo() {
//          if state.photoId != photo.photoId { return state }
//          
//          // remove existing tags
//          var newTags = state.tags
//          newTags.map({ (tag: TagViewData) -> TagViewData in
//            switch(tag){
//            case .ServerTag(let tagInfo, _, let syncRequirement):
//              let updatedSyncReq = syncRequirement.requireUpdate(.Delete)
//              return .ServerTag(tagInfo: tagInfo, state: .Deleted, syncRequirement: updatedSyncReq)
//            case .UserCreatedTag(let tagInfo, _, let syncRequirement):
//              let updatedSyncReq = syncRequirement.requireUpdate(.Delete)
//              return .UserCreatedTag(tagInfo: tagInfo, state: .Deleted, syncRequirement: updatedSyncReq)
//            }
//          })
//          
//          // add in updated tags
//          tagData.forEach { (tag: PhotoTypes.Tag) in
//            if let _ = state.tags[tag.tagId] {
//              newTags[tag.tagId] = .ServerTag(tagInfo: tag, state: .Updated, syncRequirement: .None) //already showing this tag
//            } else {
//              newTags[tag.tagId] = .ServerTag(tagInfo: tag, state: .Created, syncRequirement: .None)
//            }
//          }
//          return State(mode: state.mode, photoId: state.photoId, tags: newTags)
//        }
//      }
//      return state
//    }
//  }
  
  static func syncWithServerReducer() -> (State) -> State {
    return { state in
      return state
    }
  }
}

