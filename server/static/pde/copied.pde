

// Global variables
int radius = 50.0;
int X, Y;
int nX, nY;
int delay = 16;

// Setup the Processing Canvas
void setup(){
	size(document.getElementById('canvas').offsetWidth, document.getElementById('canvas').offsetHeight);
	strokeWeight( 10 );
	frameRate( 30 );
	X = width / 2;
	Y = height / 2;
	nX = X;
	nY = Y;  
}

// Main draw loop
void draw(){
	size(window.innerWidth, window.innerHeight-110);
	radius = radius + sin( frameCount / 4 );

	nX = width / 2;
	nY = height / 2;
	
	// Track circle to new destination
	X+=(nX-X)/delay;
	Y+=(nY-Y)/delay;
	
	// Fill canvas grey
	background( 100 );
	
	// Set fill-color to blue
	if (window.bar) {
		fill(0, 0, 128);
	}
	else {
		fill( 0, 121, 184 );
	}
	// Set stroke-color white
	stroke(255); 
	
	// Draw circle
	ellipse( X, Y, radius, radius );                  
}
