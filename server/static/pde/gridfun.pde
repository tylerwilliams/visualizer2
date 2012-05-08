float colorR = 100; 
float colorG = 100; 
float colorB = 100; 
 
void setup (){ 
	size(window.innerWidth, window.innerHeight-110);
  frameRate(30); 
  smooth(); 
} 
 
void draw() { 
	size(window.innerWidth, window.innerHeight-110);
  background(0); 
  for(int x = 0; x < width; x+=40){ 
    for(int y = 0; y < height; y+=40){ 
      stroke(255,255,255,50); 
      fill(colorR,colorG,colorB,random(0,255)); 
      rect(x,y,40,40); 
    } 
  } 
 
}