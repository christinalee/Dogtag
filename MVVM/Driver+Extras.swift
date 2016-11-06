//
// Created by Brandon Kase on 5/6/16.
// Copyright (c) 2016 Math Camp. All rights reserved.
//

import RxSwift
import RxCocoa

protocol BindTo {
    func bindTo<O: ObserverType>(_ o: O) -> Disposable //where O.E == Element
}

extension SharedSequenceConvertibleType where SharingStrategy == DriverSharingStrategy, E: Any {
  func bindTo<O: ObserverType>(_ o: O) -> Disposable where O.E == E {
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

extension SharedSequenceConvertibleType where SharingStrategy == DriverSharingStrategy, E: OptionalType {
    func filterNotNil() -> Driver<E.Value> {
        return self.filter{ !$0.empty }.map{ $0.unwrap() }
    }
}
