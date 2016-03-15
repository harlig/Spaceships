//Collin Dutter
//Ethan Harlig
//CPE 123 T/Th 12-3
//Zoe Wood

import ddf.minim.*;
import java.util.ArrayList;
import java.util.HashSet;


public World gameWorld; //a world contains all the asteroids, ships, lasers etc. Everything.
public Camera camera;
public static final int GAME_WIDTH = 800;//define custom width
public static final int GAME_HEIGHT = GAME_WIDTH/4*3;//define custom height width 4*3 aspect ratio
public HashSet<Integer> keysPressed;//Set of keys which are pressed
//declare a particle system
public int frame;
public Minim minim;
public Screen currentScreen;


void setup() {
  size(800, 600);
  keysPressed = new HashSet<Integer>();
  minim = new Minim(this);
  currentScreen = new TitleScreen();
}

void draw() {
  currentScreen.updateScreen();
  currentScreen.drawScreen();
  fill(#DCFF00);
  textSize(15);
  textAlign(LEFT);
  text((int)frameRate, GAME_WIDTH-30, GAME_HEIGHT-5);
  fill(0);
}

//On key press, add that key to the set of keys pressed
public void keyPressed(KeyEvent e) {
  keysPressed.add(e.getKeyCode());
  if (currentScreen instanceof DeathScreen) {
    int c = e.getKeyCode();
    if (c == 10)
      currentScreen = new HighScoreScreen(((DeathScreen)currentScreen).name == "" ? "SpaceShips Player" : ((DeathScreen)currentScreen).name, ((DeathScreen)currentScreen).score);
    if (c == 8 && ((DeathScreen)currentScreen).name.length() > 0) {
      StringBuilder sb = new StringBuilder(((DeathScreen)currentScreen).name);
      sb.deleteCharAt(((DeathScreen)currentScreen).name.length()-1);
      ((DeathScreen)currentScreen).name = sb.toString();
    } else if (c != 8 && c!= 10 && ((DeathScreen)currentScreen).name.length() < 16) {
      ((DeathScreen)currentScreen).name+=key;
    }
  }
  if (currentScreen instanceof GameScreen)
    if (e.getKeyCode() == 80)
      gameWorld = new World();
}

//On key release, remove that key from the set of keys pressed
public void keyReleased(KeyEvent e) {
  keysPressed.remove(e.getKeyCode());
}

public float distSquared(float x1, float y1, float x2, float y2) {
  return (x2-x1)*(x2-x1) + (y2-y1)*(y2-y1);
}

public class Camera {
  public float x, y;
  public float viewWidth, viewHeight;

  public Camera() {
    x = 0;
    y = 0;
    viewHeight = GAME_HEIGHT;
    viewWidth = GAME_WIDTH;
  }
  public Camera(float x, float y) {
    this();
    this.x = x;
    this.y = y;
  }

  public void drawCamera() {
  } 

  public void updateCamera() {
    if (!gameWorld.player.destroyed) {
      if (gameWorld.player.cx > x+GAME_WIDTH*3/4) 
        x+=gameWorld.player.velocity.x;

      if (gameWorld.player.cx < x+GAME_WIDTH*1/4) 
        x-=gameWorld.player.velocity.x;

      if (gameWorld.player.cy > y+GAME_HEIGHT*3/4) 
        y+=gameWorld.player.velocity.y;

      if (gameWorld.player.cy < y+GAME_HEIGHT*1/4) 
        y-=gameWorld.player.velocity.y;
    }
  }
}

//player space ship
public class SpaceShip {
  public float cx, cy;//center x coordinate, center y coordinate
  public PVector velocity;//ship velocity
  public final int MAX_VELOCITY;//maximum ship velocity
  public PVector acceleration;//ship acceleration
  public float rotation;//ships current angle/rotation/theta in degrees
  public float rotationVelocity;//velocity at which ship rotates

  public AudioPlayer dyingSound;
  public AudioPlayer thrusterSound;
  public boolean destroyed = false;
  public boolean thrusting;

  public PImage sprite;
  public int lives;
  public ParticleSystem thrust;
  public ParticleSystem explosion;
  public int score;
  public int comboScore;

  public int timeOfDeath;

  public Turret turret;
  public SpaceShip() {
    cx = camera.x + camera.viewWidth/2;
    cy = camera.y + camera.viewHeight/2;
    MAX_VELOCITY = 3;
    velocity = new PVector();
    acceleration = new PVector(.05, .05);
    rotationVelocity = 3;
    rotation = 0;
    velocity.normalize();
    turret = new Turret();
    lives = 3;
    thrust = new ParticleSystem(new PVector(cx, cy));
    explosion = new ParticleSystem(new PVector(cx, cy));
    dyingSound = minim.loadFile("dyingsound.wav");
    thrusterSound = minim.loadFile("thrusters1.wav");
    sprite = loadImage("spaceship.png");
    thrusting = true;
    score = 0;
    comboScore = -10;
  }

  //draws the space ship
  public void drawShip() {
    float drawX = cx - camera.x;
    float drawY = cy - camera.y;


    thrust.run();
    if (!destroyed) {
      if (thrusting) {
        //thrusterSound.play(0)a;
        thrust.source.x = drawX-16*cos(radians(rotation));
        thrust.source.y = drawY-16*sin(radians(rotation));
        thrust.addParticles(50, rotation);
      }
      //rotate to current angle
      pushMatrix();
      translate(drawX, drawY);
      rotate(radians(rotation+90));
      translate(-drawX, -drawY);
      //draw the actual ship
      image(sprite, drawX-16, drawY-16, 32, 32);

      popMatrix();
      turret.drawTurret(drawX, drawY);
    }
    if (destroyed) {
      explosion.run();
    }
  }

  //updates the ship and handles all user input
  void updateShip() {
    //update the ship's coordinates by adding its velocity which is limited between the two values
    //-MAX_VELOCITY and MAX_VELOCIT
    if (destroyed)
      velocity = new PVector();
    cx+=velocity.x*cos(radians(rotation));
    cy+=velocity.y*sin(radians(rotation));

    //user input handling
    //if at least one key is pressed
    if (keysPressed.size() > 0) {
      for (int c : keysPressed) {
        //move forward if 'w' pressed
        if (c == 87) {
          velocity.x=constrain(velocity.x+acceleration.x, 0, MAX_VELOCITY);
          velocity.y=constrain(velocity.y+acceleration.y, 0, MAX_VELOCITY);
          thrusting = true;
        } else {
          if (velocity.x > 0)
            velocity.x-=acceleration.x/3.0;
          if (velocity.y > 0)
            velocity.y-=acceleration.y/3.0;
        }
        //rotate counter clock if 'a' pressed
        if (c == 65) {
          rotation-=rotationVelocity;
        }
        //rotate clock if 'd' pressed
        if (c == 68) {
          rotation+=rotationVelocity;
        }
      }
    } else {
      if (velocity.x > 0)
        velocity.x-=acceleration.x/3.0;
      if (velocity.y > 0)
        velocity.y-=acceleration.y/3.0;
      thrusting = false;
    }

    if (destroyed) {
      if (millis() - timeOfDeath > 2000) {
        destroyed = false;

        gameWorld.asteroids = new ArrayList<Asteroid>();
        gameWorld.maxAsteroids = 30;

        cx = camera.x + camera.viewWidth/2;
        cy = camera.y + camera.viewHeight/2;

        lives--;
      }
    }

    turret.updateTurret(cx, cy);
  }
}

public class Turret {
  public float rotation;
  public AudioPlayer fireSound;
  public boolean firing;
  private int lastFired;//last time in millis which the ships lasers were fired

    public Turret() {
    firing = false;
    fireSound = minim.loadFile("lasershoot.wav");
  }
  public void updateTurret(float shipX, float shipY) {
    rotation = atan2(mouseY - (shipY-camera.y), mouseX- (shipX-camera.x));
    //fire if 
    if (mousePressed && !gameWorld.player.destroyed) {
      //make sure it has been at least 200 ms since last shot fired
      if (millis() - lastFired >=200) {
        gameWorld.lasers.add(new Laser(rotation, shipX, shipY));
        lastFired = millis();
        fireSound.play();
        fireSound.rewind();
      }
    }
  }
  public void drawTurret(float shipDrawX, float shipDrawY) {
    pushMatrix();
    translate(shipDrawX, shipDrawY);
    rotate(rotation);
    translate(-shipDrawX, -shipDrawY);
    noStroke();
    fill(#B4070D);
    ellipse(shipDrawX, shipDrawY, 5, 5);
    rectMode(CENTER);
    rect(shipDrawX+7, shipDrawY, 10, 5);
    rectMode(LEFT);
    stroke(0);
    popMatrix();
  }
}


//Basically just asteroids
public class Asteroid {
  public float cx, cy; //center x coordinate, center y coordinate
  public float rotation;//amount asteroid is rotated in degrees
  public float rotationVelocity;//velocity at which asteroid rotates
  public float flyingAngle;//angle at which asteroid is flying in degrees
  public PVector velocity;//asteroid's velocity
  public boolean damaged;//whether asteroid has been damaged or not
  public int diameter;//width of asteroid
  public float[][] vertices;
  public float hitAngle;


  public Asteroid(float cx, float cy, int size) {
    velocity = new PVector(random(0, 1.7), random(0, 1.7));
    rotationVelocity = random(-1, 2); 
    this.cx = cx;
    this.cy = cy;
    this.diameter = size;
    if (currentScreen instanceof GameScreen)
      flyingAngle = random(-40, 40) + degrees(atan2(gameWorld.player.cy-cy, gameWorld.player.cx-cx));//angle to the player plus some error
    else if (currentScreen instanceof BackgroundActiveScreen)
      flyingAngle = random(-40, 40) + degrees(atan2(camera.viewWidth/2-cy, camera.viewHeight/2-cx));

    vertices = new float[8][2];
    float radius = 0;
    float theta = 0;
    for (int i = 0; i < 8; i++) {
      if (i%(int)random(1, 3)==0)
        radius = size/2-(int)random(1, 6);
      else
        radius = size/2;
      float vertexX = radius*cos(theta);
      float vertexY = radius*sin(theta); 
      theta+=TWO_PI/8;
      vertices[i][0] = vertexX;
      vertices[i][1] = vertexY;
    }
  }

  public Asteroid(float cx, float cy, int size, float flyingAngle) {
    this(cx, cy, size);
    this.flyingAngle = flyingAngle;
  }

  //draws the asteroid
  public void drawAsteroid() {
    float drawX = cx- camera.x;
    float drawY = cy - camera.y;
    pushMatrix();
    //rotate it to the current rotation
    translate(drawX, drawY);
    rotate(radians(rotation));
    translate(-drawX, -drawY);
    popMatrix();
    //draws the actual asteroid
    fill(255);
    strokeWeight(2);
    beginShape();
    for (int i = 0; i < vertices.length; i++) {
      vertex(drawX + vertices[i][0], drawY + vertices[i][1]);
    }
    endShape(CLOSE);
  }
  //updates the asteroid

  public boolean updateAsteroid() {
    //updates the coordinates
    cx+=velocity.x*cos(radians(flyingAngle));
    cy+=velocity.y*sin(radians(flyingAngle));

    //destroys asteroid if its off the screen (plus a slight margin)
    if (cx> camera.x + camera.viewWidth + 100|| cx < camera.x-100 || cy > camera.y + camera.viewHeight+100 || cy < camera.y-100)
      return false;
    if (currentScreen instanceof GameScreen) {
      if (!gameWorld.player.destroyed) {
        if (distSquared(this.cx, this.cy, gameWorld.player.cx, gameWorld.player.cy) < 400+(diameter/2)*(diameter/2)) {
          gameWorld.player.destroyed = true;
          gameWorld.player.comboScore = -10;
          gameWorld.player.timeOfDeath = millis();
          gameWorld.player.explosion.source.x = cx - camera.x;
          gameWorld.player.explosion.source.y = cy - camera.y;
          gameWorld.player.explosion.addParticles(5000);
          gameWorld.player.dyingSound.play(0);
        }
      }
    }

    //rotates the asteroid  
    rotation+=rotationVelocity;
    return true;
  }
}
//lasers which the ship fires
public class Laser {
  public float angleFired;//angle at which laser was fired
  public float cx, cy;//center x coordinate center y coordinate
  public float laserVelocity = 7;
  public Laser(float turretRotation, float x, float y) {
    angleFired = turretRotation;
    cx = x;
    cy = y;
  }

  //draws the laser
  public void drawLaser() {

    float drawX = cx - camera.x;
    float drawY = cy - camera.y;

    stroke(255, 0, 0);
    strokeWeight(2);
    // noStroke();
    line(drawX, drawY, drawX + 5*cos(angleFired), drawY+5*sin(angleFired));
    stroke(0);
  }

  //updates the laser
  public boolean updateLaser() {
    //update the coordinates based on the angle fired
    cx+=laserVelocity*cos(angleFired) + 7*cos(angleFired);
    cy+=laserVelocity*sin(angleFired) + 7*sin(angleFired);

    //destroys laser if its off the screen (plus a slight margin)
    if (cx> camera.x + camera.viewWidth + 5|| cx < camera.x-5 || cy > camera.y + camera.viewHeight+5 || cy < camera.y-5) {
      gameWorld.player.comboScore = -10;
      return false;
    }
    //check for collisions with other asteroids
    for (Asteroid a : gameWorld.asteroids) {
      //if collision, set the asteroid to damaged
      if (distSquared(cx, cy, a.cx, a.cy) < 4+(a.diameter/2)*(a.diameter/2)) {
        a.damaged = true;
        a.hitAngle = angleFired;
        if (currentScreen instanceof GameScreen) {
          ((GameScreen)currentScreen).comboTexts.add(new ComboText(gameWorld.player.comboScore));
        }
        return false;
      }
    }
    return true;
  }
}


//the world which everything is contained
public class World {
  public SpaceShip player;//the player
  public ArrayList<Asteroid> asteroids;//list of all the asteroids currently in world
  public ArrayList<Laser> lasers;//list of all the lasers currently in world
  public int maxAsteroids;//maximum number of asteroids which can be in world at one time
  public boolean screenShake;
  public int startShake;
  public static final int WIDTH = GAME_WIDTH;
  public static final int HEIGHT = GAME_HEIGHT;
  private float lastTime;
  private PImage starBackground;
  private float backgroundX, backgroundY;
  public boolean drawComboScore;

  public World() {
    camera = new Camera();
    player = new SpaceShip();
    
    lasers = new ArrayList<Laser>();
    asteroids = new ArrayList<Asteroid>();
    screenShake = false;
    startShake = 0;
    maxAsteroids = 30;
    lastTime = millis();
    starBackground = loadImage("stars.jpg");
    backgroundX = 0;
    backgroundY = 0;
  }
  //draws the world
  public void drawWorld() {
    //super detailed space background
    background(0);
    if (screenShake)
      translate((int)random(-5, 5), (int)random(-5, 5));


    image(starBackground, backgroundX-camera.x, backgroundY-camera.y);
    image(starBackground, backgroundX+starBackground.width-camera.x, backgroundY-camera.y);
    image(starBackground, backgroundX-starBackground.width-camera.x, backgroundY-camera.y);
    image(starBackground, backgroundX-camera.x, backgroundY-starBackground.height-camera.y);
    image(starBackground, backgroundX-camera.x, backgroundY+starBackground.height-camera.y);

    image(starBackground, backgroundX+starBackground.width-camera.x, backgroundY+starBackground.height-camera.y);
    image(starBackground, backgroundX-starBackground.width-camera.x, backgroundY-starBackground.height-camera.y);
    image(starBackground, backgroundX+starBackground.width-camera.x, backgroundY-starBackground.height-camera.y);
    image(starBackground, backgroundX-starBackground.width-camera.x, backgroundY+starBackground.height-camera.y);

    int w = starBackground.width*3/4;
    int h = starBackground.height*3/4;
    float drawX = player.cx - camera.x;
    float drawY = player.cy - camera.y;

    if (drawX %  w > 595 && player.cx > backgroundX + 595) 
      backgroundX+=starBackground.width;

    if (drawX % w < 205 && player.cx < backgroundX + 205) 
      backgroundX-=starBackground.width;

    if (drawY % h > 445 && player.cy > backgroundY + 445) 
      backgroundY+=starBackground.height;

    if (drawY % h < 155 && player.cy < backgroundY + 155)  
      backgroundY -=starBackground.height;




    //loop through all lasers and draw them
    for (Laser l : lasers)
      l.drawLaser();

    //loop through all asteroids and draw them  
    for (Asteroid a : asteroids)
      a.drawAsteroid();
    //draw player ship
    if (currentScreen instanceof GameScreen)
      player.drawShip();
  }

  //updates world
  public void updateWorld() {
    if (millis()-startShake > 20)
      screenShake = false;
    if (currentScreen instanceof GameScreen) {
      if (millis() - lastTime >= 5000) {
        if (maxAsteroids > 0 && maxAsteroids <= 90) {
          maxAsteroids+=10;
          lastTime = millis();
        }
      }
    }
    //loops through all lasers andr draws them
    for (int i = 0; i < lasers.size (); i++) {
      Laser l = lasers.get(i);
      //if updateLaser returned false (off screen), delete the laser
      if (!l.updateLaser()) {
        lasers.remove(i);
      }
    }

    //generate asteroids in 4 different quadrants of screen 
    if (asteroids.size() < maxAsteroids) {
      for (int i = asteroids.size (); i < maxAsteroids; i++) {
        int side = (int)random(0, 4);
        float x = camera.x;
        float y = camera.y;
        float cameraWidth = camera.viewWidth;
        float cameraHeight = camera.viewHeight;
        switch(side) {
        case 0:
          //left
          asteroids.add(new Asteroid(random(x-200, x-20), random(y, y+cameraHeight), (int)random(25, 50)));
          break;
        case 1:
          //right
          asteroids.add(new Asteroid(random(x + cameraWidth +20, x + cameraWidth+200), random(y, y+cameraHeight), (int)random(25, 50)));
          break;
        case 2:
          //bottom
          asteroids.add(new Asteroid(random(x, x+cameraWidth), random(y + cameraHeight+20, y + cameraHeight+200), (int)random(25, 50)));
          break;
        case 3:
          //top
          asteroids.add(new Asteroid(random(x, x + cameraWidth), random(y-200, y-20), (int)random(25, 50)));
          break;
        }
      }
    }
    //check for destroy asteroids
    for (int i = 0; i < asteroids.size (); i++) {
      Asteroid a = asteroids.get(i);
      //if off screen destroy
      if (!a.updateAsteroid()) 
        asteroids.remove(i);

      //if hit by laser, split into 3 asteroids
      if (a.damaged) {
        asteroids.remove(i);
        startShake = millis();
        screenShake = true;
        player.score+=100+player.comboScore;
        if (a.diameter > 25) {
          for (int j = 0; j < 3; j++) {
            asteroids.add(new Asteroid(a.cx, a.cy, a.diameter-10, a.flyingAngle));
          }
        }
      }
    }
    //update player ship
    if (currentScreen instanceof GameScreen)
      player.updateShip();
    //client.write((int)player.cx+","+(int)player.cy+","+(int)player.rotation+"*");
  }
}



class Particle {
  PVector loc;
  PVector vel;
  PVector accel;
  float r;
  float life;
  color redParticle, orangeParticle;
  float rotation;

  //constructor
  Particle(PVector start, float playerRotation) {
    accel = new PVector(0, 0.05, 0); //gravity
    vel = new PVector(random(0, 3), random(0, 3), 0);
    redParticle = color(random(200, 255), random(0, 5), random(0, 20));
    orangeParticle = color(random(200, 255), random(75, 125), random(0, 50));   
    loc = start.get();
    r = 8.0;
    life = 50;
    rotation = playerRotation;
    // vel.normalize();
  }
  Particle(PVector start) {
    accel = new PVector(0, 0.05, 0);
    vel = new PVector(random(0, 3), random(0, 3));
    redParticle = color(random(200, 255), random(0, 5), random(0, 20));
    orangeParticle = color(random(200, 255), random(75, 125), random(0, 50));
    loc = start.get();
    r = 8.0;
    life = 50;
    rotation = random(0, 360);
  }

  //TODO define another constructor that allows a particle to start with a given color

  //what to do each frame
  void run() {
    updateP();
    drawParticle();
  }

  //a function to update the particle each frame
  void updateP() {
    vel.add(accel);
    loc.x-= vel.x*cos(radians(rotation));
    loc.y-= vel.y*sin(radians(rotation));
    life -= 1.0;
  }

  //how to draw a particle
  void drawParticle() {
    pushMatrix();
    ellipseMode(CENTER);
    //stroke(pcolor, life);
    noStroke();
    fill(((int)random(0, 4) > 1 ? redParticle : orangeParticle), life);
    translate(loc.x, loc.y);
    ellipse(0, 0, r, r);
    stroke(0);
    popMatrix();
  }

  //a function to test if a particle is alive
  boolean alive() {
    if (life <= 0.0) {
      return false;
    } else {
      return true;
    }
  }
} //end of particle object definition

//now define a group of particles as a particleSys
class ParticleSystem {

  ArrayList particles; //all the particles
  PVector source; //where all the particles emit from
  PVector shade; //their main color

  //constructor
  ParticleSystem(int num, PVector init_loc, float playerRotation) {
    particles = new ArrayList();
    source = init_loc.get();
    shade = new PVector(random(255), random(255), random(255));
    for (int i=0; i < num; i++) {
      particles.add(new Particle(source, playerRotation));
    }
  }
  ParticleSystem(int num, PVector init_loc) {    
    particles = new ArrayList();
    source = init_loc.get();
    shade = new PVector(random(255), random(255), random(255));
    for (int i=0; i < num; i++) {
      particles.add(new Particle(source));
    }
  }
  ParticleSystem(PVector location) {    
    particles = new ArrayList();
    source = location.get();
    shade = new PVector(random(255), random(255), random(255));
  }

  public void addParticles(int num, float playerRotation) {
    for (int i = 0; i < num; i+=5)
      particles.add(new Particle(source, playerRotation));
  }
  public void addParticles(int num) {
    for (int i = 0; i < num; i+=5)
      particles.add(new Particle(source));
  }

  //what to do each frame
  void run() {
    //go through backwards for deletes
    for (int i=particles.size ()-1; i >=0; i--) {
      Particle p = (Particle) particles.get(i);
      //update each particle per frame
      p.run();
      if ( !p.alive()) {
        particles.remove(i);
      }
    }
  }

  //is particle system still populated?
  boolean dead() {
    if (particles.isEmpty() ) {
      return true;
    } else {
      return false;
    }
  }
}

public abstract class Screen {
  public PFont font;

  public Screen() {
    font = createFont("spacefont.ttf", 32);
    textFont(font);
    keysPressed = new HashSet<Integer>();
  }

  public abstract void drawScreen();
  public abstract void updateScreen();
}

public class BackgroundActiveScreen extends Screen {
  private World world;

  public BackgroundActiveScreen() {
    super();
    camera = new Camera(0, 0);
    world = new World();
  }
  public BackgroundActiveScreen(World world) {
    super();
    camera = new Camera();
    this.world = world;
  }
  public void updateScreen() {
    world.updateWorld();
  }

  public void drawScreen() {

    world.drawWorld();
  }
}


public class TitleScreen extends BackgroundActiveScreen {
  private float lastTime;
  private boolean flashText;


  public void drawScreen() {
    super.drawScreen();

    textSize(50);
    textAlign(CENTER);
    fill(255);
    text("SpaceShips", width/2, height/2-50);
    textSize(25);
    text("an interstellar adventure by", width/2, height/2-25);
    text("Collin Dutter and Ethan Harlig", width/2, height/2);
    if (flashText )
      text("press space to start!", width/2, height/2+50);
  }
  public void updateScreen() {
    super.updateScreen();
    if (keysPressed.size() > 0) {
      for (int c : keysPressed) {
        if (c == 32) {
          currentScreen = new GameScreen();
        }
      }
    }
    if (millis() - lastTime > 600) {
      flashText = !flashText;
      lastTime = millis();
    }
  }
}


public class DeathScreen extends BackgroundActiveScreen {
  private String name;
  private int score;
  private boolean drawLineThingy;
  private long lastTime;
  public DeathScreen(int score) {
    name = "";
    this.score = score;
    drawLineThingy = false;
  }

  public void drawScreen() {
    super.drawScreen();  
    textSize(50);
    textAlign(CENTER);
    text("GAME OVER!", width/2, 50);
    textSize(25);
    text("score: " + score, width/2, 80);
    textSize(50);
    text(name, width/2, 208);
    stroke(255);
    if (drawLineThingy)
      line(width/2 + textWidth(name)/2, 208-50, width/2 + textWidth(name)/2, 208);

    line(width/2-300, 210, width/2+300, 210);
    textSize(25);
    text("Enter name:", width/2, 105);

    stroke(0);
    text("press enter to submit score!", width/2, height/2);
  }

  public void updateScreen() {
    super.updateScreen();
    if (millis() - lastTime > 600) {
      drawLineThingy = !drawLineThingy;
      lastTime = millis();
    }
  }
}

public class GameScreen extends Screen {
  public ArrayList<ComboText> comboTexts;
  public GameScreen() {
    
    gameWorld = new World();
    comboTexts = new ArrayList<ComboText>();
  }

  public void drawScreen() {
    gameWorld.drawWorld();
    pushMatrix();
    textSize(32);
    fill(255);
    textAlign(LEFT);
    text("SCORE: " + gameWorld.player.score, 10, 30);
    for (int i = 0; i < comboTexts.size (); i++) {
      if (!comboTexts.get(i).drawText())
        comboTexts.remove(i);
    }
    popMatrix();

    for (int i = 0; i < gameWorld.player.lives; i++) {
      pushMatrix();
      translate(40*i+25, 580);
      beginShape();
      image(gameWorld.player.sprite, -15, -20, 32, 32);
      popMatrix();
    }
  }
  public void updateScreen() {
    gameWorld.updateWorld();
    camera.updateCamera();
    if (gameWorld.player.lives < 1)
      currentScreen = new DeathScreen(gameWorld.player.score);
  }
}

public class ComboText {
  public float y;
  public int opacity;
  public int comboScore;
  public ComboText(int score) {
    y = 30;
    opacity = 255;
    comboScore = score;
    gameWorld.player.comboScore+=10;
  }

  public boolean drawText() {
    textAlign(LEFT);
    fill(255, opacity-=3);
    text("+" + (comboScore+110), 10+textWidth("SCORE: " + gameWorld.player.score), y--);
    if (y<-32)
      return false;
    return true;
  }
}



public class HighScoreScreen extends BackgroundActiveScreen {
  private JSONArray sortedScores;
  private String playerName;
  private int playerScore;


  public HighScoreScreen(String name, int score) {
    playerScore = score;
    playerName = name;
    JSONObject player = new JSONObject();
    File file =new File(dataPath("scores.json"));
    if (!file.exists()) {
      println("No file!");
      saveJSONArray(new JSONArray(), "data/scores.json");
    }
    JSONArray scores = loadJSONArray("data/scores.json");
    player.setString("name", name);
    player.setInt("score", score);

    scores.append(player);
    sortedScores = BubbleSort(scores);
    saveJSONArray(sortedScores, "data/scores.json");
  }

  public void drawScreen() {
    super.drawScreen();
    for (int i = 0; i < (sortedScores.size () < 15 ? sortedScores.size() : 15); i++) {
      JSONObject player = sortedScores.getJSONObject(i);
      textAlign(LEFT);
      textSize(25);
      fill(255);
      if (player.getString("name") == playerName && player.getInt("score") == playerScore)
        fill(#FAFF12);
      text("#" + (i+1), 20, 75+30*i);  
      text(player.getString("name"), 75, 75+30*i);
      text(player.getInt("score"), 600, 75+30*i);
      textAlign(CENTER);

      text("press space to return to title screen!", width/2, GAME_HEIGHT-30);

      textSize(50);
      text("Highscores", width/2, 50);
    }
  }
  public void updateScreen() {
    super.updateScreen();
    if (keysPressed.size() > 0) {
      for (int c : keysPressed) {
        if (c == 32)
          currentScreen = new TitleScreen();
      }
    }
  }

  public JSONArray BubbleSort(JSONArray players)
  {
    int i;
    boolean notDone = true;  
    JSONObject temp;

    while (notDone)
    {
      notDone=false;
      for (i=0; i < players.size ()-1; i++ )
      {
        if (players.getJSONObject(i).getInt("score")< players.getJSONObject(i+1).getInt("score") )
        {
          temp = players.getJSONObject(i); 
          players.setJSONObject(i, players.getJSONObject(i+1));
          players.setJSONObject(i+1, temp);
          notDone = true;
        }
      }
    }
    return players;
  }
}