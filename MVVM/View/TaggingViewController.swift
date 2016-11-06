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
import NSObject_Rx

public enum TagCreationEvent {
  case started
  case ended
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
  
  override var prefersStatusBarHidden : Bool {
    return true
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    tagCreationContainerView.isHidden = true
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    
    realModel =  ConcreteTagModel(tagIntents: tagIntents, tagVCIntents: tagVCIntents)
    vm = TagViewModel.make(realModel)
    bind(vm)
    
    backgroundView.isHidden = true
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
  
  
  fileprivate func textWithResizeBindable(_ textView: UITextView) -> UIBindingObserver<UITextView, String> {
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
  
  func bindViews(_ vm: VM) -> (Arity, [Disposable]) {
    let vm = vm.drivers
    return (arity(TagViewModel.Drivers.init), [
      vm.backgroundHidden
        .bindTo(backgroundView.rx.isHidden),
      
      vm.placeholderHidden
        .bindTo(placeholderLabel.rx.isHidden),
      
      vm.text
        .filterNotNil()
        .bindTo(textWithResizeBindable(textView)),
      
      vm.tagTableHidden
        .drive(onNext: { [weak self] isHidden in
            self?.setViewHidden(self?.tagTableContainerView, hidden: isHidden, animated: true) { }
        }),
      
      vm.tagTableBridgeHidden
        .drive(onNext:{ [weak self] isHidden in
          self?.setViewHidden(self?.tagTableBridgeView, hidden: isHidden, animated: true) { }
      }),
      
      vm.tagCreationContainerHidden
        .drive(onNext: (self.onTagCreationContainerHidden)), //todo: does this leak memory?
      
      vm.displayTags
        .drive(onNext: (self.onDisplayTags)), //todo: does this leak memory?
      
      vm.tagTableQuery
        .bindTo(yr_tagTableFilterText)
      ])
  }
  
  fileprivate func onDisplayTags(_ tagDict: Dictionary<String, TagViewData>) {
    tagDict.values.forEach{ (tagViewData: TagViewData) in
      switch(tagViewData.state){
      case .created:
        self.displayTag(tagViewData)
      case .deleted:
        self.deleteTag(tagViewData)
      case .updated:
        //todo: can do a smarter update in future
        if let tagView = tagViewsDisplayed[tagViewData.id] {
          tagView.removeFromSuperview()
          tagViewsDisplayed.removeValue(forKey: tagViewData.id)
        }
        self.displayTag(tagViewData)
      case .deleteMode, .liked, .none, .panning:
        //forward to tag
        if let tagView = self.tagViewsDisplayed[tagViewData.id] {
          tagView.tagState$.onNext(tagViewData.state)
        } else {
          fatalError("trying to forward new state to nonexistant view \(tagViewData)")
        }
      }
    }
  }
  
  fileprivate func onTagCreationContainerHidden(_ isHidden: Bool) {
    if isHidden { tagCreationEventSubject.onNext(.ended) }
    else { tagCreationEventSubject.onNext(.started) }
    
    backgroundView.isHidden = isHidden
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
  
  fileprivate func deleteTag(_ tagViewData: TagViewData) {
    if let tagView = tagViewsDisplayed[tagViewData.id] {
      tagView.removeFromSuperview()
      tagViewsDisplayed.removeValue(forKey: tagViewData.id)
      tagVCIntents.tagRemovedFromVC.onNext(tagViewData.id)
    } else {
      fatalError("Trying to remove a tagView that is not in the dict \(tagViewData)")
    }
  }
  
  fileprivate func prepareBridgeView() {
    if tagTableBridgeView == nil {
      let bridgeView = UIView()
      bridgeView.frame.size = CGSize(width: tagTableContainerView.frame.width, height: 20)
      bridgeView.backgroundColor = UIColor.white
      bridgeView.alpha = 0.0
      self.view.addSubview(bridgeView)
      self.tagTableBridgeView = bridgeView
    }
    
    //prepare bridge view
    tagTableBridgeView?.frame.origin = CGPoint(x: tagTableContainerView.frame.origin.x, y: tagTableContainerView.frame.origin.y - 10)
  }
  
  func setViewHidden(_ view: UIView?, hidden: Bool, animated: Bool, onComplete: @escaping () -> Void) {
    guard let view = view else { return }
    
    if view.isHidden == hidden { return }
    
    var animationTime = 0.3
    if animated == false { animationTime = 0.0 }
    
    if view.isHidden { view.isHidden = false }
    
    UIView.animate(withDuration: animationTime, animations: { () -> Void in
      if hidden {
        view.alpha = 0.0
      } else {
        view.alpha = 1.0
      }
    }, completion: { (_) -> Void in
      view.isHidden = hidden
      onComplete()
    }) 
  }
  
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if segue.identifier == "segueTaggingEmbedTaggingTable" {
      if let tableVC = segue.destination as? TaggingTableViewController {
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
    taggingTableViewController?.willMove(toParentViewController: nil)
    taggingTableViewController?.view.removeFromSuperview()
    taggingTableViewController?.removeFromParentViewController()
    taggingTableViewController?.taggingDelegate = nil
    taggingTableViewController = nil
  }
  
  override func viewWillDisappear(_ animated: Bool) {
    tagVCIntents.syncWithServer.onNext()
    super.viewWillDisappear(animated)
  }
  
  func makeTextViewFirstResponder() {
    backgroundView.isHidden = false
    textView.becomeFirstResponder()
  }
  
  @IBAction func tappedBackgroundView(_ caller: NSObject) {
    tagVCIntents.backgroundTapped.onNext()
  }

  func createShadow(_ view: UIView?) {
    view?.layer.shadowOpacity = 0.5
    view?.layer.shadowRadius = 2.0
    view?.layer.shadowColor = UIColor.black.cgColor
    view?.layer.shadowOffset = CGSize(width: 0.0, height: 1.0)
    view?.layer.shouldRasterize = true
    view?.layer.rasterizationScale = UIScreen.main.scale
  }
}

//making and displaying tags
extension TaggingViewController {
  fileprivate func displayTag(_ tagViewData: TagViewData) {
    switch(tagViewData) {
    case .serverTag(let tag, _, _):
      self.displayTagFromServer(tag)
    case .userCreatedTag(let tagInfo, _, _):
      self.displayTagFromUser(tagInfo)
    }
  }
  
  fileprivate func displayTagFromServer(_ tag: PhotoTypes.Tag) {
    let imgUrl = tag.createdBy == TagOwner.Own ? "dog-pink" : "dog-yellow"
    let tagView = TagView(tagId: tag.tagId, userId: tag.createdBy, text: tag.text, location: tag.location, parentSize: getParentSize(), imgUrl: imgUrl, tagIntents: tagIntents)
    tagContainerView.addSubview(tagView)
    tagViewsDisplayed[tagView.viewId] = tagView
  }
  
  fileprivate func displayTagFromUser(_ tagInfo: UserTagInfo) {
    let tagView: TagView
    let tagOwner = TagOwner.Own //By definition, tag is owned by current user
    
    switch(tagInfo.location){
    case .some(.customLocation(let location)):
      tagView = TagView(tagId: tagInfo.id, userId: tagOwner, text: tagInfo.text, location: location, parentSize: getParentSize(), imgUrl: tagInfo.imgUrl, centerOnTooth: tagInfo.centerOnTooth, tagIntents: tagIntents)
    default:
      let location = tagCreationContainerView.center
      tagView = TagView(tagId: tagInfo.id, userId: tagOwner, text: tagInfo.text, location: location, parentSize: getParentSize(), imgUrl: tagInfo.imgUrl, tagIntents: tagIntents)
    }
    
    tagContainerView.addSubview(tagView)
    tagViewsDisplayed[tagView.viewId] = tagView
  }
  
  fileprivate func getParentSize() -> CGSize {
    if let size = parentPhotoSize {
      return size
    }
    
    return CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
  }
}

//creating new tags with text view
extension TaggingViewController: UITextViewDelegate {
  func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
    tagVCIntents.textChanged.onNext(text)
    return false 
  }
  
  func optTextViewDidChange(_ textView: UITextView?){
    guard textView != nil else { return }
    
    resizeIfNeeded()
  }
  
  fileprivate func showPlaceholderIfNeeded() {
    if (textView.text.characters.count) > 0 {
      placeholderLabel.isHidden = true
    } else {
      placeholderLabel.isHidden = false
    }
  }
  
  fileprivate func resizeIfNeeded() {
    textView.layoutManager.ensureLayout(for: textView.textContainer)
    
    let containerSize = textView.layoutManager.usedRect(for: textView.textContainer).size
    let height = ceil(containerSize.height + textView.textContainerInset.top + textView.textContainerInset.bottom)*1.25
    
    containerHeight.constant = height
    textView.layoutIfNeeded()
    textView.setContentOffset(CGPoint(x: 0, y: -textView.contentInset.top), animated: false)
  }
}

extension TaggingViewController: TaggingTableDelegate {
  func matchedContactSelected(_ matchedContact: ContactModel.MatchedContact) {
    let currentTextViewText = textView.text
    
    let words: [String] = currentTextViewText!.characters.split{$0 == " "}.map(String.init)
    if let partialTag = words.last {
      let fullTag = "@" + matchedContact.username
      let startIdx = fullTag.characters.index(fullTag.startIndex, offsetBy: partialTag.characters.count)
      let remainingTagText = fullTag.substring(from: startIdx)
      
      tagVCIntents.textChanged.onNext(remainingTagText + " ")
    }
  }
  
  func sizeChanged(_ contentSize: CGSize) {
    DispatchQueue.main.async {
      var frame = self.tagTableContainerView.frame
      let maxHeight = CGFloat(250)
      frame.size.height = min(contentSize.height, maxHeight)
      self.tagTableContainerView.frame = frame
    }
  }
}
