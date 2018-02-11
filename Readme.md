# A Ray Caster in Swift
This repository contains a very simple 3D software renderer. The aim of this project is to give you an illustrative example what you can already achieve with your high school knowledge on right triangles. It uses a technique called [Ray Casting][1] that was very common in early 3D computer games. I’ve tried to keep the code clear and well commented and also added an introduction to Ray Casting inside this Readme file.

If you’d like to play with it right now: There is also a [browser version][2] of this demo written in [Rust][3].

**Have fun!**

![][image-1]

## How to Build
You can build this demo using Xcode 9 (or later):

- Clone the repository
- Open it with Xcode on your Mac
- Hit the run button
- Walk around using the arrow keys…
- You can modify the game’s map by editing the file `Map.txt`

## How does it work?
Ray Casting is a technique that was used at a time where computing power was very limited. It uses many simplifications that keep it easy to implement and easy to understand.

The main simplification is that our virtual world is just a two-dimensional grid. Every tile inside this grid can be either empty or can contain a wall. The floor of this virtual world is also completely flat and all walls have the same height. Inside this world is our player. Contrary to the walls, the player is not tied to the grid and can be moved and rotated freely. Our virtual world can be represented by a map that could look like the following:

![][image-2]

If we put ourselves in the position of the player painted in the previous figure, we would probably expect to see something like this – a simple doorway with a distant wall behind it.

![][image-3]

How can we render such a scene from this map? Drawing a virtual scene is pretty similar to looking through a window in reality. Imagine that our computer display is a window into our virtual world. If we look through a real window our eyes would perceive light rays that were reflected from the walls inside the room. These rays passed through a certain point of the window into the eyes of the watcher. Ray Casting fakes this by turning it around: It simulates a ray starting from the player’s eyes passing through each pixel of the computer screen into the virtual world. If such a ray hits a wall, the renderer calculates the distance to the hit point. If a wall is closer to the player, it will draw the point larger. If a wall is distant, it will draw it smaller. Since all walls of our world have the same height it is completely sufficient to send out one ray for each column of pixels on our screen. The following figure illustrates this process of ray casting:

![][image-4]

By sending out one ray for each column of pixels, we will get an approximated image of the player’s environment. The number of rays directly influences the quality of the image. Even if we send out only 24 rays (which means we have a very low screen resolution with just 24 horizontal pixels), we already get an approximation of our virtual scene:

![][image-5]

Of course, a real renderer can utilize the full height and width of a modern display to get a much crispier and detailed image.

## Raycasting Step by Step
So far the conceptual part – let’s take a look at the code! Our virtual world is represented by a central struct `Game` that consists of the `map` and the `player`.

### The Map
The map is a two-dimensional array of tiles. The first dimension contains all rows and the second array dimension contains all tiles of a row:

```swift
struct Map {
	let tiles : [[Tile]]
}
```

Every `Tile` can be either empty or can contain a wall with a certain color. Thus we can define a tile using an enum:

```swift
enum Tile {
	case empty
	case wall(color: Color)
}
```

### The Player
The player has a position inside the map and an orientation relative to the x-axis. In contrast to tiles, the player can move freely inside the map:

```swift
struct Player {
	var position: Point
	var direction : Double
}
```

### The Renderer
Rendering is performed by the class `Renderer`. The renderer is called every time we need to refresh the screen – e.g. if the player moved or when the window has been resized. This is done by calling the method `Render.render(toCanvas:)`. This method draws the current scene from the player’s perspective into a given canvas. This canvas is just a simple RGB bitmap graphic that will be drawn to the screen.

Since all walls have the same height, we only need to send out rays on one horizontal plane. The rendering method therefore performs one rendering step for each column of pixels:

```swift
func render(toCanvas canvas: Canvas) {
	for column in 0 ..< canvas.width {
		render(column: column, toCanvas: canvas)
	}
}
```

At each rendering step, the method `render(column: toCanvas:)` is called. It sends out one ray to scan the environment and draws the `scanningResult` on the canvas:

```swift
func render(column: UInt, toCanvas canvas: Canvas) {
	let scanningResult = castRay(forColumn: column, width: canvas.width)
	draw(hit: scanningResult, forColumn: column, toCanvas: canvas)
}
```

The `scanningResult` can be either that the ray hit a wall or that the ray left the player’s range of vision. If it hit a wall, the wall’s color and the distance to the wall is attached to the result:

```swift
enum Hit {
	case none
	case wall(color: Color, distance: Double)
}
```

#### Starting a Ray
Every ray is represented by the struct `Ray`. It consists of an origin, an end point, an angle and a length. It can be initialized with a starting point and an angle. It can be grown step by step through the method `grow()`:

```swift
struct Ray {
	let start: Point
	let end: Point
	let angle: Angle
	let length: Double

	init(start: Point, angle: Angle) { … }
	func grow() -> Ray { … }
}
```

At each rendering step the renderer casts one ray through the map. It does this by calling the method `Renderer.castRay(forColumn:width:)`. This method determines the angle and the origin of the ray and then grows the ray until it hits a wall or leaves the range of vision. 

To start a ray, we must know its origin and direction. The ray’s origin is obviously the position of the player. The direction depends of two variables: First, on the players viewing direction which is given. Second, on the column, we currently want to draw (resulting in the ray’s `relativeAngle`):

```swift
func castRay(forColumn column: UInt, width: UInt) -> Hit {
	let relativeAngle = rayAngle(forColumn: column, width: width)
	let absoluteAngle = relativeAngle + game.player.direction
```

How can we calculate this relative angle from the currently drawn pixel column? To understand this we should draw a little figure:

![][image-6]

This figure remembers us to our analogy from the beginning: Our human player looks through the computer display into our virtual world. For every column of pixels on the screen, there is a ray starting on our human player’s eye passing the pixel on our display and continues to grow into our virtual world until it hits a wall. Thus, the angle of our ray depends on three variables:

1. The position of the pixel column that should be drawn on screen
2. The length of our screen (in relation to a length in our virtual world)
3. The distance of our human player to the screen („focal length“)

We know exactly the pixel column we want to draw. But we neither know the size of our user’s screen nor the distance between the user and the display. This is a problem bugging artists sine they started to paint perspective images and it is usually solved by making assumptions that feel right for most cases. In our case, we assume that the screen has a relative length of `1.0` (i.e. it has the length of a single wall segment or a doorway). We also assume that the player has a relative distance to the screen of `0.75`.  If you’d like, you can change these constants and see the effect! They are set in the initializer of the `Renderer`.

Using this model, we can draw another figure that gives us an idea how we can calculate our ray’s relative angle:

![][image-7]

This figure shows that our ray forms a right triangle with the player’s position, the center of our display and the point where the ray passes through the display. Now it is time to open our school books! We remember that right triangles have several nice properties: One property is that if we know the length of two sides, it is easy to get the length of another unknown side.

![][image-8]

We know the distance to our display (the focal length) and we know the position of our pixel on our computer display. So we know the length of the sides `a` and `b`. From our school books we know that `tan(α) = a/b`. We can invert the tangent by using the arctangent (often called arctan or atan) to get the actual angle: `atan(a/b) = α`. This is how we get our angle – and this is what the function `rayAngle(forColumn: width:)` does:

```swift
func rayAngle(forColumn column: UInt, width: UInt) -> Double {
	let relativePosition = (Double(column) / Double(width)) - 0.5
	let virtualScreenPosition = relativePosition * relativeScreenSize
	return atan(virtualScreenPosition / focalLength)
}
```

It first converts the horizontal pixel position of our column to a screen position in the coordinate system of our virtual world (`virtualScreenPosition`) and combines it with our `focalLength` to calculate the relative angle.

#### Growing the Ray Step by Step
Now we know the ray’s direction and origin, we can use it to scan our map to detect surrounding walls. At each growing step, we consult our map for the contents of the tile the ray is ending at. If the tile is empty, we can continue scanning. If the tile contains a wall, we stop and return a hit value providing the wall’s color and the ray’s length (`Hit.wall(color, distance)`). Alternatively, we return `Hit.none` if we leave the range of vision.

```swift
func castRay(forColumn column: UInt, width: UInt) -> Hit {
	// Start ray
	let relativeAngle = rayAngle(forColumn: column, width: width)
	let absoluteAngle = relativeAngle + game.player.direction
	let ray = Ray(start: game.player.position, angle: absoluteAngle)

	// Grow and scan
	while ray.length <= game.map.maxDistance {
		ray = ray.grow()
			
		switch game.map.tile(forPosition: ray.end) {
			case .empty:
				break
			case .wall(let color):
				return .wall(color: color, distance: ray.length)
		}
	}
	
	return .none
}
```

For each growing step the method `grow()` is called. A naive version of `grow` would just grow the ray point by point. However, this would take either a huge amount of computing power. There might be millions of points between the player and a wall, depending on the precision of our coordinate system!

Luckily, we can use a trick: We recall that our map consists of tiles. Every tile is either filled or empty and every tile is aligned to our grid. It is completely sufficient to grow our ray from grid line to grid line and skip all points in between. The figure below gives an example:

![][image-9]

The ray starts at an arbitrary position (x=0.3, y=0.2). From there it grows to the next grid line that is in the ray’s direction (x=0.5, y=1.0). The renderer examines the tile (x=0, y=1) and detects that it is empty. Therefore, it decides to continue growing to the next grid line, which is at (x=1.0, y=1.4). Again, the field at (x=1, y=1) is empty, so it continues the scan. In the final step the ray hits the grid line at the coordinates (x=1.5, y=2). It now hits a tile that contains a wall and finishes scanning: We only needed three steps to detect a wall!

How do we know to which point we need to grow our ray? First, we know that the next point must be in the ray’s direction. Second, it must be either on a x- or an y-grid line. So we can just try it out: At every step, we place our point either on the next x or on the y line and select the point that is closer to our starting point. This is exactly what our method `Ray.grow()` does:

```swift
func grow() -> Ray {
	let rayOnNextXLine = growToNextXLine()
	let rayOnNextYLine = growToNextYLine()
	
	if (rayOnNextXLine.length < rayOnNextYLine.length) {
		return rayOnNextXLine
	}
	else {
		return rayOnNextYLine
	}
}
```

Of course, this answers our question only partially. We know that the point must be on the next grid line in x- or y-direction. But how can we get the exact coordinates of this point? This is the job of `growToNextXLine` and `growToNextYLine`. In the following we will only take a look at the first, because the second function works very similar…

When we want to calculate the exact coordinates of the next end point there is only one thing we know for sure: If a point is on a grid line, one of its coordinates must be an integer number. For instance, if we start at point P (x=2.3,y=4.1) and we want to grow the ray to the next x-grid line, the x-coordinate must be either x=3.0 or x=1.0. We just need to round it! Whether we need to round upwards or downwards depends on the ray’s angle (we’ll look at the directional rounding in a moment…). 

But what about the unknown y-coordinate? Given the x-coordinate we can calculate the y-coordinate with a bit of trigonometry. To make this more obvious, we should draw another figure:

![][image-10]

Our ray starts at point P (x=2.3, y=4.2) and we want to get the next grid line in x-direction. First, we round to the next x-coordinate in the ray’s direction. In our example, the ray moves in a positive direction with respect to the x-axis. This is point P’ which has a rounded x-coordinate (3.0) and the old y-coordinate (y=4.2).  We are know interested in the point Q, which has the new x- and y-coordinate. As we can see the ray’s previous end point P, the rounded end point P’ and the missing point Q construct a right triangle. In this triangle, we know the ray’s angle `α` and the length of the side `b` (which is `b = Δx = 3.0-2.3 = 0.7`). We don’t know the side `a = Δy` to get the coordinates of `y = 4.1 + Δy`. 

It is time to recall our school knowledge again! Right triangles also have the nice property that one can calculate a missing side using a angle and another side of the triangle:

![][image-11]

Using the last formula it is easy to get the missing length of `Δy=a=tan(α) * b`.

There is still one piece missing: How do we round the x coordinate? As we’ve said the rounding only depends on the ray’s direction. For instance, if the ray moves from left to right, we have to round up to the next x coordinate. If it moves from right to left, we need to move down. This is what `distanceToNextGridLine` does. It determines the ray’s direction for a requested axis and rounds the coordinate that belongs to this axis:

```swift
func distanceToNextGridLine(axis: Axis) -> Double {
	let position = end.component(axis)
	
	switch Direction(forAngle: angle, axis: axis) {
		case .increasing:
			return floor(position) + 1.0 - position
		case .decreasing:
			return ceil(position) - 1.0 - position
	}
}
```

The function `Direction(forAngle: axis:)` tells us, whether an angle is moving upwards or downwards on a certain axis. It does this by inspecting the given angle. The following figure gives an example how we can get the direction from an angle for the movement in x-direction:

![][image-12]

If the angle is between 0° and 90°, the values on the x-coordinate of the ray are increasing. If the angle is between 90° and 270° they are decreasing. Between 270° and 360° it is increasing again. Looking at the definition of the cosine function the angle is just increasing if `cos(α) > 0`. Using this information we can determine the ray’s direction for a particular axis and round our coordinate and we have everything to grow our ray.

This is exactly what our function `growToNextXLine` does:

```swift
func growToNextXLine() -> Ray {
	let deltaX = distanceToNextGridLine(axis: .x)
	let deltaY = tan(angle) * deltaX
	return grow(deltaX: deltaX, deltaY: deltaY)
}
```

It first determines the next x value by rounding (`distanceToNextGridLine`) and then calculates the distance to the next y-coordinate using the tangent. Using these distances we update the end coordinates of our ray using `grow(deltaX: deltaY:)`. By updating the ray’s endpoint, it also re-calculates the length of the ray:

```swift
let deltaX = self.end.x - self.start.x
let deltaY = self.end.y - self.start.y
self.length = sqrt(deltaX * deltaX + deltaY * deltaY)
```

### Drawing
Where are we now? The method `castRay`  revealed that our ray either hit a wall or did not hit anything in range. How can we use this information to draw a wall or an empty area? This is done by the function `Renderer.draw(hit: forColumn: toCanvas:)`:

```swift
func draw(hit: Hit, forColumn column: UInt, toCanvas canvas: Canvas) {
	switch hit {
		case .none:
			drawWall(withHeight: 0, color: Color.black, toCanvas: canvas, atColumn: column)
	
		case let .wall(color: color, distance: distance):
			let normalizedWallHeight = 1.0 / distance;
			drawWall(withHeight: normalizedWallHeight, color: color, toCanvas: canvas, atColumn: column)
	}
}
```

This function distinguishes between the two cases: If the ray never hit a wall, it will receive `hit = .none`. In this case it draws an empty wall. If `hit=.wall(color, distance)` is passed, we draw a wall segment with the given color. The height of the wall segment is calculated from its distance. It is normalized to `1.0` to calculate it independently from the actual screen resolution.

In both cases, the helper function `drawWall(withHeight: color: toCanvas: atColumn:)` is called to perform the actual drawing. Depending on the wall’s height this function calculates the height of the wall relative to the screen size:

```swift
func drawWall(withHeight wallHeight: Double, color: Color, toCanvas canvas: Canvas, atColumn column: UInt) {
	let limitedWallHeight = min(wallHeight, 1.0)
	let screenWallHeight = UInt(limitedWallHeight * Double(canvas.height))
```

It then determines the upper and the lower end point of the wall:

```swift
	let wallTop = (canvas.height - screenWallHeight) / 2;
	let wallBottom = wallTop + screenWallHeight
```

Then it draws the ceiling…

```swift
	for y in 0 ..< wallTop {
		canvas.setPixel(x: column, y: y, color: Color.black)
	}
```

…the wall segment…

```swift
	for y in wallTop ..< wallBottom {
		canvas.setPixel(x: column, y: y, color: color)
	}
```

…and the floor. The floor is drawn with a grey gradient to give it a more realistic feeling:

```swift
	for y in wallBottom ..< canvas.height {
		let gradientPosition = Double(y)/Double(canvas.height)
		let gradientColor = Color.darkGrey.adjustLightIntensity(gradientPosition)
		canvas.setPixel(x: column, y: y, color: gradentColor
	}
```

That’s it!

### Fixing the Fisheye Effect
If we put everything together and run the demo, we will find out that there is a little bug. Our wall looks a bit twisted:

![][image-13]

This happens because we did a mistake when calculating the length of the ray. If we look at the following figure we see that rays at the border of our display take a longer way to the wall then rays in the center of the screen:

![][image-14]

For a natural perspective, we would expect that parallel points on a wall are also parallel on the screen:

![][image-15]

To make parallel walls appear parallel we need to correct our projection a bit. Again, we can use our knowledge on right triangles to fix this problem:

![][image-16]

If you look at the actual source code, you will see that the method `castRay(forColumn: width:)` applies this correction to a ray’s distance:

```swift
case .wall(let color):
	let projectedDistance = ray.length * cos(relativeAngle)
	…
	return .wall(color: illuminatedColor, distance: projectedDistance)
```

### Adding some Light
For now, our virtual world still looks a bit too simplified. We should definitely add some light effects!

![][image-17]

To improve our visualization we add two simple types of lighting:

1. Distance lighting
2. Directional lighting

Adding light to our scene effectively means that we adjust the color of our walls by making it a bit darker. If a color should appear darker we reduce all color components to a certain percentage. This means that all light intensity are defined by a percentage value from 0 to 1.

#### Distance Lighting
Distance lighting works like a flashlight: It reduces the light intensity of a wall depending on its distance. To calculate the illumination we need to define a maximum distance the light our flashlight should reach. This is the global parameter `illuminationRadius` which is set to the `Renderer` instance during startup. We also need a minimal light intensity to ensure that our world doesn’t get too dark. By relating these constants with the ray’s length we can then simulate a distance lighting:

```swift
let distanceLightIntensity = min(max(1.0 - ray.length/illuminationRadius, minimumLight), 1.0)
```

Adding distance light already increases the quality of our scene a bit:

![][image-18]

#### Directional Lighting
Directional lighting simulates a global light source. It assigns every side of a wall a certain light intensity. If we look at the northern or western side of a wall it may appear darker than if we look at its southern or eastern side. 

The intensity for directional lighting is calculated by the method `Map.lightIntensityForWall(atPoint: direction:)`. It first determines whether the ray hit a side of the wall that is on a vertical or a horizontal grid line by comparing the distance of the hit point to the surrounding grid lines. Then it inspects the ray’s angle to see from which direction the wall was approached. Adding directional light dramatically improves the 3D feeling of our scene:

![][image-19]

#### Applying Lighting
The lighting is applied in the `Render.castRay(…)` method. Whenever a ray hit a wall, the distance and directional lighting at the hit point is calculated. Both light intensities are then combined and applied to the color of the hit point:

```swift
let illuminatedColor = color.adjustLightIntensity(distanceLightIntensity * wallLightIntensity)
return .wall(color: illuminatedColor, distance: projectedDistance)
```

## How to Continue?
I wanted to keep this demo simple to keep this demo clear. Therefore, this demo is still not at a point where computer games where back in the 90’s. There are a lot of things we could add:

1. **Texture mapping**: Instead of using flat colors, we could also draw a bitmap texture on each wall.
2. **Actors and Items**: Of course a computer game needs other actors and collectable items. Contrary to walls, such actors may move freely within the map, so they need a special rendering.
3. **Magic walls**: Why not adding magic walls, elevators or doorways that can be opened?
4. **Overlays**: What about showing the player’s status or collected items? You can do this by drawing an overlay on top of the scene…
5. **Performance**: To keep the code clear I sacrificed performance on many points. Try to find and improve performance holes.

Of course, Ray Casting is an outdated technique. But it has a big sister that is the technical basis for all modern 3D animation films: [Ray Tracing][4]. Ray Tracers usually scan the environment vertically and horizontally without tying them to a fixed grid. They are also capable of tracking different light sources in a scene to simulate reflections and other light effects. However, Ray Tracing is computational intensive, so it is usually not used by computer games (even though [recent developments][5] show that future computer games will probably use it).

Contemporary computer games typically use [3D polygon rendering][6] which works a bit different than Ray Casting and is usually also built into the graphic  hardware. Marcus Müller implemented a [software rendering demo in Swift][7] that uses this technique.

Finally, I’m planning to use this demo to have a minimal sample when learning a new programming language. I’ve ported the renderer to [Rust][8] and also created a [browser version][9] of it.

## Feedback
I’m happy to receive any feedback on this demo and this article! Please feel free to send your feedback via Github or at [Twitter][10]!

[1]:	https://en.wikipedia.org/wiki/Ray_casting
[2]:	https://cdn.rawgit.com/hydrixos/raycaster-rust/df4db06b/html/index.html
[3]:	https://github.com/hydrixos/raycaster-rust
[4]:	https://en.wikipedia.org/wiki/Ray_tracing_(graphics)
[5]:	https://www.youtube.com/watch?v=J3ue35ago3Y
[6]:	https://en.wikipedia.org/wiki/Graphics_pipeline
[7]:	https://github.com/mmllr/Renderer
[8]:	https://github.com/hydrixos/raycaster-rust
[9]:	https://rawgit.com/hydrixos/raycaster-rust/html/index.html
[10]:	https://twitter.com/hdrxs

[image-1]:	doc/readme.gif
[image-2]:	doc/map.png
[image-3]:	doc/full.png
[image-4]:	doc/rays.png
[image-5]:	doc/sliced.png
[image-6]:	doc/model.png
[image-7]:	doc/ray-angle.png
[image-8]:	doc/triangle-formula.png
[image-9]:	doc/steps.png
[image-10]:	doc/ray-growing.png
[image-11]:	doc/triangle-formula.png
[image-12]:	doc/x-direction.png
[image-13]:	doc/fisheye.png
[image-14]:	doc/perspective-central.png
[image-15]:	doc/perspective-parallel.png
[image-16]:	doc/perspective-correction.png
[image-17]:	doc/light-none.png
[image-18]:	doc/light-distance.png
[image-19]:	doc/light-directional.png