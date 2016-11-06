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
  case serverTag(tagInfo: PhotoTypes.Tag, state: TagState, syncRequirement: SyncRequirement)
  case userCreatedTag(tagInfo: UserTagInfo, state: TagState, syncRequirement: SyncRequirement)
  
  var id: String {
    switch (self) {
    case .serverTag(let tagInfo, _, _):
      return tagInfo.tagId
    case .userCreatedTag(let tagInfo, _, _):
      return tagInfo.id
    }
  }
  
  var state: TagState {
    switch (self) {
    case .serverTag(_, let state, _):
      return state
    case .userCreatedTag(_, let state, _):
      return state
    }
  }
  
  var syncRequirement: SyncRequirement {
    switch (self) {
    case .serverTag(_, _, let syncRequirement):
      return syncRequirement
    case .userCreatedTag(_, _, let syncRequirement):
      return syncRequirement
    }
  }
  
  func move(_ tagLocation: CGPoint) -> TagViewData {
    switch (self) {
    case .serverTag(let tagInfo, _, let syncRequirement):
      tagInfo.location = tagLocation
      let newSyncReq = syncRequirement.requireUpdate(.Move)
      return .serverTag(tagInfo: tagInfo, state: .panning(locationInView: tagLocation), syncRequirement: newSyncReq)
    case .userCreatedTag(let tagInfo, _, let syncRequirement):
      let newTagInfo = tagInfo.updateLocation(tagLocation)
      let newSyncReq = syncRequirement.requireUpdate(.Move)
      return .userCreatedTag(tagInfo: newTagInfo, state: .panning(locationInView: tagLocation), syncRequirement: newSyncReq)
    }
  }
}
