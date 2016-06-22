//
//  TagViewData.swift
//  MVVM
//
//  Created by Christina on 6/22/16.
//  Copyright © 2016 Christina. All rights reserved.
//

import Foundation
import UIKit

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