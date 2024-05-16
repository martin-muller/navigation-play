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
 Example integrator with stack reducers provided on the StackState's Path
 */

@Reducer
struct ContentReducerV2 {
    @Reducer
    enum Path: PathableReducer {
        case featureA(FeatureA.Path.Body = FeatureA.Path.body)
        case featureB(FeatureB.Path.Body = FeatureB.Path.body)
        
        // This sort of associates the scoping to StackReducers with the Path enum.
        // A next iteration could be to figure out how to generate this automatically (runtime or compile time with macros) so a variant of the `forEach` could just work out of the box without extra code.
        // so `forEach(\.path, action: \.path) automatically generated the code below.
        @ReducerBuilder<StackState<Path.State>, StackAction<Path.State, Path.Action>>
        static func navigationReducer() -> some Reducer<StackState<Path.State>, StackAction<Path.State, Path.Action>> {
            StackReducer(state: \.featureA, action: \.featureA) {
                FeatureA()
            }
            
            StackReducer(state: \.featureB, action: \.featureB) {
                FeatureB()
            }
        }
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
        .forEach(\.path, action: \.path, for: Path.self)
    }
}

struct ContentViewV2: View {
    @Bindable var store: StoreOf<ContentReducerV2>
    
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
            .navigationTitle("Home - Integrator v2")
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
