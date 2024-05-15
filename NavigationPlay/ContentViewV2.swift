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
struct ContentReducerV2 {
    @Reducer
    enum Path: PathableReducer {
        case featureA(FeatureANavigator.Path.Body = FeatureANavigator.Path.body)
        case featureB(FeatureBNavigator.Path.Body = FeatureBNavigator.Path.body)
        
        // now we just need a way to create this automatically. at runtime i don't think we have enough information.
        // the reduce builder seems to accept for loops, so if we could get a list of all cases in the Path anum...
        // but i don't see how because the cases generated by the caespathable are not iterable?
        // maybe we could make a macro, at compile time the cases are accessible for sure.
        // and even if we could do that... we don't know how to get the navigator reducer, so we would need to add that info somehow?
        //    or as another associated value (and this would probably break the @reducer macro, or somehow as a protocol to the feature Path reducer)
        @ReducerBuilder<StackState<Path.State>, StackAction<Path.State, Path.Action>>
        static func navigationReducer() -> some Reducer<StackState<Path.State>, StackAction<Path.State, Path.Action>> {
            NavigationPathReducer(state: \.featureA, action: \.featureA) {
                FeatureANavigator()
            }
            NavigationPathReducer(state: \.featureB, action: \.featureB) {
                FeatureBNavigator()
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