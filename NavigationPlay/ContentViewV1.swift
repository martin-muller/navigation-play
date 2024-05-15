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

@Reducer
struct ContentReducerV1 {
    @Reducer
    enum Path {
        case featureA(FeatureANavigator.Path.Body = FeatureANavigator.Path.body)
        case featureB(FeatureBNavigator.Path.Body = FeatureBNavigator.Path.body)
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
        
            case .path(.element(id: _, action: .featureA(.screenTwo(.delegate(.openExternal))))):
                state.path.append(.featureB(.detail(.init())))
                
            case .path:
                break
            }
            return .none
        }
        .forEach(\.path, action: \.path) {
            NavigationPathReducer(state: \.featureA, action: \.featureA) {
                FeatureANavigator()
            }
            
            NavigationPathReducer(state: \.featureB, action: \.featureB) {
                FeatureBNavigator()
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
            .navigationTitle("Home - Integrator v1")
        } destination: { store in
            switch store.case {
            case .featureA(let store):
                FeatureAView(store: store)
            case .featureB(let store):
                // CAREFUL, IF THE INDIVIDUAL SCREENS BODY HAVE MULTIPLE VIEWS NOT WRAPPED IN A STACK, THEN THIS WILL RETURN MULTIPLE VIEWS AND IT CAN MESS THIGNS UP.
                // FOR EXAMPLE THE FRAME AND OVERLAY OMDIFIERS BELOW WOULD APPLY TO 2 SEPARATE VIEWS SO YOU SEE FEATURE B TWICE
                FeatureBView(store: store)
//                    .frame(maxWidth: .infinity, maxHeight: .infinity)
//                    .overlay(alignment: .top) {
//                        Text("FEATURE B")
//                    }
          }
        }
    }
}
