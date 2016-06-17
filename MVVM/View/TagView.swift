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

public class TagView: UIView {
  public var viewId: String!
  private var createdBy: String!
  public let tagState$: PublishSubject<TagState> = PublishSubject()
  
  private var canEdit: Bool = false
  private var parentSize: CGSize?
  public var tagLocation: CGPoint {
    get {
      if let size = parentSize {
        let x: CGFloat = CGFloat(self.frame.origin.x / size.width)
        let y: CGFloat = CGFloat(self.frame.origin.y / size.height)
        
        return CGPoint(x: x, y: y)
      }
      return CGPointZero
    }
  }
  
  private let MAX_TAG_WIDTH: CGFloat = CGFloat(224)
  private let ICON_SIZE = CGFloat(28)
  private let TAG_CONTAINER_MARGIN = CGFloat(10)
  private let LABEL_MARGIN = CGFloat(4)
  private let HEART_VIEW_TAG = 77
  private let CONTROLS_HEIGHT = CGFloat(64)
  
  private let heartAnimations = [
    HeartAnimationPath(pt1: CGPoint(x: 0.8, y: -30.7), pt2: CGPoint(x: 17, y: -56.4), end: CGPoint(x: 33.6, y: -75.5)),
    HeartAnimationPath(pt1: CGPoint(x: 0.8, y: -30.7), pt2: CGPoint(x: 17, y: -56.4), end: CGPoint(x: 51, y: -50.7)),
    HeartAnimationPath(pt1: CGPoint(x: -0.6, y: -26.3), pt2: CGPoint(x: -10.6, y: -45.7), end: CGPoint(x: -33.8, y: -61.1)),
    ]
  private var animationIdx = 0
  
  @IBOutlet weak var labelContainerView: UIView!
  @IBOutlet weak var imageView: UIImageView!
  @IBOutlet weak var imageContainerView: UIView!
  @IBOutlet weak var tagLabel: UILabel!
  @IBOutlet weak var deleteButton: UIButton!
  
  private let tagViewPanHelper = TagViewPanHelper()
  public var panLocationInView: CGPoint?
  
  public var text: String? {
    return tagLabel.text
  }
  
  private var tagIntents: TagIntents!
  
  @IBAction public func tagLabelTapped(sender: UITapGestureRecognizer) {
    if tagIsObscured() {
      superview?.bringSubviewToFront(self)
    } else {
      let tapLocation = sender.locationInView(self)
      tagIntents.tagTapped.onNext((viewId, .Liked(tagLocation: tapLocation)))
      tagIntents.tagTapped.onNext((viewId, .None))
    }
  }
  
  @IBAction public func deleteButtonPressed(sender: UIButton) {
    if !canEdit { return }
    
    animateTagDisappearance() { //todo: switch anim from lead to follow?
      self.tagIntents.tagDeleteButtonTapped.onNext(self.viewId)
      self.tagIntents.tagExitedDeleteMode.onNext(self.viewId) //todo: this should be handled in model when tagRemoved fires
    }
  }
  
  @IBAction func imageViewTapped(sender: UITapGestureRecognizer) {
    tagIntents.tagIconTapped.onNext((viewId, createdBy))
  }
  
  @IBAction public func longPress(sender: UILongPressGestureRecognizer) {
    if !canEdit { return }
    
    if sender.state == .Began{
      let deleteButtonCurrentlyHidden = deleteButton.hidden
      if deleteButtonCurrentlyHidden {
        tagIntents.tagEnteredDeleteMode.onNext(viewId)
      } else {
        tagIntents.tagExitedDeleteMode.onNext(viewId)
      }
    }
  }
  
  var tagSnapshot: UIView?
  @IBAction public func panTag(sender: UIPanGestureRecognizer) {
    //do not allow panning when in delete wobble mode
    if !canEdit || !deleteButton.hidden { return }
    
    switch (sender.state) {
    case .Began:
      panLocationInView = sender.locationInView(self)
      tagIntents.tagMoved.onNext((viewId, panLocationInView))
      break
    case .Ended:
      panLocationInView = nil
      tagIntents.tagMoved.onNext((viewId, nil))
      break
    default:
      if let panLocationInView = panLocationInView {
        let newLocation: CGPoint = sender.locationInView(superview)
        let adjustedNewLocation = tagViewPanHelper.adjustedNewLocation(panLocationInView, newPanLocation: newLocation, viewFrame: self.bounds, superviewFrame: (superview?.frame)!)
        tagIntents.tagMoved.onNext((viewId, adjustedNewLocation)) 
      }
    }
  }
  
  private func panBegin() {
    tagSnapshot = self.snapshotViewAfterScreenUpdates(false)
    if let snapshot = tagSnapshot {
      snapshot.frame = self.convertRect(snapshot.frame, toView: self.superview)
      self.superview?.addSubview(snapshot)
      snapshot.center = self.center
      labelContainerView.hidden = true
      imageContainerView.hidden = true
      UIView.animateWithDuration(0.1, animations: {
        snapshot.transform = CGAffineTransformScale(CGAffineTransformIdentity, 1.15, 1.15)
      })
    }
  }
  
  private func panEnd() {
    labelContainerView.hidden = false
    imageContainerView.hidden = false
    
    tagSnapshot?.removeFromSuperview()
    tagSnapshot = nil 
  }
  
  private func pan(locationInView: CGPoint) {
    self.frame.origin = locationInView
    self.tagSnapshot?.center = self.center
  }
  
  override public func awakeFromNib() {
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
  
  public init(id: String, text: NSAttributedString, location: CGPoint, parentSize: CGSize, imgUrl: String, tagIntents: TagIntents){
    let frame = CGRect(x: location.x, y: location.y, width: 0, height: 0)
    self.tagIntents = tagIntents
    self.viewId = id
    super.init(frame: frame)
    
    setup()
    
    canEdit = true //tag is created by current user
    self.parentSize = parentSize
    tagLabel.attributedText = text
    
    //todo: handle photo
//    if imgUrl != "" {
//      let url = NSURL(string: imgUrl)
//      imageView.yr_setImageWithUrl(url!)
//    }
    sizeToFit()
    
  }
  
  public convenience init(id: String, text: NSAttributedString, location: CGPoint, parentSize: CGSize, imgUrl: String, centerOnTooth: Bool, tagIntents: TagIntents){
    self.init(id: id, text: text, location: location, parentSize: parentSize, imgUrl: imgUrl, tagIntents: tagIntents)
    
    if centerOnTooth {
      //used for long press tags
      centerToothAtPoint(location)
      locateInScreen()
    } else {
      //used to center tag in tag creation view
      self.center = location
    } 
  }
  
  private func centerToothAtPoint(location: CGPoint) {
    let newLocationX = location.x - self.frame.width / 2
    let newLocationY = location.y - (labelContainerView.frame.height + imageView.frame.height / 2)
    self.frame.origin = CGPoint(x: newLocationX, y: newLocationY)
  }
  
  
  override public func didMoveToSuperview() {
    locateInScreen()
  }
  
  private func setup() {
    NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(TagView.backgroundTapped), name: "taggingVCBackgroundTapped", object: nil)
    
    tagIntents.tagFinishedCreating.onNext(self.viewId)
    
    let views = NSBundle.mainBundle().loadNibNamed("TagView", owner: self, options: nil)
    if let v = views.first as? UIView {
      self.addSubview(v)
      v.frame = self.bounds
    }
    
    tagState$.asObservable().scan((TagState.None, TagState.None), accumulator: { (curr, tagState) -> (TagState, TagState) in
      return (curr.1, tagState)
    }).subscribeNext { (oldAndNewTagStates) in
      self.handleStateChange(oldAndNewTagStates.0, newState: oldAndNewTagStates.1)
      }.addDisposableTo(rx_disposeBag)
    
    //label shadow
    labelContainerView.layer.cornerRadius = 6
    labelContainerView.layer.shadowColor = UIColor.blackColor().CGColor
    labelContainerView.layer.shadowOpacity = 0.5
    labelContainerView.layer.shadowOffset = CGSize(width: 0, height: 1)
    labelContainerView.layer.shadowRadius = 2.0
    
    //image container shadow 
    imageContainerView.layer.cornerRadius = imageContainerView.layer.frame.height / 2
    imageContainerView.layer.shadowColor = UIColor.blackColor().CGColor
    imageContainerView.layer.shadowOpacity = 0.5
    imageContainerView.layer.shadowOffset = CGSize(width: 0, height: 2)
    imageContainerView.layer.shadowRadius = 2.0
    
    //image view rounding/styling
    imageView.layer.cornerRadius = imageView.layer.frame.height / 2
    imageView.layer.masksToBounds = true
    imageView.layer.borderWidth = 2
    imageView.layer.borderColor = UIColor.whiteColor().CGColor
    
    deleteButton.layer.cornerRadius = deleteButton.layer.frame.height / 2
    
    imageContainerView.layer.shouldRasterize = true
    imageContainerView.layer.rasterizationScale = UIScreen.mainScreen().scale
    labelContainerView.layer.shouldRasterize = true
    labelContainerView.layer.rasterizationScale = UIScreen.mainScreen().scale
  }
  
  private func handleStateChange(oldState: TagState, newState: TagState) {
    switch(newState){
    case .Liked(let tapLocation):
      self.showHeartAnimation(tapLocation)
    case .DeleteMode:
      if oldState.shallowEquals(.DeleteMode) { return }
      self.enterDeleteMode()
    case .Panning(let locationInView):
      if oldState.shallowEquals(.None) {
        panBegin()
      } else {
        pan(locationInView)
      }
    case .None:
      if oldState.shallowEquals(.DeleteMode) {
        exitDeleteMode()
        return
      }
      
      if oldState.shallowEquals(.Panning(locationInView: CGPointZero)) {
        panEnd()
        return
      }
      
      //no op
      return
    case .Created, .Deleted, .Updated:
      fatalError("these tag states handled in vc, should not be here") //todo: reorg enums so this can't happen?
    }
  }
  
  private func locateInScreen() {
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
  
  override public func sizeThatFits(size: CGSize) -> CGSize {
    let intrinsicWidth = tagLabel.intrinsicContentSize().width
    var desiredLabelWidth = min(intrinsicWidth, MAX_TAG_WIDTH)
    
    //adjust intrinsic width to wrap evenly if more than one line
    if case 225 ... 400 =  intrinsicWidth {
      desiredLabelWidth = intrinsicWidth / 2 + 2 * LABEL_MARGIN
    }
    
    let labelSizeThatFits = tagLabel.sizeThatFits(CGSize(width: desiredLabelWidth, height: CGFloat.max))
    
    let labelHeight = labelSizeThatFits.height + 2 * LABEL_MARGIN
    let labelWidth = labelSizeThatFits.width + 2 * LABEL_MARGIN
    
    let desiredHeight = labelHeight + ICON_SIZE + 2 * TAG_CONTAINER_MARGIN
    let desiredWidth = labelWidth + 2 * TAG_CONTAINER_MARGIN
    
    return CGSize(width: desiredWidth, height: desiredHeight)
  }
  
  deinit {
    NSNotificationCenter.defaultCenter().removeObserver(self)
  }
  
  private func tagIsObscured() -> Bool {
    guard let s = self.superview?.subviews else { return true }
    
    if s.last == self {
      return false //short circuit if tag is top subview
    }
    
    let selfIdx = s.indexOf(self)
    for (idx, sv) in s.enumerate() {
      if idx > selfIdx {
        if let tagSubview = sv as? TagView {
          if CGRectIntersectsRect(self.tagLabel.frame, tagSubview.tagLabel.frame) {
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
  private func radians(degrees: Double) -> CGFloat {
    return CGFloat((degrees * M_PI) / 180.0)
  }
  
  private func enterDeleteMode() {
    //    tagIntents.tagEnteredDeleteMode.onNext(viewId)
    
    //must size before entering animation
    deleteButton.hidden = false
    UIView.animateWithDuration(0.1, delay: 0.0, options: [], animations: { () -> Void in
      self.deleteButton.alpha = 1.0
      }, completion: { _ in
        self.beginWobble()
    })
  }
  
  private func exitDeleteMode() {
    UIView.animateWithDuration(0.1, delay: 0.0, options: [], animations: { () -> Void in
      self.deleteButton.alpha = 0.0
      }, completion: { _ in
        self.endWobble()
        self.deleteButton.hidden = true
    }) 
    
    //    tagIntents.tagExitedDeleteMode.onNext(viewId)
  }
  
  private func beginWobble() {
    //initial rotation to start angle
    UIView.animateWithDuration(0.05, delay: 0.0, options: [], animations: { () -> Void in
      self.transform = CGAffineTransformRotate(CGAffineTransformIdentity, self.radians(-3))
    }) { (result) -> Void in
      
      //begin wobble
      UIView.animateWithDuration(0.1, delay: 0.0, options: [UIViewAnimationOptions.AllowUserInteraction,  UIViewAnimationOptions.Repeat,  UIViewAnimationOptions.Autoreverse], animations: { () -> Void in
        self.transform = CGAffineTransformRotate(CGAffineTransformIdentity, self.radians(3))
        }, completion: nil)
    }
  }
  
  private func endWobble() {
    //rotate back to proper orientation
    UIView.animateWithDuration( 0.1, delay: 0.0, options: [UIViewAnimationOptions.AllowUserInteraction, UIViewAnimationOptions.BeginFromCurrentState, UIViewAnimationOptions.CurveLinear], animations: { () -> Void in
      self.transform = CGAffineTransformIdentity;
      }, completion: nil)
  }
  
  func backgroundTapped() {
    if deleteButton.hidden { return }
    exitDeleteMode()
  }
}

//liking tags
extension TagView {
  private func showHeartAnimation(tapLocation: CGPoint) {
    //create heart to animate
    let heartImage = UIImage(named: "badge_heart_big")
    let heartView = UIImageView(image: heartImage)
    heartView.tag = HEART_VIEW_TAG
    heartView.alpha = 0.0
    
    //add to superview and position
    let frameRelativeToTag = CGRect(x: tapLocation.x, y: -8, width: 28, height: 24.5)
    let convertedFrame = self.convertRect(frameRelativeToTag, toView: self.superview)
    heartView.frame = convertedFrame
    self.superview?.addSubview(heartView)
    
    //create and add animations
    let heartAnim = createHeartAnimation(heartView.frame.origin)
    let bounceAnim = createBounceAnimation()
    heartView.layer.addAnimation(heartAnim, forKey: "heartAnimations")
    self.layer.addAnimation(bounceAnim, forKey: "labelAnimation")
    
  }
  
  private func createBounceAnimation() -> CABasicAnimation {
    let bounceAnim = CABasicAnimation(keyPath: "transform.scale")
    bounceAnim.toValue = 1.15
    bounceAnim.autoreverses = true
    bounceAnim.duration = 0.1
    return bounceAnim
  }
  
  private func createHeartAnimation(origin: CGPoint) -> CAAnimationGroup {
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
  
  override public func animationDidStop(anim: CAAnimation, finished flag: Bool) {
    viewWithTag(HEART_VIEW_TAG)?.removeFromSuperview()
  }
  
  private func getTranslationPath(startPoint: CGPoint) -> CGPathRef {
    let heartPath = heartAnimations[animationIdx % heartAnimations.count]
    animationIdx += 1
    
    let path = CGPathCreateMutable()
    CGPathMoveToPoint(path, nil, startPoint.x, startPoint.y)
    CGPathAddCurveToPoint(path, nil,
                          startPoint.x + heartPath.ctrlPt1.x,
                          startPoint.y + heartPath.ctrlPt1.y,
                          startPoint.x + heartPath.ctrlPt2.x,
                          startPoint.y + heartPath.ctrlPt2.y,
                          startPoint.x + heartPath.endPoint.x,
                          startPoint.y + heartPath.endPoint.y)
    return path
  }
}

//removing tags
extension TagView {
  private func animateTagDisappearance(onCompletion: () -> Void) {
    let centerPt = self.center
    
    //take and add snapshot
    let snapshot = self.snapshotViewAfterScreenUpdates(false)
    snapshot.center = centerPt
    self.superview?.addSubview(snapshot)
    
    //hide views
    self.hidden = true
    
    UIView.animateWithDuration( 0.15, animations: { () -> Void in
      snapshot.alpha = 0.0
      snapshot.frame.size = CGSize(width: 0, height: 0)
      snapshot.center = centerPt
    }) { (_) -> Void in
      onCompletion()
    }
  }
}