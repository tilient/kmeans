// to run :
//   scala kmeans.scala
// or :
//   scalac kmeans.scala
//   scala Main

import math.sqrt
import scala.io.Source
import scala.util.parsing.json.JSON
import scala.collection.parallel.mutable.ParArray

object Main extends App
{
  def n          = 10
  def iters      = 15
  def iterations = 30

  case class Point(x: Double, y: Double)
  {
    def /(k: Double): Point =
      new Point(x / k, y / k)

    def +(p: Point) =
      new Point(x + p.x, y + p.y)

    def distanceTo(c: Point): Double =
      sqrt(sqr(x - c.x) + sqr(y - c.y))
  }

  type Points = ParArray[Point]
  type Centroids = Array[Point]

  val points    : Points = readPoints("../points.json")
  var centroids : Centroids = Array.empty

  def sqr(d: Double): Double =
    d * d

  def readPoints(path: String): Points =
  {
    val json = Source.fromFile(path).mkString
    val data = JSON.parseFull(json)
    val list = data.get.asInstanceOf[List[List[Double]]]
    (list.map { case List(a, b) => Point(a, b) }).toParArray
  }

  def closestCentroid(pt: Point): Point =
    centroids.minBy(pt.distanceTo)

  def average(pts: Points): Point =
    pts.reduce(_+_) / pts.length

  def clusters(): Centroids =
    (points groupBy closestCentroid)
      .values.map(average(_)).toArray

  def run()
  {
    centroids = (points take n).toArray
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
