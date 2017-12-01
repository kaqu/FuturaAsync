//
//  Either.swift
//  FuturaCore
//
//  Created by Kacper Kaliński on 30/11/2017.
//  Copyright © 2017 kaqu. All rights reserved.
//

import Foundation

public enum Either <Value, Alternative> {
    case value(Value)
    case alternative(Alternative)
}
