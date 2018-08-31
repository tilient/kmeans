/* -----------------------------------------------
ldc2 -betterC -O -release -mcpu=native mainB.d
----------------------------------------------- */

static immutable n = 10;
static immutable iterations = 15;
static immutable executions = 1_000;

static immutable nrOfPoints = 100_000;

alias Points = Point[nrOfPoints];
alias Centroids = Point[n];

@nogc
extern(C) void main()
{
  import core.stdc.stdio: printf;
  import core.stdc.time: time, difftime;

  Points points;
  Centroids centroids;

  points.readPoints();
  auto start = time(null);
  foreach (_; 0 .. executions)
    run(centroids, points);
  auto stop = time(null);
  auto totalTime = difftime(stop, start);

  printf("Average Time: %f ms.\n",
         1000.0 * totalTime / executions);
  foreach (ix, pt; centroids)
    printf("%d : (%f, %f)\n", ix, pt.x, pt.y);
}

@nogc
void readPoints(ref Points pts) {
  import core.stdc.stdio: fopen, fclose, fscanf;
  import std.string: toStringz;

  auto f = fopen("../points.txt", "r+");
  scope (exit) f.fclose();
  foreach (i; 0 .. pts.length) {
    float xx, yy;
    fscanf(f, "%f %f\n", &xx, &yy);
    pts[i].x = xx;
    pts[i].y = yy;
  }
}

pure @nogc
void run(ref Centroids centroids,
         ref Points points) {
  foreach (ix; 0 .. n)
    centroids[ix] = points[ix];
  foreach (_; 0 .. iterations) {
    Centroids cntrs;
    ulong[n]  cnts;
    cntrs[] = Point(0.0, 0.0);
    cnts[] = 0;
    foreach (ix, pt; points) {
      ix = pt.closest(centroids);
      cnts[ix]++;
      cntrs[ix] = cntrs[ix] + pt;
    }
    foreach(i, ref c; centroids)
      c = cntrs[i] / cnts[i];
  }
}

pure @nogc
size_t closest(Point p, ref Centroids choices) {
  size_t minIx;
  double minDist = double.max;
  foreach (ix, choice; choices) {
    double dist = p.distance2(choice);
    if (dist < minDist) {
      minIx = ix;
      minDist = dist;
    }
  }
  return minIx;
}

// -----------------------------------------------

struct Point {
	double x;
	double y;

  pure @nogc
  double norm2() {
  	return x*x + y*y;
  }

  pure @nogc
  double distance2(Point p) {
    return (this - p).norm2();
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

