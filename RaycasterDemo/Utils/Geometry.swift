//
//  Geometry.swift
//  RaycasterDemo
//
//  Created by Friedrich Gräter on 22.12.16.
//  Copyright © 2018 Friedrich Ruynat. All rights reserved.
//

import Foundation

/// Specifies an angle relative to the X-Axis in radians
typealias Angle = Double

/// Specifies an axis in the coordinate system.
enum Axis {
	case x, y
}

/// Specifies a point within the map.
struct Point {
	let x: Double
	let y: Double
	
	/// Adds two points
	func add(x: Double, y: Double) -> Point {
		return Point(x: self.x + x, y: self.y + y)
	}
	
	/// Provides the component of a point for an axis.
	func component(_ axis: Axis) -> Double {
		switch(axis) {
			case .x: return x
			case .y: return y
		}
	}

	/// Determines the axis the closets grid line is parallel to.
	var closestGridLineAxis: Axis {
		if (abs(x - round(x)) < abs(y - round(y))) {
			return .x
		}
		else {
			return .y
		}
	}
}

/// Specifies the direction of a line on a certain axis.
public enum Direction {
	case increasing, decreasing
	
	/// Determines whether a line with a certain angle will result in decreasing or increasing values on a given axis.
	init(forAngle angle: Angle, axis: Axis) {
		// Take a look at the unit circle: https://en.wikipedia.org/wiki/Unit_circle
		switch axis {
			case .x:
				// A line's values are increasing on the x-axis if the angle is between 270° and 90° (when cos(angle) > 0).
				self = cos(angle) > 0 ? .increasing : .decreasing
			case .y:
				// A line's values are increasing on the y-axis if the angle is between 0° and 180° (when sin(angle) > 0).
				self = sin(angle) > 0 ? .increasing : .decreasing
		}
	}
}
