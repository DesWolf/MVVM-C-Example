//
//  SecondPageViewModel.swift
//  MVVM+C
//
//  Created by Максим Окунеев on 12/14/20.
//

import Foundation

protocol MainPageViewModelType {
    // MARK: - Input
    var view: MainPageView! { get set }
//    var fullName: String { get }
    var data: String { get }
    
    // MARK: - Output
}

class MainPageViewModel {
    
    // MARK: - Input
//   internal var fullName: String
    internal var data: String
    
    // MARK: - Output
    
    weak var view: MainPageView!
    private let moduleAssembly: ModuleAssemblyType
    
    init(moduleAssembly: ModuleAssemblyType,  data: String) {
        self.moduleAssembly = moduleAssembly
//        self.fullName = fullName
        self.data = data
    }
}

extension MainPageViewModel: MainPageViewModelType {}
