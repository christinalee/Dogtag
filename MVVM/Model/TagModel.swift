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

protocol TagModel {
  var model: Driver<ConcreteTagModel.State> { get }
  var tagIntents: TagIntents { get }
  var tagVCIntents: TagVCIntents { get }
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
    
    //create fake server tag for initial state -- included for Demo purposes only
    var initialDict = Dictionary<String, TagViewData>()
    let serverTag1 = TagCreationHelper.makeNewServerTag("Welcome!", location: CGPoint(x: 5, y: 0.5), userId: TagOwner.OtherPerson)
    let tag1 = TagViewData.serverTag(tagInfo: serverTag1, state: .created, syncRequirement: .none)
    initialDict[tag1.id] = tag1
    
    let intialState = State(mode: .none, photoId: nil, tags: initialDict)
    let tagReducers: Observable<(State) -> State> = TagIntentsHelper.reduce(tagIntents)
    let vcReducers: Observable<(State) -> State> = TagVCIntentsHelper.reduce(tagVCIntents)
    
    model = Observable.of(
      tagReducers,
      vcReducers
    ).merge().scan(intialState, accumulator: { (currentState, reducer) -> State in
      let newState = reducer(currentState)
      return newState
    }).startWith(intialState)
      .asDriver(onErrorDriveWith: Driver.never())
  }
}
