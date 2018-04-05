import std.stdio;
import std.math;
import std.json;
import std.file;
import std.datetime.stopwatch;
import std.algorithm.iteration: map, reduce;
import std.array:array;

/* -----------------------------------------------
to compile:
ldc2 -O -release -mcpu=native main.d
gdc -O3 -o main main.d

----------------------------------------------- */

static immutable n = 10;
static immutable iterations = 15;
static immutable executions = 30;

void main()
{
  Point[] points = readPoints("../points.json");
  Point[n] centroids;

  StopWatch sw;
  sw.start();
  foreach (_; 0 .. executions)
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

void run(ref Point[n] centroids,
         Point[] points) {
  centroids[] = points[0 .. centroids.length];
  foreach (_; 0 .. iterations)
    centroids[] = points.cluster(centroids)
                    .map!(average).array()[];
}

 pure Point[][] cluster(Point[] points,
                  Point[] centroids) {
  Point[][Point] clusters;
  foreach (pt; points)
    clusters[pt.closest(centroids)] ~= pt;
  return clusters.values();
}

pure Point average(Point[] pnts) {
  return pnts.reduce!((a,b) => a+b) / pnts.length;
}

pure @nogc
Point closest(Point p, Point[] choices) {
  size_t minIx;
  double minDist = double.max;
  foreach (ix, choice; choices) {
    double dist = p.distance(choice);
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

  pure @nogc
  double norm() {
  	return sqrt(x*x + y*y);
  }

  pure @nogc
  double distance(Point p) {
    return (this - p).norm();
  }

  pure @nogc
  Point opBinary(string op)(Point pt) {
    return mixin(
      "Point(x " ~op~ " pt.x, y " ~op~ " pt.y)");
  }

  pure @nogc
  Point opBinary(string op)(ulong v) {
    return mixin(
      "Point(x " ~op~ " v, y " ~op~ " v)");
  }
}

// -----------------------------------------------

