//
//  SpecFunctions.swift
//  OutletActionAssertion
//
//  Created by Ben Chatelain on 6/6/15.
//  Copyright (c) 2015-2016 Ben Chatelain.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

import Quick
import Nimble
import UIKit

// MARK: - Outlets
/// Full signature of the `outlet` curried function.
private typealias FullOutletTest = (UIViewController) -> (String) -> AnyObject?

/// Asserts that the named outlet is bound, but does not care about the type of object.
typealias AnyOutletAssertion = String -> AnyObject?

/// Asserts that the named outlet is bound to a `UIButton`.
typealias ButtonOutletAssertion = String -> UIButton?

/// Asserts that the named outlet is bound to a `UIBarButtonItem`.
typealias BarButtonItemOutletAssertion = String -> UIBarButtonItem?

/// Asserts that the named outlet is bound to a `UISegmentedControl`.
typealias SegmentedControlOutletAssertion = String -> UISegmentedControl?

/// Asserts that the named outlet is bound to a `UILabel`.
typealias LabelOutletAssertion = String -> UILabel?

/// Asserts that the named outlet is bound to a `UIImageView`.
typealias ImageOutletAssertion = String -> UIImageView?

/// Asserts that `viewController` has an outlet with matching name. The Nimble
/// `fail` function is called if outlet is not found.
///
/// - parameter viewController: `UIViewController` to inspect.
///
/// - returns: Function which validates `outlet`.
///
///            - parameter outlet: Name of outlet to look up.
///
///            - returns: Object bound to `outlet` if found; nil otherwise.
private func outlet(viewController: UIViewController) -> (String) -> AnyObject? {
    return { (outlet: String) -> AnyObject? in
        guard let object = viewController.valueForKey(outlet)
            else { fail("\(outlet) outlet was nil"); return nil }

        return object
    }
}

/// Asserts that `viewController` has an outlet with matching name. The Nimble
/// `fail` function is called if outlet is not found.
///
/// - parameter viewController: `UIViewController` to inspect.
///
/// - returns: Function which validates `outlet`.
///
///            - parameter outlet: Name of outlet to look up.
///
///            - returns: Object bound to `outlet` if found; nil otherwise.
func outlet<T>(viewController: UIViewController) -> (String) -> T? {
    return { (expectedOutlet: String) -> T? in
        guard let object = outlet(viewController)(expectedOutlet)
            else { return nil }

        debugPrint(object.dynamicType)

        guard let objectOfType = object as? T
            else { fail("\(object) outlet was not a \(T.self)"); return nil }

        return objectOfType
    }
}

// MARK: - Actions
/// Full signature of the `action` curried function.
typealias FullActionAssertion = (UIViewController) -> (String, from: String) -> Void

/// Asserts that the  `from` outlet.
typealias ActionAssertion = (String, from: String) -> Void

/// Asserts that `viewController` contains an action invoked from a known outlet.
/// The Nimble `expect` function is used for validation and `fail` is called if
/// action type is not supported.
///
/// - parameter viewController: `UIViewController` to inspect.
///
/// - returns: Function which validates `expectedAction`.
///
///            - parameter expectedAction: Name of action to look up.
///
///            - parameter expectedOutlet: Name of outlet to look up.
///
///            - returns: Object bound to `outlet` if found; nil otherwise.
func action(viewController: UIViewController) -> (String, from: String) -> Void {
    return { (expectedAction: String, expectedOutlet: String) in
        let optionalControl = outlet(viewController)(expectedOutlet)

        var target: AnyObject?
        var action: String?

        if let control = optionalControl {
            switch control {
            case let button as UIBarButtonItem:
                target = button.target
                action = button.action.description
            case let control as UIControl:
                target = control.allTargets().first!
                var allActions: [String] = []
                for event: UIControlEvents in [.TouchUpInside, .ValueChanged] {
                    allActions += control.actionsForTarget(target!, forControlEvent: event) ?? []
                }

                // Filter down to the expected action
                action = allActions.filter({$0 == expectedAction}).first
            default:
                fail("Unhandled control type: \(control.dynamicType)")
            }
        }

        expect(target) === viewController
        expect(action).toNot(beNil())
        if let action = action {
            expect(action) == expectedAction
        }
    }
}