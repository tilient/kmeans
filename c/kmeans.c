#include <sys/time.h>
#include <jansson.h>
#include <string.h>
#include <math.h>

/*
 * to install libjansson:
sudo apt-get install libjansson-dev
 * to compile:
clang -Wall -O3 -o kmeans kmeans.c -ljansson -lm
 * to run:
 *   ./kmeans
 */

// -------------------------------------------------------------------
// Point
// -------------------------------------------------------------------

typedef struct {
  double x;
  double y;
} Point;

inline long hash(Point pt)
{
  return (long)(pt.x * 123405567891.0) ^ (long)(pt.y * 109874654321.0);
}

inline double square_dist(Point p1, Point p2)
{
  Point p = {p1.x - p2.x, p1.y - p2.y};
  return (p.x * p.x) + (p.y * p.y);
}

inline double dist(Point p1, Point p2)
{
  Point p = {p1.x - p2.x, p1.y - p2.y};
  return sqrt((p.x * p.x) + (p.y * p.y));
}

inline void addToPoint(Point* p1, Point p2)
{
  p1->x += p2.x;
  p1->y += p2.y;
}

inline Point divPoint(Point p, int i)
{
  Point pt = {p.x / i, p.y / i};
  return pt;
}

// -------------------------------------------------------------------
// PointList
// -------------------------------------------------------------------

typedef struct {
  int    len;
  int    maxlen;
  Point* lst;
} PointList;

void initPointList(PointList* lst)
{
  lst->len = 0;
  lst->maxlen = 0;
  lst->lst = NULL;
}

void pointListAdd(PointList* lst, Point pt);

void initPointListOfLen(PointList* lst, int len)
{
  Point pt = {0.0, 0.0};
  int i;

  initPointList(lst);
  for (i = 0; i < len; ++i)
    pointListAdd(lst, pt);
}

void termPointList(PointList* lst)
{
  if (lst->lst != NULL)
    free(lst->lst);
  lst->len = 0;
  lst->maxlen = 0;
  lst->lst = NULL;
}

inline void growPointList(PointList* lst)
{
  lst->maxlen += 8192;
  lst->lst = realloc(lst->lst, (lst->maxlen * sizeof(Point)));
  if (lst->lst == NULL)
    printf ("ERROR : could not realloc.\n");
}

inline void growPointListIfNeed(PointList* lst)
{
  if (lst->len >= lst->maxlen)
    growPointList(lst);
}

void pointListAdd(PointList* lst, Point pt)
{
  growPointListIfNeed(lst);
  lst->lst[lst->len] = pt;
  lst->len += 1;
}

inline Point pointListAt(PointList* lst, int ix)
{
  return lst->lst[ix];
}

inline void pointListAtPut(PointList* lst, int ix, Point pt)
{
  lst->lst[ix] = pt;
}

#define min(X, Y) (((X) < (Y)) ? (X) : (Y))

inline void pointListCopy(PointList* toList, PointList* fromList)
{
  int len = sizeof(Point) * min(toList->len, fromList->len);
  memcpy(toList->lst, fromList->lst, len);
}

Point pointListAverage(PointList* lst)
{
  Point pt = {0.0, 0.0};
  int ix;
  int len = lst->len;

  for (ix = 0; ix < len; ++ix)
    addToPoint(&pt, pointListAt(lst, ix));
  return divPoint(pt, lst->len);
}

// -------------------------------------------------------------------
// Hash Table
// -------------------------------------------------------------------

#define HashMapSize 128

typedef struct HashEntry {
  long      key;
  PointList lst;
} HashEntry;

typedef HashEntry HashMap[HashMapSize];

inline void initHashMap(HashMap map)
{
  memset(map, 0, HashMapSize * sizeof(HashEntry));
}

inline int findHashPos(HashMap map, long key)
{
  int hash = (key % HashMapSize);
  while (map[hash].key != 0 && map[hash].key != key)
    hash = (hash + 1) % HashMapSize;
  return hash;
}

PointList* hashMapGet(HashMap map, long key) {
  int hash = findHashPos(map, key);
  if (map[hash].key == 0)
    return NULL;
  return &map[hash].lst;
}

void hashMapPutEmpty(HashMap map, long key) {
  int hash = findHashPos(map, key);
  map[hash].key = key;
  initPointList(&map[hash].lst);
}

void hashMapPut(HashMap map, long key, PointList lst) {
  int hash = findHashPos(map, key);
  map[hash].key = key;
  map[hash].lst = lst;
}

// -------------------------------------------------------------------
// K-Means
// -------------------------------------------------------------------

void readPoints(PointList* points)
{
  json_t*      json;
  json_error_t error;
  size_t       index;
  json_t*      value;

  json = json_load_file("../points.json", 0, &error);
  if (json) {
    json_array_foreach(json, index, value) {
      Point pt = {json_number_value(json_array_get(value,0)),
                  json_number_value(json_array_get(value,1))};
      pointListAdd(points, pt);
    }
  }
}

// -------------------------------------------------------------------

Point closestCentroid(Point point, PointList* centroids)
{
  double minDist = 1.0 / 0.0;
  Point  result;
  int    clen = centroids->len;
  int    ix;

  for (ix = 0; ix < clen; ++ix) {
    Point centroid = pointListAt(centroids, ix);
    double d = square_dist(point, centroid);
    if (d < minDist) {
       minDist = d;
       result = centroid;
    }
  }
  return result;
}

void buildClusters(HashMap clusterMap,
                   PointList* points, PointList* centroids)
{
  int ix;
  int clen = centroids->len;
  int plen = points->len;

  for (ix = 0; ix < clen; ++ix)
    hashMapPutEmpty(clusterMap, hash(pointListAt(centroids, ix)));

  for (ix = 0; ix < plen; ++ix) {
    Point point    = pointListAt(points, ix);
    Point centroid = closestCentroid(point, centroids);
    pointListAdd(hashMapGet(clusterMap, hash(centroid)), point);
  }
}

void updateCentroids(PointList* points, PointList* centroids)
{
  int     ix;
  int     clen = centroids->len;
  HashMap clusterMap;

  initHashMap(clusterMap);
  buildClusters(clusterMap, points, centroids);
  for (ix = 0; ix < clen; ++ix)
  {
    Point centroid = pointListAt(centroids, ix);
    PointList* lst = hashMapGet(clusterMap, hash(centroid));
    pointListAtPut(centroids, ix, pointListAverage(lst));
    termPointList(lst);
  }
}

void calculateCentroids(PointList* points, PointList* centroids,
                        int nrOfIterations)
{
  int ix;

  pointListCopy(centroids, points);
  for (ix = 0; ix < nrOfIterations; ++ix)
    updateCentroids(points, centroids);
}

// -------------------------------------------------------------------
// Main Benchmark
// -------------------------------------------------------------------

void printCentroids(PointList* centroids)
{
  int ix;
  int clen = centroids->len;

  for (ix = 0; ix < clen ; ++ix) {
    Point pt = pointListAt(centroids, ix);
    printf("(%2.16f, %2.16f) \n", pt.x, pt.y);
  }
}

int main()
{
  int nrOfCentroids  = 10;
  int nrOfIterations = 15;
  int times          = 30;

  PointList points;
  PointList centroids;
  struct    timeval tv_before;
  struct    timeval tv_after;
  int       i;

  initPointList(&points);
  readPoints(&points);
  initPointListOfLen(&centroids, nrOfCentroids);

  gettimeofday(&tv_before, NULL);
  for (i = 0; i < times; ++i)
    calculateCentroids(&points, &centroids, nrOfIterations);
  gettimeofday(&tv_after, NULL);

  printCentroids(&centroids);
  double avg_time =
    (((double) (tv_after.tv_usec - tv_before.tv_usec) / 1000) +
     ((double) (tv_after.tv_sec - tv_before.tv_sec) * 1000)) / times;
  printf ("Average time = %f miliseconds\n", avg_time);

  termPointList(&points);
  termPointList(&centroids);
  return 0;
}

// -------------------------------------------------------------------
