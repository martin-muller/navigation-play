# NavigationPlay


Is a sample project to showcase navigation logic being in a separate package while using TCA's stack navigation pattern.

Consisting of:


1. NavigationPlay aka the integrator
    - target that integrates multiple features from separate packages
    - usually the production app, but can be a preview app as well
    - facilitates the feature to feature communication by intercepting delegate actions
2. FeatureA and FeatureB local packages
    - independent features
    - handle their own navigation internally
    - FeatureA.swift and FeatureB.swift provide the path and stack reducer implementation
3. TCAExtensions
    - Contains StackReducer a reducer that can operate on a case of StackState's Path
