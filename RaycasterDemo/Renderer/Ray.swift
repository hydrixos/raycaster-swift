//
//  Ray.swift
//  RaycasterDemo
//
//  Created by Friedrich Ruynat on 11.02.18.
//  Copyright © 2018 Friedrich Ruynat. All rights reserved.
//

import Foundation

/// Describes a Ray that move through a map
struct Ray {
	/// The starting point of the ray
	let start: Point
	
	/// The ending point of the ray
	let end: Point
	
	/// The angle of the ray
	let angle: Angle
	
	/// The length of the ray
	let length: Double
	
	/// Initializes a ray with a starting point, an angle and a length of 0.
	init(start: Point, angle: Angle) {
		self.init(start: start, end: start, angle: angle)
	}
	
	/// Initializes a ray with a start position, an end position and an angle.
	private init (start: Point, end: Point, angle: Angle) {
		self.start = start
		self.end = end
		self.angle = angle
		
		let deltaX = self.end.x - self.start.x
		let deltaY = self.end.y - self.start.y
		self.length = sqrt(deltaX * deltaX + deltaY * deltaY)
	}

	/// Creates a new ray where the end point progressed one step to the next grid line that is parallel either to the X axis or Y axis.
	func grow() -> Ray {
		// Simulate the ray is hitting the next grid line that is parallel either to the X or to the Y axis
		let rayOnNextXLine = growToNextXLine()
		let rayOnNextYLine = growToNextYLine()
		
		// Choose the candidate with the shorter distance to the current point.
		if (rayOnNextXLine.length < rayOnNextYLine.length) {
			return rayOnNextXLine
		}
		else {
			return rayOnNextYLine
		}
	}

	/// Creates a new ray where the end point progressed to the next grid line that is parallel to the X axis.
	private func growToNextXLine() -> Ray {
		let deltaX = distanceToNextGridLine(axis: .x)
		let deltaY = tan(angle) * deltaX
		return grow(deltaX: deltaX, deltaY: deltaY)
	}

	/// Creates a new ray where the end point progressed to the next grid line that is parallel to the Y axis.
	private func growToNextYLine() -> Ray {
		let deltaY = distanceToNextGridLine(axis: .y)
		let deltaX = deltaY / tan(angle)
		return grow(deltaX: deltaX, deltaY: deltaY)
	}
	
	/// Moves the end point of the ray by the given delta.
	private func grow(deltaX: Double, deltaY: Double) -> Ray {
		return Ray(start: start, end: Point(x: end.x + deltaX, y: end.y + deltaY), angle: angle)
	}
	
	/// Determines the shorted distance between the ray's endpoint and the next grid line that is parallel to the given axis and in the ray's direction.
	///
	/// - Parameters:
	///		- axis:		The axis the matching grid line should be parallel to
	private func distanceToNextGridLine(axis: Axis) -> Double {
		let position = end.component(axis)
		
		switch Direction(forAngle: angle, axis: axis) {
			// We move in the positive direction: We round down to the previous full grid line and move one grid forwards.
			case .increasing:
				return floor(position) + 1.0 - position
			
			// We move in the negative direction: We round to the next full grid line and then move one grid backwards.
			case .decreasing:
				return ceil(position) - 1.0 - position
		}
	}
}
