//
//  TagIntents.swift
//  yaroll
//
//  Created by Christina on 5/31/16.
//  Copyright © 2016 Math Camp. All rights reserved.
//

import Foundation
import RxSwift
import UIKit

public struct TagIntents {
  let tagFinishedCreating: PublishSubject<String> = PublishSubject()
  let tagMoved: PublishSubject<(String, CGPoint?)> = PublishSubject()
  let tagDeleteButtonTapped: PublishSubject<String> = PublishSubject()
  let tagEnteredDeleteMode: PublishSubject<String> = PublishSubject()
  let tagExitedDeleteMode: PublishSubject<String> = PublishSubject()
  let tagIconTapped: PublishSubject<(String, String)> = PublishSubject()
  let tagTapped: PublishSubject<(String, TagState)> = PublishSubject()
}

struct TagIntentsHelper {
  typealias State = ConcreteTagModel.State
  
  static func reduce(_ intents: TagIntents) -> Observable<(State) -> State>{
    let tagMoved = intents.tagMoved.map { (tagId, location) in
      TagIntentsHelper.tagMovedReducer(tagId, tagLocation: location)
    }
    
    let tagDeleteButtonTapped = intents.tagDeleteButtonTapped.map { (tagId) in
      TagIntentsHelper.tagDeleteButtonTappedReducer(tagId)
    }
    
    let tagEnteredDeleteMode = intents.tagEnteredDeleteMode.map { (tagId) in
      TagIntentsHelper.tagEnteredDeleteModeReducer(tagId)
    }
    
    let tagExitedDeleteMode = intents.tagExitedDeleteMode.map { (tagId) in
      TagIntentsHelper.tagExitedDeleteModeReducer(tagId)
    }
    
    let tagIconTapped = intents.tagIconTapped.map { (tagId, userid) in
      TagIntentsHelper.tagIconTappedReducer(tagId, userid: userid)
    }
    
    let tagTapped = intents.tagTapped.map { (tagIdAndState) in
      TagIntentsHelper.tagTappedReducer(tagIdAndState)
    }
    
    let tagFinishedCreating = intents.tagFinishedCreating.map { (tagId) in
      TagIntentsHelper.tagFinishedCreatingReducer(tagId)
    }
    
    return Observable.of(
      tagMoved,
      tagDeleteButtonTapped,
      tagEnteredDeleteMode,
      tagExitedDeleteMode,
      tagIconTapped,
      tagTapped,
      tagFinishedCreating
    ).merge()
  }
  
  static func tagFinishedCreatingReducer(_ tagId: String) -> (State) -> State {
    return { state in
      if let tagViewData = state.tags[tagId] {
        var newTags = state.tags
        
        switch(tagViewData){
        case .serverTag(let tagInfo, _, let syncRequirement):
          newTags[tagInfo.tagId] = TagViewData.serverTag(tagInfo: tagInfo, state: .none, syncRequirement: syncRequirement)
        case .userCreatedTag(let tagInfo, _, let syncRequirement):
          newTags[tagInfo.id] = TagViewData.userCreatedTag(tagInfo: tagInfo, state: .none, syncRequirement: syncRequirement)
        }
        
        return State(mode: state.mode, photoId: state.photoId, tags: newTags)
      }
      
      return state
    }
  }
  
  static func tagMovedReducer(_ tagId: String, tagLocation: CGPoint?) -> (State) -> State {
    return { state in
      
      if let tag = state.tags[tagId] {
        var newDict = state.tags
        
        if let location = tagLocation {
          let updatedTag: TagViewData = tag.move(location)
          newDict[tagId] = updatedTag
          
          switch(tag){
          case .serverTag(let tagInfo, _, let syncRequirement):
            newDict[tag.id] = .serverTag(tagInfo: tagInfo, state: .panning(locationInView: location), syncRequirement: syncRequirement.requireUpdate(.Move))
          case .userCreatedTag(let tagInfo, _, let syncRequirement):
            newDict[tag.id] = .userCreatedTag(tagInfo: tagInfo, state: .panning(locationInView: location), syncRequirement: syncRequirement.requireUpdate(.Move))
          }  
        } else { //pan ended
          switch(tag){
          case .serverTag(let tagInfo, _, let syncRequirement):
            newDict[tag.id] = .serverTag(tagInfo: tagInfo, state: .none, syncRequirement: syncRequirement)
          case .userCreatedTag(let tagInfo, _, let syncRequirement):
            newDict[tag.id] = .userCreatedTag(tagInfo: tagInfo, state: .none, syncRequirement: syncRequirement)
          }
        }
        
        return State(mode: state.mode, photoId: state.photoId, tags: newDict)
      }
      
      fatalError("Trying to pan nonexistant tag \(tagId)")
    }
  }
  
  static func tagDeleteButtonTappedReducer(_ tagId: String) -> (State) -> State {
    return { state in
      if let tag = state.tags[tagId] {
        var newDict = state.tags
        
        switch(tag){
        case .serverTag(let tagInfo, _, let syncRequirement):
          let updatedSyncReq = syncRequirement.requireUpdate(.Delete)
          newDict[tagId] = .serverTag(tagInfo: tagInfo, state: .deleted, syncRequirement: updatedSyncReq)
        case .userCreatedTag(let tagInfo, _, let syncRequirement):
          let updatedSyncReq = syncRequirement.requireUpdate(.Delete)
          newDict[tagId] = .userCreatedTag(tagInfo: tagInfo, state: .deleted, syncRequirement: updatedSyncReq)
        }
        return State(mode: state.mode, photoId: state.photoId, tags: newDict)
      }
      
      fatalError("freak out! tapping delete button on a nonexistant \(tagId)")
    }
  }
  
  static func tagEnteredDeleteModeReducer(_ tagId: String) -> (State) -> State  {
    return { state in
      
      if let tagData = state.tags[tagId] {
        switch(state.mode){
        case .none, .deletingTag:
          var newDict = state.tags
          switch(tagData){
          case .serverTag(let tag, _, let syncRequirement):
            newDict[tagData.id] = TagViewData.serverTag(tagInfo: tag, state: .deleteMode, syncRequirement: syncRequirement)
          case .userCreatedTag(let tagInfo, _, let syncRequirement):
            newDict[tagData.id] = TagViewData.userCreatedTag(tagInfo: tagInfo, state: .deleteMode, syncRequirement: syncRequirement)
          }
          return State(mode: .deletingTag, photoId: state.photoId, tags: newDict)
        case .tagging(_, _), .taggingAndMentioning(_, _, _):
          //This shouldn't happen
          fatalError("Tag model going from \(state.mode) to .DeletingTag")
        }
      }
      
      fatalError("Freak out, trying to send non existant tag into delete mode \(tagId)")
    }
  }
  
  static func tagExitedDeleteModeReducer(_ tagId: String) -> (State) -> State {
   return { state in
      switch(state.mode){
      case .deletingTag:
        let tagsInDeleteMode: Int = state.tags.filter({ (_, tagData) -> Bool in
          tagData.state.shallowEquals(TagState.deleteMode)
        }).count
        let newMode: TagVCMode = tagsInDeleteMode == 0 ? .none : .deletingTag
        return State(mode: newMode, photoId: state.photoId, tags: state.tags)
      case .none, .tagging(_, _), .taggingAndMentioning(_, _, _):
        //This shouldn't happen
        fatalError("Freak out, tag model going from \(state.mode) to .None")
      }
    }
  }
  
  static func tagIconTappedReducer(_ tagId: String, userid: String) -> (State) -> State  {
   print("tag \(tagId) icon tapped")
    return { state in
      if userid == TagOwner.Own {
        //no op
        return state
      }
      
      //segue if not own profile photo
      return state
    }
  }
  
  static func tagTappedReducer(_ tagIdAndState: (String, TagState)) -> (State) -> State  {
    return { state in 
      if let tag = state.tags[tagIdAndState.0] {
        var newDict = state.tags
        
        switch(tag){
        case .serverTag(let tagInfo, _, let syncRequirement):
          var updatedSyncReq = syncRequirement
          if case .liked(_) = tagIdAndState.1 {
            updatedSyncReq = syncRequirement.addLike()
          }
          newDict[tag.id] = .serverTag(tagInfo: tagInfo, state: tagIdAndState.1, syncRequirement: updatedSyncReq)
          
        case .userCreatedTag(let tagInfo, _, let syncRequirement):
          var updatedSyncReq = syncRequirement
          if case .liked(_) = tagIdAndState.1 {
            updatedSyncReq = syncRequirement.addLike()
          }
          newDict[tag.id] = .userCreatedTag(tagInfo: tagInfo, state: tagIdAndState.1, syncRequirement: updatedSyncReq)
        }
        
        return State(mode: state.mode, photoId: state.photoId, tags: newDict)
      }
      
      fatalError("Trying to tap a tag that doesn't exist in tags dict \(tagIdAndState)")
    }
  }
}
