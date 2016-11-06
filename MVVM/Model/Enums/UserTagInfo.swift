//
//  UserTagInfo.swift
//  MVVM
//
//  Created by Christina on 6/22/16.
//  Copyright © 2016 Christina. All rights reserved.
//

import Foundation
import UIKit

public struct UserTagInfo {
  let id: String
  let text: NSAttributedString
  let location: TagViewLocation?
  let imgUrl: String
  let centerOnTooth: Bool
  
  func updateLocation(_ location: CGPoint) -> UserTagInfo {
    let newLocation: TagViewLocation = .customLocation(point: location)
    return UserTagInfo(id: self.id, text: self.text, location: newLocation, imgUrl: self.imgUrl, centerOnTooth: self.centerOnTooth)
  }
}

