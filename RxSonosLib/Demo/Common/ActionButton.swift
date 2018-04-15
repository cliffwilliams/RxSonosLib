//
//  ActionButton.swift
//  Demo App
//
//  Created by Stefan Renne on 15/04/2018.
//  Copyright © 2018 Uberweb. All rights reserved.
//

import UIKit
import RxSwift
import RxSonosLib

@IBDesignable class ActionButton: UIButton {
    
    let data: BehaviorSubject<(TransportState, MusicService)> = BehaviorSubject(value: (.transitioning, .unknown))
    private let disposeBag = DisposeBag()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.setup()
    }
    
    private func setup() {
        data
            .asObserver()
            .subscribe(onNext: { [weak self] (state, service) in
                switch state.actionState(for: service) {
                case .playing, .transitioning:
                    self?.setImage(UIImage(named: "icon_play_large"), for: .normal)
                case .paused:
                    self?.setImage(UIImage(named: "icon_pause_large"), for: .normal)
                case .stopped:
                    self?.setImage(UIImage(named: "icon_stop_large"), for: .normal)
                }
        }).disposed(by: disposeBag)
        
        self
            .rx
            .controlEvent(UIControlEvents.touchUpInside)
            .map({ [weak self] _ in
                guard let data = try self?.data.value() else { return (TransportState.transitioning, MusicService.unknown) }
                let state = data.0
                let service = data.1
                let newState = state.actionState(for: service)
                return (newState, service)
            })
            .subscribe(data)
            .disposed(by: disposeBag)
    }
    
}