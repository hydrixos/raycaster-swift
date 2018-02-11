//
//  Renderer.swift
//  RaycasterDemo
//
//  Created by Friedrich Gräter on 10.11.16.
//  Copyright © 2018 Friedrich Ruynat. All rights reserved.
//

import Foundation

/// Draws a 3D scene for a given map and a player within the map.
class Renderer {
	/// The state of the virtual world to be rendered
	var game: Game
	
	/// The size of the physical computer display in relation to a grid field
	let relativeScreenSize: Double
	
	/// The focal length used for determining the viewport angle
	let focalLength: Double
	
	/// The radius around the player where objects should appear illuminated
	let illuminationRadius: Double
	
	/// The minimum environment light of the scene
	let minimumLight: Double
	
	///  Initializes the renderer with a map, a player and a focal length that should be used for rendering.
	///
	///  - Parameters:
	///  	- game:					The virtual world state (i.e. the game's map and player position)
	///		- relativeScreenSize:	The size of the physical computer display in relation to a grid field
	///  	- focalLength:			A focal length that should be used for rendering.
	///	 	- illuminationRadius:	The radius around the player where objects should appear illuminated.
	///	 	- minimumLight:			The minimum environment light of the scene.
	///
	init(game: Game, relativeScreenSize: Double, focalLength: Double, illuminationRadius: Double, minimumLight: Double) {
		self.game = game
		self.relativeScreenSize = relativeScreenSize
		self.focalLength = focalLength
		self.illuminationRadius = illuminationRadius
		self.minimumLight = minimumLight
	}

	/// Renders one frame into a canvas.
	///
	/// - Parameters:
	///		- canvas		The canvas that should be drawn to.
	func render(toCanvas canvas: Canvas) {
		for column in 0 ..< canvas.width {
			render(column: column, toCanvas: canvas)
		}
	}
	
	/// Renders one pixel column of a frame into a canvas.
	///
	/// - Parameters:
	///		- column:		The pixel column of the canvas that should be rendered
	///		- canvas:		The canvas that should be drawn to.
	func render(column: UInt, toCanvas canvas: Canvas) {
		// Cast the ray to find a nearby wall
		let scanningResult = castRay(forColumn: column, width: canvas.width)
		
		// Draw scanning result to the canvas
		draw(hit: scanningResult, forColumn: column, toCanvas: canvas)
	}
}


// MARK: - Ray Casting
extension Renderer {
	/// Casts a ray from the player's position for a given column on the view and returns what the ray scanned at its end.
	///
	/// - Parameters:
	///		- column:			The column that should be drawn
	///		- width:			The largest column number that could be drawn
	///
	/// - Returns:				Whether and how the ray hit a wall
	fileprivate func castRay(forColumn column: UInt, width: UInt) -> Hit {
		// Determine the absolute angle of the ray
		let relativeAngle = rayAngle(forColumn: column, width: width)
		let absoluteAngle = relativeAngle + game.player.direction

		// Create the ray
		var ray = Ray(start: game.player.position, angle: absoluteAngle)
		
		// Grow the ray stepy by step. Grow it until we either hit a wall or reached the maximum distance
		while ray.length <= game.map.maxDistance {
			ray = ray.grow();
			
			switch game.map.tile(forPosition: Map.Tile.Position(point: ray.end, angle: ray.angle)) {
				case .empty:
					// We've found nothing. Just continue scanning.
					break;
				
				case .wall(let color):
					// Fix the calculated distance to correct the fisheye effect
					let projectedDistance = ray.length * cos(relativeAngle)
					
					// Apply some lighting to the wall's color
					let wallLightIntensity = Map.lightIntensityForWall(atPoint: ray.end, inDirection: ray.angle)
					let distanceLightIntensity = min(max(1.0 - ray.length/illuminationRadius, minimumLight), 1.0)
					let illuminatedColor = color.adjustLightIntensity(distanceLightIntensity * wallLightIntensity)
					
					// Pass the result
					return .wall(color: illuminatedColor, distance: projectedDistance)
			}
		}
		
		// The ray casting reached the outer bounds of our map. We never hit a wall...
		return .none
	}
	
	/// Determines the angle of a scanning ray for drawing the given column on a screen with the given width.
	/// The ray should be casted from the given player's using its position, viewing direction and the current focal length.
	///
	///	- Parameters:
	///		- column:	The current screen column to be drawn (which must be less than the screen's width).
	///		- width:	The width of the screen.
	private func rayAngle(forColumn column: UInt, width: UInt) -> Double {
		let relativeScreenPosition = (Double(column) / Double(width)) - 0.5
		let virtualScreenPosition = relativeScreenPosition * relativeScreenSize
		return atan(virtualScreenPosition / focalLength)
	}
	
	/// Describes the result of a casted ray
	enum Hit {
		/// The ray never hit a wall
		case none

		/// The ray hit a wall with a given color at a given distance.
		case wall(color: Color, distance: Double)
	}
}

// MARK: - Drawing
extension Renderer {
	/// Draws the given screen column for the result of a particular ray casting operation to a given canvas
	fileprivate func draw(hit: Hit, forColumn column: UInt, toCanvas canvas: Canvas) {
		switch hit {
			case .none:
				// We did not found a wall, just draw an empty space
				drawWall(withHeight: 0, color: Color.black, toCanvas: canvas, atColumn: column)
			
			case let .wall(color: color, distance: distance):
				// Determine the visual height of the wall on the screen (normalized to the screen's height)
				let normalizedWallHeight = 1.0 / distance
				
				// Finally: Draw the wall for the current screen position…
				drawWall(withHeight: normalizedWallHeight, color: color, toCanvas: canvas, atColumn: column)
		}
	}
	
	/// Draws a column of a wall for the given screen position.
	///
	///	 - Parameters:
	///  	- wallHeight:	The visible height of a wall segment to be drawn (0: no wall, >=1: full screen height).
	///  	- color:		The color of the wall to be drawn.
	///  	- canvas:		The canvas that should be used for drawing.
	///  	- column:		The current screen column to be drawn.
	private func drawWall(withHeight wallHeight: Double, color: Color, toCanvas canvas: Canvas, atColumn column: UInt) {
		let limitedWallHeight = min(wallHeight, 1.0)
		let screenWallHeight = UInt(limitedWallHeight * Double(canvas.height))
		
		let wallTop = (canvas.height - screenWallHeight) / 2;
		let wallBottom = wallTop + screenWallHeight

		// Draw the black ceiling
		for y in 0 ..< wallTop {
			canvas.setPixel(x: column, y: y, color: Color.black)
		}
		
		// Draw the wall (if anything is visible)
		for y in wallTop ..< wallBottom {
			canvas.setPixel(x: column, y: y, color: color)
		}
		
		// Draw the floor as grey gradient
		for y in wallBottom ..< canvas.height {
			let gradientPosition = Double(y)/Double(canvas.height)
			let gradientColor = Color.darkGrey.adjustLightIntensity(gradientPosition)
			canvas.setPixel(x: column, y: y, color: gradientColor)
		}
	}
}
