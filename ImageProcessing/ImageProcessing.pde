 //<>//
PImage img;
void settings() {
  size(1200, 600);
}
void setup() {
  img = loadImage("board1.jpg");
  colorMode(HSB, 360, 100, 100);
  noLoop(); // no interactive behaviour: draw() will be called only once.
}
void draw() {
  float[][] kernel = { { 9, 12, 9 }, 
    { 12, 15, 12 }, 
    { 9, 12, 9 }};
  //PImage blur = convolute(img, kernel);
  PImage sobel = sobel(img);

  image(sobel, 0, 0);
  hough(result);


  println("end");
}
  
PImage sobel(PImage img) {
  float[][] hKernel = { { 0, 1, 0 }, 
    { 0, 0, 0 }, 
    { 0, -1, 0 } };
  float[][] vKernel = { { 0, 0, 0 }, 
    { 1, 0, -1 }, 
    { 0, 0, 0 } };
  //image(img, 0, 0);
  PImage threshold = createImage(img.width, img.height, ALPHA);
  // clear the image

  PImage result = createImage(img.width, img.height, ALPHA);
  // clear the image
  for (int i = 0; i < img.width * img.height; i++) {
    result.pixels[i] = color(0);
  }

  for (int i = 0; i < img.width * img.height; i++) {
    if (hue(img.pixels[i]) < 160 || hue(img.pixels[i]) > 200) {
      threshold.pixels[i] = color(0);
    } else {
      threshold.pixels[i] = img.pixels[i];
    }
  }
  //image(threshold, 0, 0);

  float max=0;
  float[] buffer = new float[img.width * img.height];

  int a, b, c, d;
  for (int x = 0; x < img.width; x++) {
    if (x == 0) {
      a = 1;
      b = 2;
    } else if (x == img.width - 1) {
      a = 0;
      b = 1;
    } else {
      a = 0;
      b = 2;
    }
    for (int y = 0; y < img.height; y++) {
      if (y == 0) {
        c = 1;
        d = 2;
      } else if (y == img.height - 1) {
        c = 0;
        d = 1;
      } else {
        c = 0;
        d = 2;
      }
      int sum_h = 0;
      int sum_v = 0;
      for (int xMat = a; xMat <= b; xMat++) {
        for (int yMat = c; yMat <= d; yMat++) {
          int pos = (x + xMat - 1) + (y + yMat - 1) * img.width;
          //println(pos);
          sum_h += brightness(img.pixels[pos]) * hKernel[xMat][yMat];
          sum_v += brightness(img.pixels[pos]) * vKernel[xMat][yMat];
        }
      }
      float sum = sqrt((sum_h * sum_h) + (sum_v * sum_v));
      if (sum > max) {
        max = sum;
      }
      buffer[x + y * img.width] = sum;
    }
  }

  for (int y = 2; y < img.height - 2; y++) { // Skip top and bottom edges
    for (int x = 2; x < img.width - 2; x++) { // Skip left and right
      if (buffer[y * img.width + x] > (int)(max * 0.12f) && hue(threshold.pixels[y * img.width + x]) != hue(color(0))) { // 30% of the max
        result.pixels[y * img.width + x] = color(255);
      } else {
        result.pixels[y * img.width + x] = color(0);
      }
    }
  }

  return result;
}

PImage convolute(PImage img, float[][] kernel) {

  float weight = 1.f;
  // create a greyscale image (type: ALPHA) for output
  PImage result = createImage(img.width, img.height, ALPHA);

  int a, b, c, d;

  for (int x = 0; x < img.width; x++) {
    if (x == 0) {
      a = 1;
      b = 2;
    } else if (x == img.width - 1) {
      a = 0;
      b = 1;
    } else {
      a = 0;
      b = 2;
    }
    for (int y = 0; y < img.height; y++) {
      if (y == 0) {
        c = 1;
        d = 2;
      } else if (y == img.height - 1) {
        c = 0;
        d = 1;
      } else {
        c = 0;
        d = 2;
      }
      int brightness = 0;
      for (int xMat = a; xMat <= b; xMat++) {
        for (int yMat = c; yMat <= d; yMat++) {
          int pos = (x + xMat - 1) + (y + yMat - 1) * img.width;
          //println(pos);
          brightness += brightness(img.pixels[pos]) * kernel[xMat][yMat];
        }
      }
      brightness /= weight;
      if (brightness > 100) {
        result.pixels[x + y * img.width] = color(hue(img.pixels[x + y * img.width]), saturation(img.pixels[x + y * img.width]), 100);
      } else {
        result.pixels[x + y * img.width] = color(hue(img.pixels[x + y * img.width]), saturation(img.pixels[x + y * img.width]), brightness);
      }
    }
  }
  return result;
}

void hough(PImage edgeImg) {
  float discretizationStepsPhi = 0.06f;
  float discretizationStepsR = 2.5f;

  // dimensions of the accumulator
  int phiDim = (int) (Math.PI / discretizationStepsPhi);
  int rDim = (int) (((edgeImg.width + edgeImg.height) * 2 + 1) / discretizationStepsR);

  // our accumulator (with a 1 pix margin around)
  int[] accumulator = new int[(phiDim + 2) * (rDim + 2)];
  for (int i = 0; i < (phiDim + 2) * (rDim + 2); i++) {
    accumulator[i] = 0;
  }
  // Fill the accumulator: on edge points (ie, white pixels of the edge
  // image), store all possible (r, phi) pairs describing lines going
  // through the point.
  int truc = 0;
  for (int y = 0; y < edgeImg.height; y++) {
   for (int x = 0; x < edgeImg.width; x++) {
     // Are we on an edge?
     if (brightness(edgeImg.pixels[y * edgeImg.width + x]) != 0) {

       // ...determine here all the lines (r, phi) passing through
       // pixel (x,y), convert (r,phi) to coordinates in the
       // accumulator, and increment accordingly the accumulator.
       // Be careful: r may be negative, so you may want to center onto
       // the accumulator with something like: r += (rDim - 1) / 2

       for (int r = 0; r < rDim; r++) {
        for (int phi = 0; phi < phiDim; phi++) {
          int num = floor(x * cos(phi) + y * sin(phi));
          if (r == num) {
            accumulator[phi * rDim + r] += 1;
            //println(accumulator[phi * rDim + r]);
          }
        }
       }
       truc++;
       println(truc);
     }
   }
  }

  PImage houghImg = createImage(rDim + 2, phiDim + 2, ALPHA);
  for (int i = 0; i < accumulator.length; i++) {
    houghImg.pixels[i] = color(min(255, accumulator[i]));
  }
  // You may want to resize the accumulator to make it easier to see:
  houghImg.resize(400, 400);
  houghImg.updatePixels();
  image(houghImg, 800, 0);
}