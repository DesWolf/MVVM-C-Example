//
//  FirstPageAssembly.swift
//  MVVM+C
//
//  Created by Максим Окунеев on 12/18/20.
//

import Swinject

private let storyboardName = "LoginPage"

struct LoginAssembly: Assembly {
    func assemble(container: Container) {
        container.register(LoginView.self) { r in
            let controller = UIStoryboard(name: storyboardName, bundle: nil).instantiateInitialViewController()
            guard let view = controller as? LoginView else {
                fatalError("Login View Controller does not conform to Login view protocol")
            }
            guard let viewModel = r.resolve(LoginViewModelType.self) else {
                fatalError("Can't resolve LoginPageViewModel in Login View Controller")
            }
            guard let moduleAssembly = r.resolve(ModuleAssemblyType.self) else {
                fatalError("Can't resolve moduleAssemby in Login View Controller")
            }
            
            view.viewModel = viewModel
            view.moduleAssembly = moduleAssembly
            
            return view
        }

        container.register(LoginViewModelType.self) { r in
            guard let moduleAssembly = r.resolve(ModuleAssemblyType.self) else {
                fatalError("Can't resolve moduleAssemby in Login View Controller")
            }
            guard let data = r.resolve(LoginData.self) else {
                fatalError("Can't resolve LoginPageData in Login View Controller")
            }
            
            return LoginViewModel(moduleAssembly: moduleAssembly, name: data.name, surname: data.surname)
        }
    }
}

