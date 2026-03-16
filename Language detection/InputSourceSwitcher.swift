//
//  InputSourceSwitcher.swift
//  Language detection
//
//  Created by yosef kiali on 23/01/2026.
//

import Foundation
import Carbon

enum InputSourceSwitcher {
    static func select(inputSourceID: String) {
        guard let src = inputSource(for: inputSourceID) else { return }
        TISSelectInputSource(src)
    }

    private static func inputSource(for id: String) -> TISInputSource? {
        let props = [kTISPropertyInputSourceID as String: id] as NSDictionary
        let list = TISCreateInputSourceList(props, false).takeRetainedValue() as NSArray
        return (list.firstObject as! TISInputSource?)
    }
}
