//
//  ViewController.swift
//  MVVM
//
//  Created by Christina on 6/6/16.
//  Copyright © 2016 Christina. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
  weak var taggingViewController: TaggingViewController?
  weak var taggingSnapshot: UIView?
  
  @IBAction func longPress(sender: UILongPressGestureRecognizer) {
    if case .Began = sender.state {
      createTagAtPoint(sender.locationInView(self.view))
    }
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    // add the child
    let storyboard = UIStoryboard(name: "Main", bundle: nil)
    if let vc = storyboard.instantiateViewControllerWithIdentifier("TaggingViewController") as? TaggingViewController {
      taggingViewController = vc
      
      vc.tagCreationEventSubject.subscribeNext({ (event) in
        switch(event){
        case .Started:
          self.tagCreationStarted()
        case .Ended:
          self.tagCreationEnded()
        }
      }).addDisposableTo(rx_disposeBag)
      
      vc.view.translatesAutoresizingMaskIntoConstraints = true
      vc.view.frame = view.bounds
      addChildViewController(vc)
      view.addSubview(vc.view)
      vc.didMoveToParentViewController(self)
    }
  }
  
  deinit {
    taggingViewController?.willMoveToParentViewController(nil)
    taggingViewController?.view.removeFromSuperview()
    taggingViewController?.removeFromParentViewController()
    taggingViewController = nil
  }
  
  @IBAction func tagButtonTapped(button: UIButton) {
    toggleTagCreation()
  }
}

extension ViewController {
  private func toggleTagCreation() {
    taggingViewController?.tagVCIntents.toggleTagMode.onNext(.Default)
  }
  
  func createTagAtPoint(longPressLocation: CGPoint) {
    taggingViewController?.tagVCIntents.toggleTagMode.onNext(TagViewLocation.CustomLocation(point: longPressLocation))
  }
}

extension ViewController {
  func tagCreationStarted() {
    //do anything necessary in parent here
    print("tag creation started")
  }
  
  func tagCreationEnded() {
    //do anything necessary in the parent here
    print("tag creation ended")
  }
}