//
// Created by Brandon Kase on 5/6/16.
// Copyright (c) 2016 Math Camp. All rights reserved.
//

import RxSwift
import RxCocoa

extension Driver {
  func bindTo<O: ObserverType where O.E == Element>(o: O) -> Disposable {
    return self.asObservable().bindTo(o)
  }
}

// HACK: tag options with a protocol so we can constrain driver
protocol OptionalType {
  associatedtype Value
  var empty: Bool { get }
  func unwrap() -> Self.Value
}
extension Optional: OptionalType {
  typealias Value = Wrapped
  var empty: Bool {
    return self == nil
  }
  func unwrap() -> Value { return self! }
}
extension Driver where Element: OptionalType {
  func filterNotNil() -> Driver<Element.Value> {
    return self.filter{ !$0.empty }.map{ $0.unwrap() }
  }
}
