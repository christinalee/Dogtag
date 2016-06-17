//
//  TagViewPanHelper.swift
//  yaroll
//
//  Created by Christina on 2/10/16.
//  Copyright © 2016 Math Camp. All rights reserved.
//

import Foundation
import UIKit

struct TagBoundaries {
  let maxX: CGFloat
  let maxY: CGFloat
  let minX: CGFloat
  let minY: CGFloat
  
  init(minX: CGFloat, minY: CGFloat, maxX: CGFloat, maxY: CGFloat) {
    self.minX = minX
    self.minY = minY
    self.maxX = maxX
    self.maxY = maxY
  }
}

class TagViewPanHelper {
  private let VERTICAL_MARGIN = CGFloat(64)
  
  func adjustedNewLocation(panLocationInView: CGPoint, newPanLocation: CGPoint, viewFrame: CGRect, superviewFrame: CGRect) -> CGPoint {
    let desiredLocation = CGPoint(x: newPanLocation.x - panLocationInView.x, y: newPanLocation.y - panLocationInView.y)
    let tagBoundaries = getBoundaries(viewFrame, superviewFrame: superviewFrame)
    return clipToBoundariesIfNecessary(desiredLocation, tagBoundaries: tagBoundaries)
  }
  
  func clipToBoundariesIfNecessary(desiredLocation: CGPoint, tagBoundaries: TagBoundaries) -> CGPoint {
    var adjustedLocation = desiredLocation
    
    if desiredLocation.x < tagBoundaries.minX {
      adjustedLocation = CGPoint(x: tagBoundaries.minX, y: adjustedLocation.y)
    } else if desiredLocation.x > tagBoundaries.maxX {
      adjustedLocation = CGPoint(x: tagBoundaries.maxX, y: adjustedLocation.y)
    }
   
    if desiredLocation.y < tagBoundaries.minY {
      adjustedLocation = CGPoint(x: adjustedLocation.x, y: tagBoundaries.minY)
    } else if desiredLocation.y > tagBoundaries.maxY {
      adjustedLocation = CGPoint(x: adjustedLocation.x, y: tagBoundaries.maxY)
    }
    
    return adjustedLocation
  }
  
  func getBoundaries(viewFrame: CGRect, superviewFrame: CGRect) -> TagBoundaries {
    let maxX = superviewFrame.width - viewFrame.width
    let maxY = (superviewFrame.height - VERTICAL_MARGIN) - viewFrame.height
    let minX = CGFloat(0)
    let minY = VERTICAL_MARGIN
    
    return TagBoundaries(minX: minX, minY: minY, maxX: maxX, maxY: maxY)
  }
  
}