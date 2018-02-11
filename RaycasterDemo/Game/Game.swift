//
//  Game.swift
//  RaycasterDemo
//
//  Created by Friedrich Ruynat on 17.03.18.
//  Copyright © 2018 Friedrich Ruynat. All rights reserved.
//

import Foundation

/// Represents the state of our game's virtual world
struct Game {
	/// The map of our virtual world
	var map: Map
	
	/// The player of our virtual world
	var player: Player
	
	/// Rotates the player's viewing angle with the given angle.
	///
	///  - Parameters:
	///		- angle:		The angle the player should rotated with (0…2π).
	public mutating func rotatePlayer(_ angle: Double) {
		player.direction += angle
	}
	
	/// Moves the player by the given distance in its current viewing direction. The player is not moved if it would collide with a wall.
	///
	/// - Parameters:
	///		- distance:		The distance the player should be moved by.
	public mutating func movePlayer(_ distance: Double) {
		// The actual distance is the hypothenuse of a right-angled triangle. The legs are the differences in the x and y direction. Using the ray's angle we can determine the length of the legs.
		// See: https://en.wikipedia.org/wiki/Trigonometry#Overview
		let newPoint = player.position.add(x: distance * cos(player.direction), y: distance * sin(player.direction))
		
		switch map.tile(forPosition: Map.Tile.Position(point: newPoint, angle: player.direction)) {
			case .wall:
				return;
			
			case .empty:
				player.position = newPoint
				return;
		}
	}

}
