//
//  User.swift
//  SimpleChat
//
//  Created by Raul on 26/04/2017.
//  Copyright © 2017 Raul. All rights reserved.
//

internal class User {
    internal let id: String
    internal let name: String
    internal let image: String
    
    init(id: String, name: String, image:String) {
        self.id = id
        self.name = name
        self.image = image
    }
}
