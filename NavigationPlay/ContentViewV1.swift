//
//  ContentView.swift
//  NavigationPlay
//
//  Created by Alejandro Martinez on 10/5/24.
//

import SwiftUI
import ComposableArchitecture
import FeatureA
import FeatureB
import TCAExtensions

/*
 Example integrator with stack reducers provided in a `forEach` closure
 */

@Reducer
struct ContentReducerV1 {
    @Reducer
    enum Path {
        case featureA(FeatureA.Path.Body = FeatureA.Path.body)
        case featureB(FeatureB.Path.Body = FeatureB.Path.body)
    }
    
    @ObservableState
    struct State {
        var path = StackState<Path.State>()
    }
    
    enum Action {
        case path(StackActionOf<Path>)
        
        case openFeatureA
        case openFeatureB
    }
    
    var body: some ReducerOf<Self> {
        
        
        Reduce { state, action in
            switch action {
            case .openFeatureA:
                state.path.append(.featureA(.screenOne(.init())))
                
            case .openFeatureB:
                state.path.append(.featureB(.detail(.init())))
                
            case .path:
                return .none
            }
            return .none
        }
        .forEach(\.path, action: \.path) {
            StackReducer(state: \.featureA, action: \.featureA) {
                FeatureA()
            }
            
            StackReducer(state: \.featureB, action: \.featureB) {
                FeatureB()
            }
        }
    }
}

struct ContentViewV1: View {
    @Bindable var store: StoreOf<ContentReducerV1>
    
    var body: some View {
        NavigationStack(
            path: $store.scope(state: \.path, action: \.path)
        ) {
            VStack {
                Text("Big Home")
                
                Button("Open Feature A") {
                    store.send(.openFeatureA)
                }
                
                Button("Open Feature B") {
                    store.send(.openFeatureB)
                }
            }
        } destination: { store in
            switch store.case {
            case .featureA(let store):
                FeatureAView(store: store)
            case .featureB(let store):
                FeatureBView(store: store)
            }
        }
    }
}
