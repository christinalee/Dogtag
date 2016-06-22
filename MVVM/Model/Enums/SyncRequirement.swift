//
//  SyncRequirement.swift
//  MVVM
//
//  Created by Christina on 6/22/16.
//  Copyright © 2016 Christina. All rights reserved.
//

import Foundation

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