//
//  ProfileModel.swift
//  Messenger
//
//  Created by jh on 2021/04/04.
//

import Foundation

enum ProfileViewModelType {
    case info, logout
}

struct ProfileViewModel {
    let viewModelType: ProfileViewModelType
    let title: String
    let handler: (() ->Void)?
}
