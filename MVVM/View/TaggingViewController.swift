//
//  TaggingViewController.swift
//  yaroll
//
//  Created by Ben Garrett on 2/9/16.
//  Copyright © 2016 Math Camp. All rights reserved.
//

import Foundation
import UIKit
import RxCocoa
import RxSwift

public enum TagCreationEvent {
  case Started
  case Ended
}

class TaggingViewController: UIViewController, ViewModelBinder {
  //VIEWS
  @IBOutlet weak var textView: UITextView!
  @IBOutlet weak var backgroundView: UIView!
  @IBOutlet weak var tagTableContainerView: UIView!
  @IBOutlet weak var tagContainerView: PassThroughView!
  @IBOutlet weak var tagCreationContainerView: UIView!
  @IBOutlet weak var placeholderLabel: UILabel!
  @IBOutlet weak var containerHeight: NSLayoutConstraint!
  @IBOutlet weak var taggingTableViewController: TaggingTableViewController!
  weak var tagTableBridgeView: UIView? //view between tag label and tag table vc to hide rounded edges
  
  //NECESSARY(?) EVILS
  let tagCreationEventSubject: PublishSubject<TagCreationEvent> = PublishSubject<TagCreationEvent>() //Parent VC (TaggingCardstackVC) uses this to know when to hide/show chrome
  var originalContainerHeight:CGFloat = 0.0
  var parentPhotoSize: CGSize?
  var tagViewsDisplayed: Dictionary<String, TagView> = Dictionary()
  
  //NEW MODEL VARS
  var tagIntents: TagIntents = TagIntents()
  var tagVCIntents: TagVCIntents = TagVCIntents()
  
  typealias VM = TagViewModel
  
  var realModel: ConcreteTagModel!
  var vm: VM!
  
//  var photoData: PhotoData? {
//    didSet {
//      if let photoData = photoData {
//        tagVCIntents.photoDataChanged.onNext(photoData)
//      }
//    }
//  }
  
  override func prefersStatusBarHidden() -> Bool {
    return true
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    tagCreationContainerView.hidden = true
  }
  
  override func viewWillAppear(animated: Bool) {
    super.viewWillAppear(animated)
    
    realModel =  ConcreteTagModel(tagIntents: tagIntents, tagVCIntents: tagVCIntents)
    vm = TagViewModel.make(realModel)
    bind(vm)
    
    backgroundView.hidden = true
    originalContainerHeight = containerHeight.constant
    
    navigationController?.setNavigationBarHidden(true, animated: false)
    tagTableContainerView.layer.cornerRadius = 10
    tagTableContainerView.clipsToBounds = true
    tagTableContainerView.layer.masksToBounds = false
    createShadow(tagCreationContainerView)
    createShadow(tagTableContainerView)
    
    resizeIfNeeded()
    self.automaticallyAdjustsScrollViewInsets = false
    textView.delegate = self
    
    self.prepareBridgeView()
  }
  
  
  private func textWithResizeBindable(textView: UITextView) -> UIBindingObserver<UITextView, String> {
    return UIBindingObserver<UITextView, String>(UIElement: textView, binding: { (textView: UITextView, text: String) in
      textView.text = text
      self.optTextViewDidChange(textView)
    })
  }
  
  var yr_tagTableFilterText: UIBindingObserver<TaggingTableViewController, String> {
    return UIBindingObserver<TaggingTableViewController, String>(UIElement: taggingTableViewController, binding: { (tagTableVC: TaggingTableViewController, filterText: String) in
      tagTableVC.updateSearchText(filterText)
    })
  }
  
  func bindViews(vm: VM) -> (Arity, [Disposable]) {
    let vm = vm.drivers
    return (arity(TagViewModel.Drivers.init), [
      vm.backgroundHidden
        .bindTo(backgroundView.rx_hidden),
      
      vm.placeholderHidden
        .bindTo(placeholderLabel.rx_hidden),
      
      vm.text
        .filterNotNil()
        .bindTo(textWithResizeBindable(textView)),
      
      vm.tagTableHidden
        .driveNext{ [weak self] isHidden in
          self?.setViewHidden(self?.tagTableContainerView, hidden: isHidden, animated: true) { }
      },
      
      vm.tagTableBridgeHidden
        .driveNext{ [weak self] isHidden in
          self?.setViewHidden(self?.tagTableBridgeView, hidden: isHidden, animated: true) { }
      },
      
      vm.tagCreationContainerHidden
        .driveNext(self.onTagCreationContainerHidden), //todo: does this leak memory?
      
      vm.displayTags
        .driveNext(self.onDisplayTags), //todo: does this leak memory?
      
      vm.tagTableQuery
        .bindTo(yr_tagTableFilterText)
      ])
  }
  
  private func onDisplayTags(tagDict: Dictionary<String, TagViewData>) {
    tagDict.values.forEach{ (tagViewData: TagViewData) in
      switch(tagViewData.state){
      case .Created:
        self.displayTag(tagViewData)
      case .Deleted:
        self.deleteTag(tagViewData)
      case .Updated:
        //todo: can do a smarter update in future
        if let tagView = tagViewsDisplayed[tagViewData.id] {
          tagView.removeFromSuperview()
          tagViewsDisplayed.removeValueForKey(tagViewData.id)
        }
        self.displayTag(tagViewData)
      case .DeleteMode, .Liked, .None, .Panning:
        //forward to tag
        if let tagView = self.tagViewsDisplayed[tagViewData.id] {
          tagView.tagState$.onNext(tagViewData.state)
        } else {
          fatalError("trying to forward new state to nonexistant view \(tagViewData)")
        }
      }
    }
  }
  
  private func onTagCreationContainerHidden(isHidden: Bool) {
    if isHidden { tagCreationEventSubject.onNext(.Ended) }
    else { tagCreationEventSubject.onNext(.Started) }
    
    backgroundView.hidden = isHidden
    setViewHidden(tagCreationContainerView, hidden: isHidden, animated: true) { [weak self] in
      if isHidden {
        self?.textView.resignFirstResponder()
        if let originalContainerHeight = self?.originalContainerHeight {
          self?.containerHeight.constant = originalContainerHeight
        }
      } else {
        //in tag mode
        self?.makeTextViewFirstResponder()
      }
    }
  }
  
  private func deleteTag(tagViewData: TagViewData) {
    if let tagView = tagViewsDisplayed[tagViewData.id] {
      tagView.removeFromSuperview()
      tagViewsDisplayed.removeValueForKey(tagViewData.id)
      tagVCIntents.tagRemovedFromVC.onNext(tagViewData.id)
    } else {
      fatalError("Trying to remove a tagView that is not in the dict \(tagViewData)")
    }
  }
  
  private func prepareBridgeView() {
    if tagTableBridgeView == nil {
      let bridgeView = UIView()
      bridgeView.frame.size = CGSize(width: tagTableContainerView.frame.width, height: 20)
      bridgeView.backgroundColor = UIColor.whiteColor()
      bridgeView.alpha = 0.0
      self.view.addSubview(bridgeView)
      self.tagTableBridgeView = bridgeView
    }
    
    //prepare bridge view
    tagTableBridgeView?.frame.origin = CGPoint(x: tagTableContainerView.frame.origin.x, y: tagTableContainerView.frame.origin.y - 10)
  }
  
  func setViewHidden(view: UIView?, hidden: Bool, animated: Bool, onComplete: () -> Void) {
    guard let view = view else { return }
    
    if view.hidden == hidden { return }
    
    var animationTime = 0.3
    if animated == false { animationTime = 0.0 }
    
    if view.hidden { view.hidden = false }
    
    UIView.animateWithDuration(animationTime, animations: { () -> Void in
      if hidden {
        view.alpha = 0.0
      } else {
        view.alpha = 1.0
      }
    }) { (_) -> Void in
      view.hidden = hidden
      onComplete()
    }
  }
  
  override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    if segue.identifier == "segueTaggingEmbedTaggingTable" {
      if let tableVC = segue.destinationViewController as? TaggingTableViewController {
        taggingTableViewController = tableVC
        taggingTableViewController.taggingDelegate = self
      }
    }
  }
  
//  func upperCardChanged(parentPhotoSize: CGSize, photoData: PhotoData ) {
////    taggingModel?.sync()
//    self.parentPhotoSize = parentPhotoSize
//    tagVCIntents.upperCardChanged.onNext(photoData)
//  }
  
  // TODO: HACK CITY
  func unload() {
    taggingTableViewController?.viewWillDisappear(false)
    taggingTableViewController?.willMoveToParentViewController(nil)
    taggingTableViewController?.view.removeFromSuperview()
    taggingTableViewController?.removeFromParentViewController()
    taggingTableViewController?.taggingDelegate = nil
    taggingTableViewController = nil
  }
  
  override func viewWillDisappear(animated: Bool) {
    tagVCIntents.syncWithServer.onNext()
    super.viewWillDisappear(animated)
  }
  
  func makeTextViewFirstResponder() {
    backgroundView.hidden = false
    textView.becomeFirstResponder()
  }
  
  @IBAction func tappedBackgroundView(caller: NSObject) {
    tagVCIntents.backgroundTapped.onNext()
  }

  func createShadow(view: UIView?) {
    view?.layer.shadowOpacity = 0.5
    view?.layer.shadowRadius = 2.0
    view?.layer.shadowColor = UIColor.blackColor().CGColor
    view?.layer.shadowOffset = CGSizeMake(0.0, 1.0)
    view?.layer.shouldRasterize = true
    view?.layer.rasterizationScale = UIScreen.mainScreen().scale
  }
}

//making and displaying tags
extension TaggingViewController {
  private func displayTag(tagViewData: TagViewData) {
    switch(tagViewData) {
    case .ServerTag(let tag, _, _):
      self.displayTagFromServer(tag)
    case .UserCreatedTag(let tagInfo, _, _):
      self.displayTagFromUser(tagInfo)
    }
  }
  
  private func displayTagFromServer(tag: PhotoTypes.Tag) {
    let imgUrl = "" //todo: generate image url from tag.createdBy
    let tagView = TagView(id: tag.tagId, text: tag.text, location: tag.location, parentSize: getParentSize(), imgUrl: imgUrl, tagIntents: tagIntents)
    tagContainerView.addSubview(tagView)
    tagViewsDisplayed[tagView.viewId] = tagView
  }
  
  private func displayTagFromUser(tagInfo: UserTagInfo) {
    let tagView: TagView
    
    switch(tagInfo.location){
    case .Some(.CustomLocation(let location)):
      tagView = TagView(id: tagInfo.id , text: tagInfo.text, location: location, parentSize: getParentSize(), imgUrl: tagInfo.imgUrl, centerOnTooth: tagInfo.centerOnTooth, tagIntents: tagIntents)
    default:
      let location = tagCreationContainerView.center
      tagView = TagView(id: tagInfo.id, text: tagInfo.text, location: location, parentSize: getParentSize(), imgUrl: tagInfo.imgUrl, tagIntents: tagIntents)
    }
    
    tagContainerView.addSubview(tagView)
    tagViewsDisplayed[tagView.viewId] = tagView
  }
  
  private func getParentSize() -> CGSize {
    if let size = parentPhotoSize {
      return size
    }
    
    return CGSize(width: UIScreen.mainScreen().bounds.width, height: UIScreen.mainScreen().bounds.height)
  }
}

//creating new tags with text view
extension TaggingViewController: UITextViewDelegate {
  func textView(textView: UITextView, shouldChangeTextInRange range: NSRange, replacementText text: String) -> Bool {
    tagVCIntents.textChanged.onNext(text)
    return false 
  }
  
  func optTextViewDidChange(textView: UITextView?){
    guard textView != nil else { return }
    
    resizeIfNeeded()
  }
  
  private func showPlaceholderIfNeeded() {
    if (textView.text.characters.count) > 0 {
      placeholderLabel.hidden = true
    } else {
      placeholderLabel.hidden = false
    }
  }
  
  private func resizeIfNeeded() {
    textView.layoutManager.ensureLayoutForTextContainer(textView.textContainer)
    
    let containerSize = textView.layoutManager.usedRectForTextContainer(textView.textContainer).size
    let height = ceil(containerSize.height + textView.textContainerInset.top + textView.textContainerInset.bottom)*1.25
    
    containerHeight.constant = height
    textView.layoutIfNeeded()
    textView.setContentOffset(CGPointMake(0, -textView.contentInset.top), animated: false)
  }
}

extension TaggingViewController: TaggingTableDelegate {
  func matchedContactSelected(matchedContact: ContactModel.MatchedContact) {
    let currentTextViewText = textView.text
    
    let words: [String] = currentTextViewText.characters.split{$0 == " "}.map(String.init)
    if let partialTag = words.last {
      let fullTag = "@" + matchedContact.username
      let startIdx = fullTag.startIndex.advancedBy(partialTag.characters.count)
      let remainingTagText = fullTag.substringFromIndex(startIdx)
      
      tagVCIntents.textChanged.onNext(remainingTagText + " ")
    }
  }
  
  func sizeChanged(contentSize: CGSize) {
    dispatch_async(dispatch_get_main_queue()) {
      var frame = self.tagTableContainerView.frame
      let maxHeight = CGFloat(250)
      frame.size.height = min(contentSize.height, maxHeight)
      self.tagTableContainerView.frame = frame
    }
  }
}
