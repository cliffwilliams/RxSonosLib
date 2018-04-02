//
//  TransportState.swift
//  RxSonosLib
//
//  Created by Stefan Renne on 27/03/2018.
//  Copyright © 2018 Uberweb. All rights reserved.
//

import Foundation


public enum TransportState: String {
    case transitioning = "TRANSITIONING"
    case playing = "PLAYING"
    case paused = "PAUSED_PLAYBACK"
    case stopped = "STOPPED"
}

extension TransportState {
    
    static func map(string: String?) -> TransportState {
        guard let string = string,
            let state = TransportState(rawValue: string) else {
            return .stopped
        }
        return state
    }
}
