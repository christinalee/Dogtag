//
//  SyncRequirement.swift
//  MVVM
//
//  Created by Christina on 6/22/16.
//  Copyright © 2016 Christina. All rights reserved.
//

import Foundation

public enum SyncRequirement {
  case none
  case update(action: TagActionType)
  case like(likeCount: Int)
  case updateAndLike(action: TagActionType, likeCount: Int)
  
  func requireUpdate(_ tagAction: TagActionType) -> SyncRequirement {
    switch self {
    case .none:
      return .update(action: tagAction)
    case .update(let action):
      if (action == .Create && tagAction == .Move){
        return self //do not change to .Update if moved, it's still .Create
      }
      return .update(action: tagAction)
    case .like(let likeCount):
      return .updateAndLike(action: tagAction, likeCount: likeCount)
    case .updateAndLike(let action, let likeCount):
      if (action == .Create && tagAction == .Move){
        return self //do not change to .Update if moved, it's still .Create
      }
      return .updateAndLike(action: tagAction, likeCount: likeCount)
    }
  }
  
  func addLike() -> SyncRequirement {
    switch self {
    case .none:
      return .like(likeCount: 1)
    case .update(let action):
      return .updateAndLike(action: action, likeCount: 1)
    case .like(let likeCount):
      return .like(likeCount: likeCount + 1)
    case .updateAndLike(let action, let likeCount):
      return .updateAndLike(action: action, likeCount: likeCount + 1)
    }
  }
}
