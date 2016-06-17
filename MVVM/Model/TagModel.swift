//
//  TagModel.swift
//  yaroll
//
//  Created by Christina on 5/31/16.
//  Copyright © 2016 Math Camp. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import UIKit

//todo: relocate these enums
public enum TagViewLocation {
  case CustomLocation(point: CGPoint)
  case Default
  
 func shallowEquals(otherLocation: TagViewLocation) -> Bool {
    switch(self, otherLocation){
    case (.CustomLocation(_), .CustomLocation(_)),
         (.Default, .Default):
      return true
    case (.CustomLocation(_), _),
         (.Default, _):
      return false
    }
  }
  
  func deepEquals(otherLocation: TagViewLocation) -> Bool {
    switch(self, otherLocation){
    case (.CustomLocation(let point1), .CustomLocation(let point2)):
      return point1 == point2
    case (.Default, .Default):
      return true
    case (.CustomLocation(_), _),
         (.Default, _):
      return false
    }
  }
}

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

public struct UserTagInfo {
  let id: String
  let text: NSAttributedString
  let location: TagViewLocation?
  let imgUrl: String
  let centerOnTooth: Bool
  
  func updateLocation(location: CGPoint) -> UserTagInfo {
    let newLocation: TagViewLocation = .CustomLocation(point: location)
    return UserTagInfo(id: self.id, text: self.text, location: newLocation, imgUrl: self.imgUrl, centerOnTooth: self.centerOnTooth)
  }
}

public enum TagActionType: String {
  case Create = "create"
  case Delete = "delete"
  case Move = "update"
}

public enum SyncRequirement {
  case None
  case Update(action: TagActionType)
  case Like(likeCount: Int)
  case UpdateAndLike(action: TagActionType, likeCount: Int)
  
  func requireUpdate(tagAction: TagActionType) -> SyncRequirement {
    switch self {
    case .None:
      return .Update(action: tagAction)
    case .Update(let action):
      if (action == .Create && tagAction == .Move){
        return self //do not change to .Update if moved, it's still .Create
      }
      return .Update(action: tagAction)
    case .Like(let likeCount):
      return .UpdateAndLike(action: tagAction, likeCount: likeCount)
    case .UpdateAndLike(let action, let likeCount):
      if (action == .Create && tagAction == .Move){
        return self //do not change to .Update if moved, it's still .Create
      }
      return .UpdateAndLike(action: tagAction, likeCount: likeCount)
    }
  }
  
  func addLike() -> SyncRequirement {
    switch self {
    case .None:
      return .Like(likeCount: 1)
    case .Update(let action):
      return .UpdateAndLike(action: action, likeCount: 1)
    case .Like(let likeCount):
      return .Like(likeCount: likeCount + 1)
    case .UpdateAndLike(let action, let likeCount):
      return .UpdateAndLike(action: action, likeCount: likeCount + 1)
    }
  }
}

public enum TagViewData {
  case ServerTag(tagInfo: PhotoTypes.Tag, state: TagState, syncRequirement: SyncRequirement)
  case UserCreatedTag(tagInfo: UserTagInfo, state: TagState, syncRequirement: SyncRequirement)
  
  var id: String {
    switch (self) {
    case .ServerTag(let tagInfo, _, _):
      return tagInfo.tagId
    case .UserCreatedTag(let tagInfo, _, _):
      return tagInfo.id
    }
  }
  
  var state: TagState {
    switch (self) {
    case .ServerTag(_, let state, _):
      return state
    case .UserCreatedTag(_, let state, _):
      return state
    }
  }
  
  var syncRequirement: SyncRequirement {
    switch (self) {
    case .ServerTag(_, _, let syncRequirement):
      return syncRequirement
    case .UserCreatedTag(_, _, let syncRequirement):
      return syncRequirement
    }
  }
  
  func move(tagLocation: CGPoint) -> TagViewData {
    switch (self) {
    case .ServerTag(let tagInfo, _, let syncRequirement):
      tagInfo.location = tagLocation
      let newSyncReq = syncRequirement.requireUpdate(.Move)
      return .ServerTag(tagInfo: tagInfo, state: .Panning(locationInView: tagLocation), syncRequirement: newSyncReq)
    case .UserCreatedTag(let tagInfo, _, let syncRequirement):
      let newTagInfo = tagInfo.updateLocation(tagLocation)
      let newSyncReq = syncRequirement.requireUpdate(.Move)
      return .UserCreatedTag(tagInfo: newTagInfo, state: .Panning(locationInView: tagLocation), syncRequirement: newSyncReq)
    }
  }
}



protocol TagModel {
  var model: Driver<ConcreteTagModel.State> { get }
  var tagIntents: TagIntents { get } //todo: make into protocol
  var tagVCIntents: TagVCIntents { get } //todo: make into protocol
}

class ConcreteTagModel: TagModel {
  struct State {
    let mode: TagVCMode
    let photoId: String?
    let tags: Dictionary<String, TagViewData>
  }
  
  var model: Driver<State>
  var tagIntents: TagIntents
  var tagVCIntents: TagVCIntents
  
  init(tagIntents: TagIntents, tagVCIntents: TagVCIntents) {
    self.tagIntents = tagIntents
    self.tagVCIntents = tagVCIntents
    
    let intialState = State(mode: .None, photoId: nil, tags: Dictionary())
    let tagReducers: Observable<(State) -> State> = TagIntentsHelper.reduce(tagIntents)
    let vcReducers: Observable<(State) -> State> = TagVCIntentsHelper.reduce(tagVCIntents)
    // todo: add a new reducer
    
    model = Observable.of(
      tagReducers,
      vcReducers
    ).merge().scan(intialState, accumulator: { (currentState, reducer) -> State in
      let newState = reducer(currentState)
      return newState
    }).asDriver(onErrorDriveWith: Driver.never())
  }
}