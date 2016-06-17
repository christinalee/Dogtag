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
  
  static func reduce(intents: TagIntents) -> Observable<(State) -> State>{
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
  
  static func tagFinishedCreatingReducer(tagId: String) -> (State) -> State {
    return { state in
      if let tagViewData = state.tags[tagId] {
        var newTags = state.tags
        switch(tagViewData){
        case .ServerTag(let tagInfo, _, let syncRequirement):
          newTags[tagInfo.tagId] = TagViewData.ServerTag(tagInfo: tagInfo, state: .None, syncRequirement: syncRequirement)
        case .UserCreatedTag(let tagInfo, _, let syncRequirement):
          newTags[tagInfo.id] = TagViewData.UserCreatedTag(tagInfo: tagInfo, state: .None, syncRequirement: syncRequirement)
        }
        return State(mode: state.mode, photoId: state.photoId, tags: newTags)
      }
      return state
    }
  }
  
  static func tagMovedReducer(tagId: String, tagLocation: CGPoint?) -> (State) -> State {
   print("tag \(tagId) moved")
    return { state in
      if let tag = state.tags[tagId] {
        var newDict = state.tags
        if let location = tagLocation {
          //todo: update tagInfo with new location
          let updatedTag: TagViewData = tag.move(location)
          newDict[tagId] = updatedTag
//          switch(tag){
//          case .ServerTag(let tagInfo, _, let syncRequirement):
//            newDict[tag.id] = .ServerTag(tagInfo: tagInfo, state: .Panning(locationInView: location), syncRequirement: syncRequirement.requireUpdate(.Move))
//          case .UserCreatedTag(let tagInfo, _, let syncRequirement):
//            newDict[tag.id] = .UserCreatedTag(tagInfo: tagInfo, state: .Panning(locationInView: location), syncRequirement.requireUpdate(.Move))
//          }  
        } else { //pan ended
          //todo: fire tag changed event to server/otherwise notify "real" model
          switch(tag){
          case .ServerTag(let tagInfo, _, let syncRequirement):
            newDict[tag.id] = .ServerTag(tagInfo: tagInfo, state: .None, syncRequirement: syncRequirement)
          case .UserCreatedTag(let tagInfo, _, let syncRequirement):
            newDict[tag.id] = .UserCreatedTag(tagInfo: tagInfo, state: .None, syncRequirement: syncRequirement)
          }
        }
        return State(mode: state.mode, photoId: state.photoId, tags: newDict)
      }
      fatalError("Trying to pan nonexistant tag \(tagId)")
    }
  }
  
  static func tagDeleteButtonTappedReducer(tagId: String) -> (State) -> State {
    return { state in
      if let tag = state.tags[tagId] {
        var newDict = state.tags
        
        switch(tag){
        case .ServerTag(let tagInfo, _, let syncRequirement):
          let updatedSyncReq = syncRequirement.requireUpdate(.Delete)
          newDict[tagId] = .ServerTag(tagInfo: tagInfo, state: .Deleted, syncRequirement: updatedSyncReq)
        case .UserCreatedTag(let tagInfo, _, let syncRequirement):
          let updatedSyncReq = syncRequirement.requireUpdate(.Delete)
          newDict[tagId] = .UserCreatedTag(tagInfo: tagInfo, state: .Deleted, syncRequirement: updatedSyncReq)
        }
        return State(mode: state.mode, photoId: state.photoId, tags: newDict)
      }
      
      print("freak out! tapping delete button on a nonexistant \(tagId)")
      return state
    }
  }
  
  static func tagEnteredDeleteModeReducer(tagId: String) -> (State) -> State  {
    return { state in
      if let tagData = state.tags[tagId] {
        switch(state.mode){
        case .None, .DeletingTag:
          var newDict = state.tags
          switch(tagData){
          case .ServerTag(let tag, _, let syncRequirement):
            newDict[tagData.id] = TagViewData.ServerTag(tagInfo: tag, state: .DeleteMode, syncRequirement: syncRequirement)
          case .UserCreatedTag(let tagInfo, _, let syncRequirement):
            newDict[tagData.id] = TagViewData.UserCreatedTag(tagInfo: tagInfo, state: .DeleteMode, syncRequirement: syncRequirement)
          }
          return State(mode: .DeletingTag, photoId: state.photoId, tags: newDict)
        case .Tagging(_, _), .TaggingAndMentioning(_, _, _):
          //This shouldn't happen
          print("!!!! something weird is happening here: tag model going from \(state.mode) to .DeletingTag")
          fatalError("tag model going from \(state.mode) to .DeletingTag")
        }
      }
      fatalError("Freak out, trying to send non existant tag into delete mode \(tagId)")
    }
  }
  
  static func tagExitedDeleteModeReducer(tagId: String) -> (State) -> State {
   return { state in
      switch(state.mode){
      case .DeletingTag:
        return State(mode: .None, photoId: state.photoId, tags: state.tags)
      case .None, .Tagging(_, _), .TaggingAndMentioning(_, _, _):
        //This shouldn't happen
        fatalError("!!!! something weird is happening here: tag model going from \(state.mode) to .DeletingTag")
      }
    }
  }
  
  static func tagIconTappedReducer(tagId: String, userid: String) -> (State) -> State  {
   print("tag \(tagId) icon tapped")
    return { state in
      //todo
//      if userid == AppModules.sharedInstance.userModel.userRecord.id {
//        //no op
//        return state
//      }
      
      //todo: need to segue if not own profile photo
      return state
    }
  }
  
  static func tagTappedReducer(tagIdAndState: (String, TagState)) -> (State) -> State  {
    return { state in 
      if let tag = state.tags[tagIdAndState.0] {
        var newDict = state.tags
        
        switch(tag){
        case .ServerTag(let tagInfo, _, let syncRequirement):
          var updatedSyncReq = syncRequirement
          if case .Liked(_) = tagIdAndState.1 {
            updatedSyncReq = syncRequirement.addLike()
          }
          newDict[tag.id] = .ServerTag(tagInfo: tagInfo, state: tagIdAndState.1, syncRequirement: updatedSyncReq)
          
        case .UserCreatedTag(let tagInfo, _, let syncRequirement):
          var updatedSyncReq = syncRequirement
          if case .Liked(_) = tagIdAndState.1 {
            updatedSyncReq = syncRequirement.addLike()
          }
          newDict[tag.id] = .UserCreatedTag(tagInfo: tagInfo, state: tagIdAndState.1, syncRequirement: updatedSyncReq)
        }
        
        return State(mode: state.mode, photoId: state.photoId, tags: newDict)
      }
      
      fatalError("trying to tap a tag that doesn't exist in tags dict \(tagIdAndState)")
    }
  }
}