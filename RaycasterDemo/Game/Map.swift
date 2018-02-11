//
//  Map.swift
//  RaycasterDemo
//
//  Created by Friedrich Gräter on 10.11.16.
//  Copyright © 2018 Friedrich Ruynat. All rights reserved.
//

import Foundation

/// Represents the map of the 3D maze.
struct Map {
	/// The tiles of the map
	private let tiles : [[Tile]]

	/// The longest distance between two points within the map
	let maxDistance : Double
	
	/// Creates a new map from the given string.
	///
	/// - Parameters:
    ///    - Lines:	An array of strings, whereas each string represents one line in the map.
	///				Use the characters R,G,B,Y,O to designate a wall with a certain color. Use spaces to designate empty tiles. Do not use tabs.
	init(mapString: String) {
		tiles = mapString.components(separatedBy: "\n").map {line in
			line.map {char in
				switch char {
					case " ":	return Tile.empty
					case "R":	return Tile.wall(color: Color.red)
					case "G":	return Tile.wall(color: Color.green)
					case "B":	return Tile.wall(color: Color.blue)
					case "Y":	return Tile.wall(color: Color.yellow)
					case "O":	return Tile.wall(color: Color.orange)
					default:	return Tile.wall(color: Color.red)
				}
			}
		}

		// Since our map is rectangular the longest possible distance can be never longer than the sum of the height or width (https://en.wikipedia.org/wiki/Triangle_inequality).
		let width = tiles.reduce(0, {maxCount, line in max(maxCount, line.count)})
		let height = tiles.count
		maxDistance = Double(width + height)
	}

	/// Returns the contents of an tile inside the map.
	///
	/// - Parameters:
	/// 	- point:	The position of the tile. If the position is outside the map, an empty field is returned.
	public func tile(forPosition position: Tile.Position) -> Tile {
		if ((position.y >= tiles.count) || (position.y < 0) || (position.x >= tiles[position.y].count) || (position.x < 0)) {
			return Tile.empty;
		}
		
		return tiles[position.y][position.x]
	}
	
	/// Returns the light intensity of a wall at a certain point depending on the viewing angle.
	///
	/// - Parameters:
	///		- point:		The point of the wall from which the light intensity is queried.
	///		- direction:	The direction the wall is viewn from
	static public func lightIntensityForWall(atPoint point: Point, inDirection direction: Angle) -> Double {
		// Determine on which side of the wall the point resides.
		let closestAxis = point.closestGridLineAxis
		let viewingDirection = Direction(forAngle: direction, axis: closestAxis)
		
		switch(closestAxis) {
			// The ray hit a wall that is parallel to the x-axis
			case .x:
				switch(viewingDirection) {
					case .increasing: return 1.0
					case .decreasing: return 0.6
				}
			
			// The ray hit a wall that is parallel to the y-axis
			case .y:
				switch(viewingDirection) {
					case .increasing: return 0.4
					case .decreasing: return 0.8
				}
		}
	}
}

extension Map {
	/// Describes an tile on the map
	enum Tile : Equatable {
		/// The tile is empty.
		case empty
		
		/// The tile contains a wall with a certain color.
		case wall(color: Color)

		/// Compares two tiles inside the map. Two tiles are equal, iff. they are either both empty or both contain a wall with the same color.
		static func ==(lhs: Tile, rhs: Tile) -> Bool {
			switch (lhs, rhs) {
				case (.empty, .empty):
					return true
				case (let .wall(colorA), let .wall(colorB)):
					return colorA == colorB
				default:
					return false;
			}
		}
		
		/// The position of a tile within the map
		struct Position {
			let x: Int
			let y: Int
			
			/// Rounds a point to a tile position. Makes sure that ambiguous points - i.e. points between two tiles - are properly rounded using the given angle.
			///
			/// - Parameters:
			///		- point:		The point that should be converted to a tile position.
			///		- angle:		An angle used to resolve ambiguous points.
			init(point: Point, angle: Angle) {
				x = Position.component(fromPoint: point, axis: .x, angle: angle)
				y = Position.component(fromPoint: point, axis: .y, angle: angle)
			}
			
			/// Rounds a single coordinate of a point to a single coordinate of a tile position. Makes sure that ambiguous coordinates - i.e. points between two
			/// tiles - are properly rounded using the given angle.
			///
			/// - Parameters:
			///		- point:		The point from which a component should be converted to a tile position component.
			///		- axis:			The axis the point's component should be taken from
			///		- angle:		An angle used to resolve ambiguous points.
			private static func component(fromPoint point: Point, axis: Axis, angle: Angle) -> Int {
				var pointComponent = point.component(axis)
				
				// Special rounding is applied if the point is on a grid line
				if (pointComponent.truncatingRemainder(dividingBy: 1) == 0) {
					switch Direction(forAngle: angle, axis: axis) {
						// If the point is between two tiles and the angle is pointing backwards, use the tile specified by the point.
						case .increasing:
							break
						// If the point is between two tiles and the angle is pointing backwards, use the previous tile.
						case .decreasing:
							pointComponent -= 1.0
					}
				}
				
				return Int(pointComponent)
			}
		}
	}
}
