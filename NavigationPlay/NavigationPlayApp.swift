//
//  NavigationPlayApp.swift
//  NavigationPlay
//
//  Created by Alejandro Martinez on 10/5/24.
//

import SwiftUI
import ComposableArchitecture

@main
struct NavigationPlayApp: App {
    
    // MARK: V1
    
    let store = Store(initialState: ContentReducerV1.State(), reducer: {
        ContentReducerV1()
    })
    
    var body: some Scene {
        WindowGroup {
            ContentViewV1(store: store)
        }
    }
    
    // MARK: V2
    
//    let store = Store(initialState: ContentReducerV2.State(), reducer: {
//        ContentReducerV2()
//    })
//    
//    var body: some Scene {
//        WindowGroup {
//            ContentViewV2(store: store)
//        }
//    }
}
