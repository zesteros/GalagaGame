import processing.video.*;

import ddf.minim.*;
import ddf.minim.analysis.*;
import ddf.minim.effects.*;
import ddf.minim.signals.*;
import ddf.minim.spi.*;
import ddf.minim.ugens.*;

SpaceShip spaceShip;
//PImage stars, 
PImage gameOver, gameCompleted;
Block[] blocks;
long time;
boolean gameFinished, gameWin;
Minim minim;
AudioPlayer player1, player2;
AudioInput input;
Movie video;
boolean videoPlayed;


void setup() {
  background(255);
  size(500, 500);
  spaceShip = new SpaceShip();
  //stars = loadImage("stars.jpg");
  gameOver = loadImage("gameover.jpg");
  gameCompleted = loadImage("win.jpg");
  /*
    Create blocks parameters are how much (first) and 
   how much rows (second)
   */
  createBlocks(20, 5);
  time = millis();
  minim = new Minim(this);
  video = new Movie(this, "Galaga.mp4");
  video.noLoop();
  video.play();
}

int i = 0;

void draw() {
  if (videoPlayed) {
    if (!gameFinished) {
      //drawStars();
      background(0);
      drawBlocks(2000, 2);//2000 is the time for move and 2 the step
      if (keyPressed) spaceShip.moveShip(5);//5 is the step
      spaceShip.drawRocket();
      spaceShip.moveShots();
    } else {
      if (!gameWin)set(0, 0, gameOver);
      else set(0, 0, gameCompleted);
    }
  } else 
    image(video, 0, 0);
  
}
void movieEvent(Movie m) {
  m.read();
}

void drawBackground() {
  PImage img = loadImage("stars.jpg");
  image(img, 0, 0);
  loadPixels();
  updatePixels();
}

void keyPressed() {
  if (!videoPlayed) { 
    video.stop();
    videoPlayed = true;
  }
  if (keyCode == UP) {
    spaceShip.shoot(
      spaceShip.spaceShipNoseCoords[0]+spaceShip.x, 
      spaceShip.spaceShipNoseCoords[1]+spaceShip.y+10
      );
    player1 = minim.loadFile("shoot.wav");
    player1.play();
  }
  if (keyCode == ENTER) {
    if (gameFinished) {
      createBlocks(20, 5);
      gameFinished = false;
      time = millis();
    }
  }
}

/*void drawStars(int speed) {
 i = i == height ? 0 : i;
 set(0, i, stars);
 set(0, i-height, stars);
 i += speed;
 }*/

void createBlocks(int size, int rows) {
  blocks = new Block[((width/size)*rows*2)];
  int j = 0;
  for (int i = -size*rows; i < size*rows; i+=size) 
    for (int k = 0; k < width; k+=size) {
      blocks[j] = new Block(k, i, size);
      j++;
    }
}
boolean timeEllapsed;

void drawBlocks(int timeLimit, float step) {
  if (millis() >= time+timeLimit && millis() <= time+timeLimit+50) {
    timeEllapsed = true;
    time = millis();
  } else timeEllapsed = false;
  int n = 0;
  for (int i = 0; i < blocks.length; i++) {
    if (blocks[i] != null) {
      if (timeEllapsed) {
        blocks[i].y+=step;
        if (blocks[i].y >= spaceShip.spaceShipNoseCoords[1]+spaceShip.y) 
          gameFinished = true;
      } 
      blocks[i].drawBlock();
    } else n++;
  }
  if (n == blocks.length-1) {
    gameWin = true;
    gameFinished = true;
  }
}

class SpaceShip {
  final int[][] vertex = {
    {50, 10}, 
    {45, 20}, 
    {45, 60}, 
    {40, 60}, 
    {35, 50}, 
    {30, 60}, //6
    {30, 85}, //7
    {45, 85}, //8
    {47, 90}, //9
    {52, 90}, 
    {55, 85}, 
    {70, 85}, 
    {70, 60}, //13
    {65, 50}, 
    {60, 60}, 
    {55, 60}, 
    {55, 20}
  };
  final int [][] fire = {
    {47, 115}, 
    {48, 105}, 
    {49, 115}, 
    {50, 105}, 
    {52, 115}, 
    {52, 90}, 
    {47, 90}
  };


  final int spaceShipNoseCoords [] = {
    vertex[0][0], 
    vertex[0][1]
  };

  int x;
  int y;
  int [] limits;
  float rockY = 0;
  Shot startShot, endShot;

  SpaceShip() {
    x = width/2-47;
    y = height/2+100;
  }

  void shoot(int x, int y) {
    stroke(0, 255, 0);
    if (startShot == null) {
      Shot newShot = new Shot(x, y, 4);
      startShot = endShot = newShot;
    } else {
      Shot newShot = new Shot(x, y, 4);
      endShot.nextShot = newShot;
      newShot.previousShot = endShot;
      endShot = newShot;
      endShot.nextShot = null;
    }
  }

  void moveShots() {
    stroke(0, 255, 0);
    Shot aux = startShot;
    while (aux != null) {
      aux.moveShot();
      checkTrackOfShot(aux, aux.x, aux.y2);
      i++;
      aux = aux.nextShot;
    }
  }

  boolean checkTrackOfShot(Shot shot, int x, int y) {
    for (int i = 0; i < blocks.length; i++)
      if (blocks[i] != null)
        if (blocks[i].hasBeenTouched(x, y)) {
          player2 = minim.loadFile("block_deleted.wav");
          player2.play();
          blocks[i].eraseBlock();
          blocks[i] = null;
          shot.speed = 0;
          shot.y2 = y;
          deleteShot(shot);
          return true;
        }
    return false;
  }

  void deleteShot(Shot shot) {
    Shot aux = startShot;
    while (aux != null) {
      if (aux == shot) {
        if (aux == startShot && aux == endShot) {
          startShot = endShot = null;
          return;
        } else if (aux == startShot) {
          startShot = aux.nextShot;
          startShot.previousShot = null;
          return;
        } else if (aux == endShot) {
          endShot = aux.previousShot;
          endShot.nextShot = null;
          return;
        } else {
          Shot prev = aux.previousShot;
          Shot nex = aux.nextShot;
          prev.nextShot = nex;
          nex.previousShot = prev;
          return;
        }
      }
      aux = aux.nextShot;
    }
  }

  void drawRocket() {
    stroke(255, 0, 0);
    beginShape();
    for (int i = 0; i < vertex.length; i++) {
      fill(200);
      vertex(vertex[i][0]+x, vertex[i][1]+y);
    }
    endShape(CLOSE);
  }

  boolean isInLimits() {
    if (vertex[5][0]+x <= 0 || vertex[0][1]+y <= 0) {
      x+=0.001;
      //y+=0.001;
      return true;
    }

    if (fire[0][1]+y >= height || vertex[12][0]+x >= width) {
      //y-=0.001;
      x-=0.001;
      return true;
    }
    return false;
  }

  public void drawFire() {
    stroke(0, 255, 0);
    beginShape();
    for (int i = 0; i < fire.length; i++) {
      fill(255, 255, 0);
      vertex(fire[i][0]+x, fire[i][1]+y);
    }
    endShape(CLOSE);
  }

  void moveShip(int step) {
    if (!isInLimits())
      switch(keyCode) {
      case RIGHT:
        x += step;
        drawFire();
        break;
      case LEFT:
        x -= step;
        drawFire();
        break;
      case DOWN:
        //y+=4;
        break;
      }
  }
}
private class Shot {

  public int x, y1, y2, speed;
  public Shot nextShot, previousShot;
  public boolean keepDrawing;

  public Shot(int x, int y, int speed) {
    this.x = x;
    this.y1 = y;
    this.y2 = (int) random(330, 332);
    this.speed = speed;
    this.keepDrawing = true;
  }

  public void moveShot() {
    line(x, y1, x, y2);
    if (this.y1 >= this.y2) this.y1 -= speed;
    if (keepDrawing) {    
      this.y2 -= speed;
    }
  }
}


private class Block { 

  public int x, y, size;

  public Block(int x, int y, int size) {
    this.x = x;
    this.y = y;
    this.size = size;
  }

  public void drawBlock() {
    stroke(0, 255, 128);
    fill(200, 180, 255, 100);
    rect(this.x, this.y, this.size, this.size);
  }

  public void eraseBlock() {
    stroke(0);
    noFill();
    rect(this.x, this.y, this.size, this.size);
  }

  public boolean hasBeenTouched(int x, int y) {
    return y >= this.y && y <= (this.y + size) 
      && x >= this.x && x <= (this.x + size);
  }
}