
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
  import std.stdio;
  import std.datetime.stopwatch;

  Points points = readPoints("../points.json");
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

Points readPoints(in string filename)
{
  import std.json;
  import std.file;
  import std.algorithm.iteration: map;
  import std.array : array;

  return parseJSON(cast(char[])read(filename))
           .array()
           .map!(v => v.array())
           .map!(e => Point(e[0].floating,
                            e[1].floating))
           .array();
}

void run(ref Point[n] centroids,
         in Points points)
{
  import std.algorithm.iteration : map;
  import std.array : array;

  centroids[] = points[0 .. n];
  foreach (_; 0 .. iterations)
    centroids[] = points.cluster(centroids)
                        .map!(average).array()[];
}

pure
Points[] cluster(in Points points,
                 in Points centroids)
{
  Points[Point] clusters;
  foreach (pt; points)
    clusters[pt.closest(centroids)] ~= pt;
  return clusters.values();
}

pure
Point average(in Points pnts)
{
  import std.algorithm.iteration : reduce;

  return pnts.reduce!"a+b" / pnts.length;
}

// -----------------------------------------------

alias Points = Point[];

struct Point
{
	double x;
	double y;

  pure @nogc
  double norm() const
  {
    import core.math : sqrt;

  	return sqrt(x^^2 + y^^2);
  }

  pure @nogc
  double distance(in Point p) const {
    return (this - p).norm();
  }

  pure @nogc
  double squareDistance(in Point p) const {
    double dx = this.x - p.x;
    double dy = this.y - p.y;
    return dy^^2 + dy^^2;
  }

  pure @nogc
  Point opBinary(string op)(in Point pt) const
  {
    return mixin(
      "Point(x " ~op~ " pt.x, y " ~op~ " pt.y)");
  }

  pure @nogc
  Point opBinary(string op)(in ulong v) const
  {
    return mixin(
      "Point(x " ~op~ " v, y " ~op~ " v)");
  }

  pure @nogc
  Point closest(in Points choices) const
  {
    // import std.algorithm: minElement;
    // auto dist = &this.distance;
    // return choices.minElement!dist;
    size_t minIx;
    double minDist = double.max;
    foreach (ix, choice; choices) {
      double dist = this.squareDistance(choice);
      if (dist < minDist) {
        minIx = ix;
        minDist = dist;
      }
    }
    return choices[minIx];
  }

}

// -----------------------------------------------

