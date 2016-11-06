//
//  ViewController.swift
//  MVVM
//
//  Created by Christina on 6/6/16.
//  Copyright © 2016 Christina. All rights reserved.
//

import UIKit
import NSObject_Rx

class ViewController: UIViewController {
  weak var taggingViewController: TaggingViewController?
  weak var taggingSnapshot: UIView?
  
  @IBAction func longPress(_ sender: UILongPressGestureRecognizer) {
    if case .began = sender.state {
      createTagAtPoint(sender.location(in: self.view))
    }
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    // add the child
    let storyboard = UIStoryboard(name: "Main", bundle: nil)
    if let vc = storyboard.instantiateViewController(withIdentifier: "TaggingViewController") as? TaggingViewController {
      taggingViewController = vc
      
        vc.tagCreationEventSubject.subscribe(onNext: { (event) in
        switch(event){
        case .started:
          self.tagCreationStarted()
        case .ended:
          self.tagCreationEnded()
        }
      }).addDisposableTo(rx_disposeBag)
      
      vc.view.translatesAutoresizingMaskIntoConstraints = true
      vc.view.frame = view.bounds
      addChildViewController(vc)
      view.addSubview(vc.view)
      vc.didMove(toParentViewController: self)
    }
  }
  
  deinit {
    taggingViewController?.willMove(toParentViewController: nil)
    taggingViewController?.view.removeFromSuperview()
    taggingViewController?.removeFromParentViewController()
    taggingViewController = nil
  }
  
  @IBAction func tagButtonTapped(_ button: UIButton) {
    toggleTagCreation()
  }
}

extension ViewController {
  fileprivate func toggleTagCreation() {
    taggingViewController?.tagVCIntents.toggleTagMode.onNext(.default)
  }
  
  func createTagAtPoint(_ longPressLocation: CGPoint) {
    taggingViewController?.tagVCIntents.toggleTagMode.onNext(TagViewLocation.customLocation(point: longPressLocation))
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
