//
//  MainWindow.swift
//  RaycasterDemo
//
//  Created by Friedrich Gräter on 17.11.16.
//  Copyright © 2018 Friedrich Ruynat. All rights reserved.
//
import Cocoa

/// The main window displaying the maze.
class MainWindow: NSWindowController, NSWindowDelegate {
	private var renderer: Renderer?
	
	// MARK: - Lifecycle
	convenience init() {
		self.init(windowNibName: "MainWindow")

		// Define the map. Use characters R, O, Y, B, G to set colors.
		let map = try! Map(mapString: String.init(contentsOf: Bundle.main.url(forResource: "Map", withExtension: "txt")!))
		
		// Create a new player instance and place it somewhere in the grid
		let player = Player(position: Point(x: 4.5, y: 5.5), direction: 0)
		
		// Initialize the virtual world
		let game = Game(map: map, player: player)
		
		// Initialize the renderer with a map, a player and some camera parameters
		renderer = Renderer(game: game, relativeScreenSize: 1.0, focalLength: 0.75, illuminationRadius: 100, minimumLight: 0.25)
	}
	
	override func windowDidLoad() {
		// Perform the regular window setup
		super.windowDidLoad()
		window?.makeKeyAndOrderFront(nil)

		// Draw the first scene initially
		refreshScreen()
		
		// Regularly wait for keyboard input to control the player and re-draw the scene if needed
		pollEvents()
	}
	
	func windowDidResize(_ notification: Notification) {
		refreshScreen()
	}

	
	// MARK: - Drawing
	func refreshScreen() {
		guard let renderer = self.renderer, let window = self.window, let layer = window.contentView?.layer else {
			return;
		}
		
		// Create a canvas for drawing the scene. The canvas must match the size of our window.
		let canvas = Canvas(width: UInt(layer.frame.size.width), height: UInt(layer.frame.size.height))
		
		// Render the scene from the current player into this canvas.
		renderer.render(toCanvas: canvas)
		
		// Draw the buffer on our window.
		layer.contents = canvas.image
	}
	
	// MARK: - Keyboard control
	private var rotateLeft = false
	private var rotateRight = false
	private var moveForwards = false
	private var moveBackwards = false

	override func keyDown(with event: NSEvent) {
		handleKeyEvent(event, didPressKey: true)
	}
	
	override func keyUp(with event: NSEvent) {
		handleKeyEvent(event, didPressKey: false)
	}

	///	Handles a key event
	///
	/// - Parameters:
	///		- event				The key event to be handled
	///		- didPressKey		Whether or not a key press or a key release should be handled.
	private func handleKeyEvent(_ event: NSEvent, didPressKey: Bool) {
		guard let chars = event.charactersIgnoringModifiers?.utf16 else {
			return
		}
		
		let keyCode = Int(chars[chars.startIndex])

		if (keyCode == NSRightArrowFunctionKey) {
			rotateRight = didPressKey
		}
		else if (keyCode == NSLeftArrowFunctionKey) {
			rotateLeft = didPressKey
		}
		else if (keyCode == NSUpArrowFunctionKey) {
			moveForwards = didPressKey
		}
		else if (keyCode == NSDownArrowFunctionKey) {
			moveBackwards = didPressKey
		}
	}
	
	/// Tests whether a key is currently pressed and performs the requested user action. Refreshes the screen afterwards.
	private func processEvents() {
		guard let renderer = self.renderer else {
			return
		}
		
		let movementSpeed	= 0.2
		let rotationSpeed	= 0.05
		
		//
		// Depending on the pressed keys, perform rotations or movements
		//
		if (rotateRight) {
			renderer.game.rotatePlayer(rotationSpeed)
		}
		
		if (rotateLeft) {
			renderer.game.rotatePlayer(-rotationSpeed)
		}
		
		if (moveForwards) {
			renderer.game.movePlayer(movementSpeed)
		}
		
		if (moveBackwards) {
			renderer.game.movePlayer(-movementSpeed)
		}
		
		// Refresh screen after we performed all moves and rotations
		if (rotateLeft || rotateRight || moveForwards || moveBackwards) {
			refreshScreen()
		}
	}
	
	/// Polls and handles key events in an endless loop.
	private func pollEvents() {
		// Wait some time and check whether keys are pressed
		DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + (1.0/60.0)) {
			self.processEvents()
			self.pollEvents()
		}
	}
}
