//
//  TagView.swift
//  yaroll
//
//  Created by Ben Garrett on 2/9/16.
//  Copyright © 2016 Math Camp. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import UIKit
import NSObject_Rx

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}


struct HeartAnimationPath {
  let ctrlPt1: CGPoint
  let ctrlPt2: CGPoint
  let endPoint: CGPoint
  
  init(pt1: CGPoint, pt2: CGPoint, end: CGPoint) {
    ctrlPt1 = pt1
    ctrlPt2 = pt2
    endPoint = end
  }
}

open class TagView: UIView, CAAnimationDelegate {
  open var viewId: String!
  fileprivate var createdBy: String!
  open let tagState$: PublishSubject<TagState> = PublishSubject()
  
  fileprivate var canEdit: Bool = false
  fileprivate var parentSize: CGSize?
  open var tagLocation: CGPoint {
    get {
      if let size = parentSize {
        let x: CGFloat = CGFloat(self.frame.origin.x / size.width)
        let y: CGFloat = CGFloat(self.frame.origin.y / size.height)
        
        return CGPoint(x: x, y: y)
      }
      return CGPoint.zero
    }
  }
  
  fileprivate let MAX_TAG_WIDTH: CGFloat = CGFloat(224)
  fileprivate let ICON_SIZE = CGFloat(28)
  fileprivate let TAG_CONTAINER_MARGIN = CGFloat(10)
  fileprivate let LABEL_MARGIN = CGFloat(4)
  fileprivate let HEART_VIEW_TAG = 77
  fileprivate let CONTROLS_HEIGHT = CGFloat(64)
  
  fileprivate let heartAnimations = [
    HeartAnimationPath(pt1: CGPoint(x: 0.8, y: -30.7), pt2: CGPoint(x: 17, y: -56.4), end: CGPoint(x: 33.6, y: -75.5)),
    HeartAnimationPath(pt1: CGPoint(x: 0.8, y: -30.7), pt2: CGPoint(x: 17, y: -56.4), end: CGPoint(x: 51, y: -50.7)),
    HeartAnimationPath(pt1: CGPoint(x: -0.6, y: -26.3), pt2: CGPoint(x: -10.6, y: -45.7), end: CGPoint(x: -33.8, y: -61.1)),
    ]
  fileprivate var animationIdx = 0
  
  @IBOutlet weak var labelContainerView: UIView!
  @IBOutlet weak var imageView: UIImageView!
  @IBOutlet weak var imageContainerView: UIView!
  @IBOutlet weak var tagLabel: UILabel!
  @IBOutlet weak var deleteButton: UIButton!
  
  fileprivate let tagViewPanHelper = TagViewPanHelper()
  open var panLocationInView: CGPoint?
  
  open var text: String? {
    return tagLabel.text
  }
  
  fileprivate var tagIntents: TagIntents!
  
  @IBAction open func tagLabelTapped(_ sender: UITapGestureRecognizer) {
    if tagIsObscured() {
      superview?.bringSubview(toFront: self)
    } else {
      let tapLocation = sender.location(in: self)
      tagIntents.tagTapped.onNext((viewId, .liked(tagLocation: tapLocation)))
      tagIntents.tagTapped.onNext((viewId, .none))
    }
  }
  
  @IBAction open func deleteButtonPressed(_ sender: UIButton) {
    if !canEdit { return }
    
    animateTagDisappearance() { //todo: switch anim from lead to follow?
      self.tagIntents.tagDeleteButtonTapped.onNext(self.viewId)
      self.tagIntents.tagExitedDeleteMode.onNext(self.viewId) //todo: this should be handled in model when tagRemoved fires
    }
  }
  
  @IBAction func imageViewTapped(_ sender: UITapGestureRecognizer) {
    tagIntents.tagIconTapped.onNext((viewId, createdBy))
  }
  
  @IBAction open func longPress(_ sender: UILongPressGestureRecognizer) {
    if !canEdit { return }
    
    if sender.state == .began{
      let deleteButtonCurrentlyHidden = deleteButton.isHidden
      if deleteButtonCurrentlyHidden {
        tagIntents.tagEnteredDeleteMode.onNext(viewId)
      } else {
        tagIntents.tagExitedDeleteMode.onNext(viewId)
      }
    }
  }
  
  var tagSnapshot: UIView?
  @IBAction open func panTag(_ sender: UIPanGestureRecognizer) {
    //do not allow panning when in delete wobble mode
    if !canEdit || !deleteButton.isHidden { return }
    
    switch (sender.state) {
    case .began:
      panLocationInView = sender.location(in: self)
      tagIntents.tagMoved.onNext((viewId, panLocationInView))
      break
    case .ended:
      panLocationInView = nil
      tagIntents.tagMoved.onNext((viewId, nil))
      break
    default:
      if let panLocationInView = panLocationInView {
        let newLocation: CGPoint = sender.location(in: superview)
        let adjustedNewLocation = tagViewPanHelper.adjustedNewLocation(panLocationInView, newPanLocation: newLocation, viewFrame: self.bounds, superviewFrame: (superview?.frame)!)
        tagIntents.tagMoved.onNext((viewId, adjustedNewLocation)) 
      }
    }
  }
  
  fileprivate func panBegin() {
    tagSnapshot = self.snapshotView(afterScreenUpdates: false)
    if let snapshot = tagSnapshot {
      snapshot.frame = self.convert(snapshot.frame, to: self.superview)
      self.superview?.addSubview(snapshot)
      snapshot.center = self.center
      labelContainerView.isHidden = true
      imageContainerView.isHidden = true
      UIView.animate(withDuration: 0.1, animations: {
        snapshot.transform = CGAffineTransform.identity.scaledBy(x: 1.15, y: 1.15)
      })
    }
  }
  
  fileprivate func panEnd() {
    labelContainerView.isHidden = false
    imageContainerView.isHidden = false
    
    tagSnapshot?.removeFromSuperview()
    tagSnapshot = nil 
  }
  
  fileprivate func pan(_ locationInView: CGPoint) {
    self.frame.origin = locationInView
    self.tagSnapshot?.center = self.center
  }
  
  override open func awakeFromNib() {
    super.awakeFromNib()
    setup()
  }
  
  override public init(frame: CGRect) {
    super.init(frame: frame)
    setup()
  }
  
  required public init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    setup()
  }
  
  public init(tagId: String, userId: String, text: NSAttributedString, location: CGPoint, parentSize: CGSize, imgUrl: String, tagIntents: TagIntents){
    let frame = CGRect(x: location.x, y: location.y, width: 0, height: 0)
    self.tagIntents = tagIntents
    self.viewId = tagId
    super.init(frame: frame)
    
    setup()
    
    canEdit = userId == TagOwner.Own //hardcoded for example, but was based on real property
    self.parentSize = parentSize
    tagLabel.attributedText = text
    
    if imgUrl != "" {
      imageView.image = UIImage(named: imgUrl)
    }
    sizeToFit()
    
  }
  
  public convenience init(tagId: String, userId: String, text: NSAttributedString, location: CGPoint, parentSize: CGSize, imgUrl: String, centerOnTooth: Bool, tagIntents: TagIntents){
    self.init(tagId: tagId, userId: userId, text: text, location: location, parentSize: parentSize, imgUrl: imgUrl, tagIntents: tagIntents)
    
    if centerOnTooth {
      //used for long press tags
      centerToothAtPoint(location)
      locateInScreen()
    } else {
      //used to center tag in tag creation view
      self.center = location
    } 
  }
  
  fileprivate func centerToothAtPoint(_ location: CGPoint) {
    let newLocationX = location.x - self.frame.width / 2
    let newLocationY = location.y - (labelContainerView.frame.height + imageView.frame.height / 2)
    self.frame.origin = CGPoint(x: newLocationX, y: newLocationY)
  }
  
  
  override open func didMoveToSuperview() {
    locateInScreen()
  }
  
  fileprivate func setup() {
    NotificationCenter.default.addObserver(self, selector: #selector(TagView.backgroundTapped), name: NSNotification.Name(rawValue: "taggingVCBackgroundTapped"), object: nil)
    
    tagIntents.tagFinishedCreating.onNext(self.viewId)
    
    let views = Bundle.main.loadNibNamed("TagView", owner: self, options: nil)
    if let v = views?.first as? UIView {
      self.addSubview(v)
      v.frame = self.bounds
    }
    
    tagState$.asObservable().scan((TagState.none, TagState.none), accumulator: { (curr, tagState) -> (TagState, TagState) in
      return (curr.1, tagState)
    }).subscribe(onNext: { (oldAndNewTagStates) in
        self.handleStateChange(oldAndNewTagStates.0, newState: oldAndNewTagStates.1)
    }).addDisposableTo(rx_disposeBag)
    
    //label shadow
    labelContainerView.layer.cornerRadius = 6
    labelContainerView.layer.shadowColor = UIColor.black.cgColor
    labelContainerView.layer.shadowOpacity = 0.5
    labelContainerView.layer.shadowOffset = CGSize(width: 0, height: 1)
    labelContainerView.layer.shadowRadius = 2.0
    
    //image container shadow 
    imageContainerView.layer.cornerRadius = imageContainerView.layer.frame.height / 2
    imageContainerView.layer.shadowColor = UIColor.black.cgColor
    imageContainerView.layer.shadowOpacity = 0.5
    imageContainerView.layer.shadowOffset = CGSize(width: 0, height: 2)
    imageContainerView.layer.shadowRadius = 2.0
    
    //image view rounding/styling
    imageView.layer.cornerRadius = imageView.layer.frame.height / 2
    imageView.layer.masksToBounds = true
    imageView.layer.borderWidth = 2
    imageView.layer.borderColor = UIColor.white.cgColor
    
    deleteButton.layer.cornerRadius = deleteButton.layer.frame.height / 2
    
    imageContainerView.layer.shouldRasterize = true
    imageContainerView.layer.rasterizationScale = UIScreen.main.scale
    labelContainerView.layer.shouldRasterize = true
    labelContainerView.layer.rasterizationScale = UIScreen.main.scale
  }
  
  fileprivate func handleStateChange(_ oldState: TagState, newState: TagState) {
    switch(newState){
    case .liked(let tapLocation):
      self.showHeartAnimation(tapLocation)
    case .deleteMode:
      if oldState.shallowEquals(.deleteMode) { return }
      self.enterDeleteMode()
    case .panning(let locationInView):
      if oldState.shallowEquals(.none) {
        panBegin()
      } else {
        pan(locationInView)
      }
    case .none:
      if oldState.shallowEquals(.deleteMode) {
        exitDeleteMode()
        return
      }
      
      if oldState.shallowEquals(.panning(locationInView: CGPoint.zero)) {
        panEnd()
        return
      }
      
      //no op
      return
    case .created, .deleted, .updated:
      fatalError("these tag states handled in vc, should not be here") //todo: reorg enums so this can't happen?
    }
  }
  
  fileprivate func locateInScreen() {
    if let superviewFrame = superview?.frame {
      let rightPhotoBoundary = superviewFrame.origin.x + superviewFrame.width
      let bottomPhotoBoundary = superviewFrame.origin.y + superviewFrame.height - CONTROLS_HEIGHT
      
      let tagOffscreenLeft = frame.origin.x < 0
      let tagOffscreenRight = frame.origin.x + frame.width > rightPhotoBoundary
      let tagOffscreenBottom = frame.origin.y + frame.height > bottomPhotoBoundary
      let tagOffscreenTop = frame.origin.y < CONTROLS_HEIGHT
      
      var newX = frame.origin.x
      if tagOffscreenLeft {
        newX = superviewFrame.origin.x + LABEL_MARGIN
      } else if tagOffscreenRight {
        newX = rightPhotoBoundary - frame.width
      }
      
      var newY = frame.origin.y
      if tagOffscreenTop {
        newY = CONTROLS_HEIGHT
      } else if tagOffscreenBottom {
        newY = bottomPhotoBoundary - frame.height
      }
      
      frame.origin = CGPoint(x: newX, y: newY)
    }
  }
  
  override open func sizeThatFits(_ size: CGSize) -> CGSize {
    let intrinsicWidth = tagLabel.intrinsicContentSize.width
    var desiredLabelWidth = min(intrinsicWidth, MAX_TAG_WIDTH)
    
    //adjust intrinsic width to wrap evenly if more than one line
    if case 225 ... 400 =  intrinsicWidth {
      desiredLabelWidth = intrinsicWidth / 2 + 2 * LABEL_MARGIN
    }
    
    let labelSizeThatFits = tagLabel.sizeThatFits(CGSize(width: desiredLabelWidth, height: CGFloat.greatestFiniteMagnitude))
    
    let labelHeight = labelSizeThatFits.height + 2 * LABEL_MARGIN
    let labelWidth = labelSizeThatFits.width + 2 * LABEL_MARGIN
    
    let desiredHeight = labelHeight + ICON_SIZE + 2 * TAG_CONTAINER_MARGIN
    let desiredWidth = labelWidth + 2 * TAG_CONTAINER_MARGIN
    
    return CGSize(width: desiredWidth, height: desiredHeight)
  }
  
  deinit {
    NotificationCenter.default.removeObserver(self)
  }
  
  fileprivate func tagIsObscured() -> Bool {
    guard let s = self.superview?.subviews else { return true }
    
    if s.last == self {
      return false //short circuit if tag is top subview
    }
    
    let selfIdx = s.index(of: self)
    for (idx, sv) in s.enumerated() {
      if idx > selfIdx {
        if let tagSubview = sv as? TagView {
          if self.tagLabel.frame.intersects(tagSubview.tagLabel.frame) {
            return true
          }
        }
      }
    }
    
    return false
  }
}

//Deletion
extension TagView {
  fileprivate func radians(_ degrees: Double) -> CGFloat {
    return CGFloat((degrees * M_PI) / 180.0)
  }
  
  fileprivate func enterDeleteMode() {
    //    tagIntents.tagEnteredDeleteMode.onNext(viewId)
    
    //must size before entering animation
    deleteButton.isHidden = false
    UIView.animate(withDuration: 0.1, delay: 0.0, options: [], animations: { () -> Void in
      self.deleteButton.alpha = 1.0
      }, completion: { _ in
        self.beginWobble()
    })
  }
  
  fileprivate func exitDeleteMode() {
    UIView.animate(withDuration: 0.1, delay: 0.0, options: [], animations: { () -> Void in
      self.deleteButton.alpha = 0.0
      }, completion: { _ in
        self.endWobble()
        self.deleteButton.isHidden = true
    }) 
    
    //    tagIntents.tagExitedDeleteMode.onNext(viewId)
  }
  
  fileprivate func beginWobble() {
    //initial rotation to start angle
    UIView.animate(withDuration: 0.05, delay: 0.0, options: [], animations: { () -> Void in
      self.transform = CGAffineTransform.identity.rotated(by: self.radians(-3))
    }) { (result) -> Void in
      
      //begin wobble
      UIView.animate(withDuration: 0.1, delay: 0.0, options: [UIViewAnimationOptions.allowUserInteraction,  UIViewAnimationOptions.repeat,  UIViewAnimationOptions.autoreverse], animations: { () -> Void in
        self.transform = CGAffineTransform.identity.rotated(by: self.radians(3))
        }, completion: nil)
    }
  }
  
  fileprivate func endWobble() {
    //rotate back to proper orientation
    UIView.animate( withDuration: 0.1, delay: 0.0, options: [UIViewAnimationOptions.allowUserInteraction, UIViewAnimationOptions.beginFromCurrentState, UIViewAnimationOptions.curveLinear], animations: { () -> Void in
      self.transform = CGAffineTransform.identity;
      }, completion: nil)
  }
  
  func backgroundTapped() {
    if deleteButton.isHidden { return }
    exitDeleteMode()
  }
}

//liking tags
extension TagView {
  fileprivate func showHeartAnimation(_ tapLocation: CGPoint) {
    //create heart to animate
    let heartImage = UIImage(named: "badge_heart_big")
    let heartView = UIImageView(image: heartImage)
    heartView.tag = HEART_VIEW_TAG
    heartView.alpha = 0.0
    
    //add to superview and position
    let frameRelativeToTag = CGRect(x: tapLocation.x, y: -8, width: 28, height: 24.5)
    let convertedFrame = self.convert(frameRelativeToTag, to: self.superview)
    heartView.frame = convertedFrame
    self.superview?.addSubview(heartView)
    
    //create and add animations
    let heartAnim = createHeartAnimation(heartView.frame.origin)
    let bounceAnim = createBounceAnimation()
    heartView.layer.add(heartAnim, forKey: "heartAnimations")
    self.layer.add(bounceAnim, forKey: "labelAnimation")
    
  }
  
  fileprivate func createBounceAnimation() -> CABasicAnimation {
    let bounceAnim = CABasicAnimation(keyPath: "transform.scale")
    bounceAnim.toValue = 1.15
    bounceAnim.autoreverses = true
    bounceAnim.duration = 0.1
    return bounceAnim
  }
  
  fileprivate func createHeartAnimation(_ origin: CGPoint) -> CAAnimationGroup {
    //translation animation
    let translationPath = getTranslationPath(origin)
    let translationAnimation: CAKeyframeAnimation = CAKeyframeAnimation(keyPath: "position")
    translationAnimation.path = translationPath
    
    //rotation animation
    let rotationAnimation = CAKeyframeAnimation(keyPath: "transform.rotation")
    let rotationValues = [radians(-115), radians(15), radians(20), radians(25)]
    rotationAnimation.values = rotationValues
    
    //alpha animation
    let alphaAnimation = CAKeyframeAnimation(keyPath: "opacity")
    let opacityValues = [0, 1, 0.5, 0]
    alphaAnimation.values = opacityValues
    
    //scale animation
    let scaleAnimation = CAKeyframeAnimation(keyPath: "scale")
    let scaleValues = [0.8, 1, 1, 1]
    scaleAnimation.values = scaleValues
    
    //group animations together
    let groupAnimation = CAAnimationGroup()
    groupAnimation.animations = [translationAnimation, rotationAnimation, alphaAnimation, scaleAnimation]
    groupAnimation.duration = 0.75
    groupAnimation.delegate = self
    return groupAnimation
  }
  
  public func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
    viewWithTag(HEART_VIEW_TAG)?.removeFromSuperview()
  }
  
  fileprivate func getTranslationPath(_ startPoint: CGPoint) -> CGPath {
    let heartPath = heartAnimations[animationIdx % heartAnimations.count]
    animationIdx += 1
    
    let path = CGMutablePath()
    path.move(to: CGPoint(x: startPoint.x, y: startPoint.y))
    path.addCurve(to: CGPoint(x: startPoint.x + heartPath.ctrlPt1.x,
                              y: startPoint.y + heartPath.ctrlPt1.y),
                  control1: CGPoint(x: startPoint.x + heartPath.ctrlPt2.x,
                                    y: startPoint.y + heartPath.ctrlPt2.y),
                  control2: CGPoint(x: startPoint.x + heartPath.endPoint.x,
                                    y: startPoint.y + heartPath.endPoint.y))
    /*CGPathAddCurveToPoint(path, nil,
                          startPoint.x + heartPath.ctrlPt1.x,
                          startPoint.y + heartPath.ctrlPt1.y,
                          startPoint.x + heartPath.ctrlPt2.x,
                          startPoint.y + heartPath.ctrlPt2.y,
                          startPoint.x + heartPath.endPoint.x,
                          startPoint.y + heartPath.endPoint.y)*/
    return path
  }
}

//removing tags
extension TagView {
  fileprivate func animateTagDisappearance(_ onCompletion: @escaping () -> Void) {
    let centerPt = self.center
    
    //take and add snapshot
    let snapshot = self.snapshotView(afterScreenUpdates: false)
    snapshot?.center = centerPt
    self.superview?.addSubview(snapshot!)
    
    //hide views
    self.isHidden = true
    
    UIView.animate( withDuration: 0.15, animations: { () -> Void in
      snapshot?.alpha = 0.0
      snapshot?.frame.size = CGSize(width: 0, height: 0)
      snapshot?.center = centerPt
    }, completion: { (_) -> Void in
      onCompletion()
    }) 
  }
}
