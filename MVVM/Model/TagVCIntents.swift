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
  
  static func reduce(intents: TagVCIntents) -> Observable<(State) -> State>{
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
        return TextChange.NewLine
      case "":
        return TextChange.DeletedChar
      default:
        return TextChange.AddedText(text: text)
      }
      }.map { text in
        TagVCIntentsHelper.textChangedReducer(text)
    }
    
    let tagRemovedFromVC = intents.tagRemovedFromVC.map { (tagId) in
      TagVCIntentsHelper.tagRemovedFromVCReducer(tagId)
    }
    
//    let upperCardChanged: Observable<(State) -> State> = intents.upperCardChanged.map{ (photoData: PhotoData) in
//      TagVCIntentsHelper.upperCardChangedReducer(photoData)
//    }
//    
//    let photoDataChanged = intents.photoDataChanged.map{ (photoData) in
//      TagVCIntentsHelper.photoDataChangedReducer(photoData)
//    }
    
    let syncWithServer = intents.syncWithServer.map{ _ in
      TagVCIntentsHelper.syncWithServerReducer()
    }
    
    return Observable.of(
      backgroundTap,
      tagButtonTapped,
      toggleTagMode,
      textChanged,
      tagRemovedFromVC,
//      upperCardChanged,
//      photoDataChanged,
      syncWithServer
      ).merge()
  }
  
  static func backgroundTappedReducer() -> (State) -> State {
    print("background tapped")
    return { state in
      switch(state.mode) {
      case .DeletingTag:
        //todo: find a good naming pardigm here
        let updatedTags = self.backgroundTappedFromDelete(state)
        return State(mode: .None, photoId: state.photoId, tags: updatedTags)
        
      case .None:
        return state
        
      case .Tagging(let text, let location):
        let tagDict = self.conditionallyUpdateTagsDict(text, location: location, currentTags: state.tags)
        return State(mode: .None, photoId: state.photoId, tags: tagDict)
        
      case .TaggingAndMentioning(let text, _, let location):
        let tagDict = self.conditionallyUpdateTagsDict(text, location: location, currentTags: state.tags)
        return State(mode: .None, photoId: state.photoId, tags: tagDict)
      }
    }
  }
  
  private static func backgroundTappedFromDelete(state: State) -> Dictionary<String, TagViewData> {
    var newTags = state.tags
    state.tags.values.filter({ (tagViewData) -> Bool in
      switch(tagViewData){
      case .ServerTag(_, let state, _):
        return state.shallowEquals(.DeleteMode)
      case .UserCreatedTag(_, let state, _):
        return state.shallowEquals(.DeleteMode)
      }
    }).forEach({ (tagViewData) in
      switch(tagViewData){
      case .ServerTag(let tagInfo, _, let syncRequirement):
        newTags[tagInfo.tagId] = TagViewData.ServerTag(tagInfo: tagInfo, state: .None, syncRequirement: syncRequirement)
      case .UserCreatedTag(let tagInfo, _, let syncRequirement):
        newTags[tagInfo.id] = TagViewData.UserCreatedTag(tagInfo: tagInfo, state: .None, syncRequirement: syncRequirement)
      }
    })
    return newTags
  }
  
  //todo: figure out how to combine this with the background Reducer (maybe). only diff case is none I believe
  static func toggleTagModeReducer(location: TagViewLocation?) -> (State) -> State {
    return { state in
      switch(state.mode){
        
      case .DeletingTag:
        var newDict = state.tags
        newDict.values.filter({ (tagViewData) -> Bool in
          return tagViewData.state.shallowEquals(.DeleteMode)
        }).forEach({ (tagViewData) in
          switch (tagViewData) {
          case .ServerTag(let tagInfo, _, let syncRequirement):
            newDict[tagInfo.tagId] = TagViewData.ServerTag(tagInfo: tagInfo, state: .None, syncRequirement: syncRequirement)
          case .UserCreatedTag(let tagInfo, _, let syncRequirement):
            newDict[tagInfo.id] = TagViewData.UserCreatedTag(tagInfo: tagInfo, state: .None, syncRequirement: syncRequirement)
          }
        })
        return State(mode: .None, photoId: state.photoId, tags: newDict)
        
      case .None:
        return State(mode: .Tagging(text: "", location: location), photoId: state.photoId, tags: state.tags)
        
      case .Tagging(let text, let location):
        let tagDict = self.conditionallyUpdateTagsDict(text, location: location, currentTags: state.tags)
        return State(mode: .None, photoId: state.photoId, tags: tagDict)
        
      case .TaggingAndMentioning(let text, _, let location):
        //todo: what to do here? go back to tagging? go back to none? -> I think none is correct
        let tagDict = self.conditionallyUpdateTagsDict(text, location: location, currentTags: state.tags)
        return State(mode: .None, photoId: state.photoId, tags: tagDict)
      }
    }
  }
  
  private static func conditionallyUpdateTagsDict(text: String, location: TagViewLocation?, currentTags: Dictionary<String, TagViewData>) -> Dictionary<String, TagViewData> {
    if !text.isEmpty {
      let newTag = TagCreationHelper.makeNewTag(text, location: location)
      let syncReq: SyncRequirement = .Update(action: .Create)
      let newTagViewData = TagViewData.UserCreatedTag(tagInfo: newTag, state: .Created, syncRequirement: syncReq)
      
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
  
  static func textChangedReducer(textChange: TextChange) -> (State) -> State {
    return { state in
      switch(textChange){
      case .AddedText(let text):
        return TextChangedHelper.handleAddText(state, addedText: text)
      case .DeletedChar:
        return TextChangedHelper.handleDeletion(state)
      case .NewLine:
        return TextChangedHelper.handleNewLine(state)
      }
    }
  }
  
  static func tagRemovedFromVCReducer(tagId: String) -> (State) -> State {
   return { state in
      if let _ = state.tags[tagId] {
        var newDict = state.tags
        newDict.removeValueForKey(tagId)
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

