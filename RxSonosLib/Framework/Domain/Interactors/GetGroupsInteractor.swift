//
//  GetGroupsInteractor.swift
//  RxSonosLib
//
//  Created by Stefan Renne on 02/03/2018.
//  Copyright © 2018 Uberweb. All rights reserved.
//

import Foundation
import RxSwift
import RxSSDP

class GetGroupsValues: RequestValues { }

class GetGroupsInteractor: BaseInteractor<GetGroupsValues, [Group]> {
    
    private let ssdpRepository: SSDPRepository
    private let roomRepository: RoomRepository
    private let groupRepository: GroupRepository
    
    init(ssdpRepository: SSDPRepository, roomRepository: RoomRepository, groupRepository: GroupRepository) {
        self.ssdpRepository = ssdpRepository
        self.roomRepository = roomRepository
        self.groupRepository = groupRepository
        
        SSDPSettings.shared.maxBufferTime = SonosSettings.shared.searchNetworkForDevices
    }
    
    override func buildInteractorObservable(requestValues: GetGroupsValues?) -> Observable<[Group]> {

        return searchNetworkForDevices()
            .distinctUntilChanged({ $0 == $1 })
            .flatMap(mapDevicesToSonosRooms())
            .flatMap(addTimer(SonosSettings.shared.renewGroupsTimer))
            .flatMap(mapRoomsToGroups())
            .distinctUntilChanged({ $0 == $1 })
    }
    
    /* SSDP */
    fileprivate func searchNetworkForDevices() -> Observable<[SSDPResponse]> {
            
        return Observable<[SSDPResponse]>.create({ (observer) -> Disposable in
            
            if let responses: [[String: String]] = CacheManager.shared.getObject(for: CacheKey.ssdpCacheKey.rawValue) {
                observer.onNext(responses.map({ SSDPResponse(data: $0) }))
            }
            
            let ssdpDisposable = self.ssdpRepository
                .scan(broadcastAddresses: ["239.255.255.250", "255.255.255.255"], searchTarget: "urn:schemas-upnp-org:device:ZonePlayer:1")
                .do(onNext: { (responses) in
                    CacheManager.shared.set(object: responses.map({ $0.responseDictionary }), for: CacheKey.ssdpCacheKey.rawValue)
                })
                .subscribe(observer)
            
            return Disposables.create([ssdpDisposable])
        })
        .subscribeOn(MainScheduler.instance)
    }
    
    /* Rooms */
    fileprivate func mapDevicesToSonosRooms() -> (([SSDPResponse]) throws -> Observable<[Room]>) {
        return { ssdpDevices in
            let collection = ssdpDevices.compactMap(self.mapSSDPToSonosRoom())
            return Observable.zip(collection)
        }
    }
    
    fileprivate func mapSSDPToSonosRoom() -> ((SSDPResponse) -> Observable<Room>?) {
        return { response in
            guard let device = SSDPDevice.map(response) else { return nil }
            return self.roomRepository.getRoom(device: device)
        }
    }
    
    /* Groups */
    fileprivate func mapRoomsToGroups() -> (([Room]) throws -> Observable<[Group]>) {
        return { rooms in
            return self.groupRepository.getGroups(for: rooms)
        }
    }
}
