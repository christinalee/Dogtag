//
// Created by Brandon Kase on 5/6/16.
// Copyright (c) 2016 Math Camp. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import NSObject_Rx

protocol ViewModelBinder: AnyObject {
  associatedtype VM
  
  /// implement this (don't call this)
  func bindViews(_ vm: VM) -> (Arity, [Disposable])
  /// call this: you get this for free
  func bind(_ vm: VM)
}
extension ViewModelBinder {
  func bind(_ vm: VM) {
    let (arity, disposables) = bindViews(vm)
    assert(arity == disposables.count)
    disposables.forEach{ ($0 as Disposable).addDisposableTo((self as! NSObject).rx_disposeBag) }
  }
}
