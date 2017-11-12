import math, hashes, tables, sequtils, times, json, strutils

const
  n          = 10
  iterations = 15
  executions = 30
  filename   = "../points.json"

type
  Point     = tuple[x, y: float]
  Points    = seq[Point]
  Centroids = array[n, Point]

proc hash(p: Point): Hash {.noInit.} =
  !$(p.x.hash !& p.y.hash)

proc `+`(p, q: Point): Point {.noInit.} =
  (p.x + q.x, p.y + q.y)

proc `-`(p, q: Point): Point {.noInit.} =
  (p.x - q.x, p.y - q.y)

proc `/`(p: Point, k: float): Point {.noInit.} =
  (p.x / k, p.y / k)

proc `/`(p: Point, n: int): Point {.noInit.} =
  p / float(n)

proc norm(p: Point): float {.noInit.} =
  sqrt(p.x * p.x + p.y * p.y)

proc distance(p, q: Point): float {.noInit.} =
  norm(p - q)

proc closest(p: Point, centroids: Centroids): Point {.noInit.} =
  var minDist = Inf
  for centroid in centroids:
    let d = p.distance(centroid)
    if d < minDist:
      minDist = d
      result = centroid

proc groupBy(points: Points,
             centroids: Centroids): Table[Point,Points] =
  result = initTable[Point, Points]()
  for c in centroids:
    result[c] = @[]
  for point in points:
    let centroid = point.closest(centroids)
    result[centroid].add(point)

proc average(points: Points): Point =
  foldl(points, a + b) / points.len

proc update(centroids: var Centroids, points: Points) =
  let groups: Table[Point, Points] = points.groupBy(centroids)
  var ix = 0
  for group in groups.values:
    centroids[ix] = group.average()
    ix += 1

proc calculate(centroids: var Centroids, points: Points) =
  for ix in centroids.low .. centroids.high:
    centroids[ix] = points[ix]
  for _ in 1 .. iterations:
    centroids.update(points)

proc loadPoints(): Points =
  result = newSeq[Point]()
  for pt in parseFile(filename).items:
    result.add((x: pt[0].fnum, y: pt[1].fnum))

proc main() =
  let points = loadPoints()
  var centroids : array[n, Point]
  let start = cpuTime()
  for _ in 1 .. executions:
    centroids.calculate(points)
  let seconds = cpuTime() - start
  let time = ((seconds * 1000) / float(executions)).round
  echo format("Made $1 executions with an average of $2 miliseconds",
              executions, time)
  for centroid in centroids:
    echo centroid

when isMainModule:
  main()
