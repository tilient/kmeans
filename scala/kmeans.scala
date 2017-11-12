// to run :
//   scala kmeans.scala
// or :
//   scalac kmeans.scala
//   scala Main

import math.sqrt
import scala.io.Source
import scala.util.parsing.json.JSON

object Main extends App
{
  def n          = 10
  def iters      = 15
  def iterations = 30

  case class Point(x: Double, y: Double)
  type Points = Array[Point]

  val points    : Points = readPoints("../points.json")
  var centroids : Points = Array.empty

  def readPoints(path: String): Points =
  {
    val json = Source.fromFile(path).mkString
    val data = JSON.parseFull(json)
    val list = data.get.asInstanceOf[List[List[Double]]]
    (list.map { case List(a, b) => Point(a, b) }).toArray
  }

  def closestCentroid(pt: Point): Point =
  {
    def sqr(d: Double): Double =
      d * d

    def distanceTo(c: Point): Double =
      sqrt(sqr(pt.x - c.x) + sqr(pt.y - c.y))

    var minIx = 0
    var minDist = distanceTo(centroids(0))
    var ix = 1
    while (ix < n)
    {
      val dist = distanceTo(centroids(ix))
      if (dist < minDist)
      {
        minDist = dist
        minIx = ix
      }
      ix += 1
    }
    centroids(minIx)
  }

  def average(pts: Points): Point =
  {
    var x = 0.0
    var y = 0.0
    for (pt <- pts)
    {
      x += pt.x
      y += pt.y
    }
    val l = pts.length
    Point(x / l, y / l)
  }

  def clusters(): Points =
  {
    (points groupBy closestCentroid)
      .values.map(average).toArray
  }

  def run()
  {
    centroids = points take n
    for (_ <- 1 to iters)
      centroids = clusters()
  }

  val start = System.currentTimeMillis
  for (_ <- 1 to iterations)
    run()
  val time = System.currentTimeMillis - start
  println(s"Average of ${time / iterations} milliseconds")
  centroids.foreach { println }
}
