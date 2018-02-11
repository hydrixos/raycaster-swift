//
//  Canvas.swift
//  RaycasterDemo
//
//  Created by Friedrich Gräter on 10.11.16.
//  Copyright © 2018 Friedrich Ruynat. All rights reserved.
//

import Foundation

/// A canvas used to draw a single scene to.
class Canvas {
	/// The height of the canvas in pixels
	let height: UInt

	/// The width of the canvas in pixels
	let width: UInt
	
	/// The color depth per pixel used by the canvas (currently set to RGBA)
	let bytesPerPixel: UInt = 4
	
	/// The memory buffer storing the canvas's contents.
	private let pixels: UnsafeMutablePointer<CUnsignedChar>
	
	/// The number of bytes required per row.
	private let bytesPerRow : UInt
	
	/// The number of bytes in total.
	private let byteCount : UInt
	
	/// Initializes a new canvas of a given height and width.
	init(width: UInt, height: UInt) {
		self.height = height
		self.width = width
		
		self.bytesPerRow = width * bytesPerPixel
		self.byteCount = height * bytesPerRow
		
		pixels = UnsafeMutablePointer<CUnsignedChar>.allocate(capacity: Int(self.byteCount))
	}
	
	/// Deallocates any resources used by the canvas.
	deinit {
		pixels.deallocate(capacity: Int(self.byteCount))
	}
	
	/// Sets a pixel at a given coordinate to a given color.
	func setPixel(x: UInt, y: UInt, color: Color) {
		pixels[Int(y * bytesPerRow + x * bytesPerPixel)] = color.blue
		pixels[Int(y * bytesPerRow + x * bytesPerPixel) + 1] = color.green
		pixels[Int(y * bytesPerRow + x * bytesPerPixel) + 2] = color.red
		pixels[Int(y * bytesPerRow + x * bytesPerPixel) + 3] = 0xff
	}
	
	/// Returns a CGImage representation of the canvas.
	var image : CGImage? {
		let bitmapInfo = CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue
		let offscreenContext = CGContext(data: pixels, width: Int(width), height: Int(height), bitsPerComponent: 8, bytesPerRow: Int(bytesPerRow), space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: bitmapInfo)
		
		return offscreenContext?.makeImage()
	}
}
