//
//  SecondPageAssembly.swift
//  MVVM+C
//
//  Created by Максим Окунеев on 12/9/20.
//

import Swinject

private let storyboardName = "MainPage"

struct MainPageAssembly: Assembly {
    func assemble(container: Container) {
        container.register(MainPageView.self) { r in
            let controller = UIStoryboard(name: storyboardName, bundle: nil).instantiateInitialViewController()
            guard let view = controller as? MainPageView else {
                fatalError("First View Controller does not conform to Second view protocol")
            }
            guard let viewModel = r.resolve(MainPageViewModel.self) else {
                fatalError("Can't resolve SecondPageViewModel in Second View Controller")
            }
            
            view.viewModel = viewModel
            
            return view
        }
        
//        container.storyboardInitCompleted(SecondPageViewController.self) { (r, c) in
//            guard var viewModel = r.resolve(SecondPageViewModelType.self) else {
//                fatalError("Can't resolve FirstPageViewModel in First View Controller")
//            }
//
//            viewModel.view = c
//            c.viewModel = viewModel
//        }
            
        container.register(MainPageViewModel.self) { r in
            guard let moduleAssembly = r.resolve(ModuleAssemblyType.self) else {
                fatalError("Can't resolve moduleAssemby in Second View Controller")
            }
            guard let secondPageData = r.resolve(MainPageData.self) else {
                fatalError("Can't resolve FirstPageData in Second View Controller")
            }
    
            return MainPageViewModel(moduleAssembly: moduleAssembly, data: secondPageData.data)
        }
    }
}
