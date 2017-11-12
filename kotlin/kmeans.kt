#!/usr/bin/env kscript

//--------------------------------------------------------------------
//-- to compile:
//--   kotlinc -cp jackson.jar -d classes kmeans.kt
//-- to run:
//--   kotlin -cp classes:jackson.jar KmeansKt
//---------
//-- with kscript: ./kmeans.kt 
//-- or kscript https://git.io/vFrnS
//--------------------------------------------------------------------

//DEPS com.fasterxml.jackson.core:jackson-core:2.4.4
//DEPS com.fasterxml.jackson.core:jackson-databind:2.4.4

import java.io.File
import com.fasterxml.jackson.core.type.TypeReference
import com.fasterxml.jackson.databind.ObjectMapper

import java.lang.Math
import java.awt.Color
import java.awt.image.BufferedImage
import javax.imageio.ImageIO

//--------------------------------------------------------------------
//-- Constants -------------------------------------------------------
//--------------------------------------------------------------------

val N = 10
val times = 15
val iterations = 30

//--------------------------------------------------------------------
//-- Tools -----------------------------------------------------------
//--------------------------------------------------------------------

fun <T> millisToRun(thunk: () -> T): Pair<T,Long>
{
  val start = System.currentTimeMillis()
  val result = thunk()
  val time = System.currentTimeMillis() - start
  return Pair(result, time)
}

// specialized (and faster) version of 'minBy'
fun <V, T: Collection<V>> T.minBy(selector: (pt: V) -> Double): V
{
  var minE = this.first()
  var minV = Double.MAX_VALUE
  for (e in this) {
    val v = selector(e)
    if (v < minV) {
      minV = v
      minE = e
    }
  }
  return minE
}

//--------------------------------------------------------------------
//-- Point -----------------------------------------------------------
//--------------------------------------------------------------------

data class Point(val x: Double, val y: Double)
{
  operator fun plus(pt: Point) =
    Point(this.x + pt.x, this.y + pt.y)

  operator fun div(d: Double) =
    Point(this.x / d, this.y / d)

  fun distanceTo(pt: Point): Double
  {
    val x = this.x - pt.x
    val y = this.y - pt.y
    return Math.sqrt((x * x) + (y * y))
  }
}

//--------------------------------------------------------------------
//-- Points ----------------------------------------------------------
//--------------------------------------------------------------------

typealias Points = List<Point>

fun Points.closestTo(pt: Point) =
  this.minBy(pt::distanceTo)

fun Points.average(): Point =
  this.reduce(Point::plus) / this.size.toDouble()

//--------------------------------------------------------------------
//--- Plot -----------------------------------------------------------
//--------------------------------------------------------------------

fun plot(points: Points, centroids: Points, K: Int = 1024)
{
  val xs = points.map { it.x }
  val ys = points.map { it.y }
  val minX = xs.min() ?: 0.0
  val minY = ys.min() ?: 0.0
  val δX = (xs.max() ?: 0.0) - minX
  val δY = (ys.max() ?: 0.0) - minY
  val κX = Math.floor(K / δX).toInt()
  val κY = Math.floor(K / δY).toInt()

  val img = BufferedImage(K + 20, K + 20, BufferedImage.TYPE_INT_RGB)
  var ix = 0
  for (pts in points.groupBy(centroids::closestTo).values) {
    val c = Color.getHSBColor(ix.toFloat() / N, 1.0f, 1.0f).getRGB()
    ix += 1
    for (pt in pts) {
      val x = (10 + κX * (pt.x - minX)).toInt()
      val y = (10 + κY * (pt.y - minY)).toInt()
      img.setRGB(x, y, c)
    }
  }
  for (n in 1 .. N) {
    val c = Color.getHSBColor(n.toFloat() / N, 1.0f, 1.0f).getRGB()
    for (x in 0 .. 100) {
      for (y in (n * 20) .. ((n + 1) * 20)) {
        img.setRGB(x, y, c)
      }
    }
  }
  val f = File("imgs/ttt.png")
  ImageIO.write(img, "PNG", f)
}

//--------------------------------------------------------------------
//-- Main ------------------------------------------------------------
//--------------------------------------------------------------------


fun readPoints(path: String): Points
{
  val mapper = ObjectMapper()
  val typeref = object : TypeReference<List<List<Double>>>() {}
  val list = mapper.readValue<List<List<Double>>>(File(path), typeref)
  return list.map { Point(it[0], it[1]) }
}

fun run(points: Points): Points =
  (1 .. times).fold( points.take(N) ) { centroids, ix ->
    points.groupBy(centroids::closestTo)
          .values
          .map(Points::average)
  }

fun main(args: Array<String>)
{
  val points = readPoints("../points.json")
  val (centroids, time) = millisToRun {
    (2 .. iterations).forEach { run(points) }
    run(points)
  }
  print("ran $iterations iterations, ")
  println("average of ${time / iterations} milliseconds.")
  plot(points, centroids)
  centroids.forEach(::println)
}

//--------------------------------------------------------------------
