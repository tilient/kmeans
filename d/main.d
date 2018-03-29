import std.stdio;
import std.math;
import std.json;
import std.file;
import std.datetime.stopwatch;
import std.algorithm.iteration: map, fold;
import std.array:array;

/* -----------------------------------------------
to compile:
ldc2 -O -release -mcpu=native main.d
----------------------------------------------- */

immutable n = 10;
immutable iterations = 15;
immutable executions = 30;

void main()
{
  Point[n] centroids;
  Point[] points = readPoints("../points.json");

  StopWatch sw;
  sw.start();
  foreach (i; 0 .. executions)
    run(centroids, points);
  sw.stop();

  writefln("Average Time: %s ms. ",
           sw.peek.total!"msecs" / executions);
  foreach (ix, pt; centroids)
    writefln("%s : %s", ix, pt);
}

Point[] readPoints(string filename) {
  return parseJSON(cast(char[])read(filename))
           .array()
           .map!(v => v.array())
           .map!(e => Point(e[0].floating,
                            e[1].floating))
           .array();
}

void run(ref Point[n] centroids, Point[] points) {
  centroids[] = points[0 .. centroids.length];
  foreach (i; 0 .. iterations)
    centroids[] = clusters(points, centroids)
                    .map!(average)
                    .array()[];
}

Point[][] clusters(Point[] points,
                   Point[] centroids) {
  Point[][Point] hm;
  foreach (pt; points)
    hm[pt.closest(centroids)] ~= pt;
  return hm.values();
}

Point average(Point[] points) {
  return points.fold!(add).div(points.length);
}

Point closest(Point p, Point[] choices) {
  size_t minIx;
  double minDist = double.max;
  foreach (ix, choice; choices) {
    double dist = distance(p, choice);
    if (dist < minDist) {
      minIx = ix;
      minDist = dist;
    }
  }
  return choices[minIx];
}

// -----------------------------------------------

struct Point {
	double x;
	double y;
}

Point add(Point p1, Point p2) {
	return Point(p1.x + p2.x, p1. y + p2.y);
}

Point sub(Point p1, Point p2) {
	return Point(p1.x - p2.x, p1.y - p2.y);
}

Point div(Point p, double d) {
	return Point(p.x/d, p.y/d);
}

double norm(Point p) {
	return sqrt((p.x * p.x) + (p.y * p.y));
}

double distance(Point p1, Point p2) {
  return p1.sub(p2).norm();
}

// -----------------------------------------------


