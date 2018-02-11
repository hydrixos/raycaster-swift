//
//  Player.swift
//  RaycasterDemo
//
//  Created by Friedrich Gräter on 10.11.16.
//  Copyright © 2018 Friedrich Ruynat. All rights reserved.
//

import Foundation

/// Represents a player inside the map.
struct Player {
	/// The player's position inside the map.
	var position: Point
	
	/// The player's viewing angle (relative to the x-axis).
	var direction : Double
}
