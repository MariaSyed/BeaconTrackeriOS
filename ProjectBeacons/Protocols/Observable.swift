//
//  Observable.swift
//  ProjectBeacons
//
//  Created by Maria Syed on 10/02/2018.
//  Copyright © 2018 Maria Syed. All rights reserved.
//

protocol Observable {
    func registerObserver(observer: Observer)
    func deregisterObserver(observer: Observer)
    func notifyObservers()
}
