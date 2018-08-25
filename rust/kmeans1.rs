use std::collections::hash_map::Entry::{Occupied, Vacant};
use std::collections::HashMap;
use std::fs::File;
use std::hash::{Hash, Hasher};
use std::io::{BufRead, BufReader};
use std::mem;
use std::time::Instant;
use std::ops::Add;

//--- main ---------------------------------------------------

fn main()
{
  let points = load_points();
  let start = Instant::now();
  for _ in 1..30 {
    run(&points, 10, 15);
  }
  let centroids = run(&points, 10, 15);
  let elapsed = start.elapsed();
  let total_time = 1000.0 * elapsed.as_secs() as f64
                 + elapsed.subsec_nanos() as f64 * 1e-6;
  let iter_time = (total_time as u64) / 30;
  println!("The average time is {} ms", iter_time);
  for pt in centroids.iter() {
    println!("(x: {}, y: {})", pt.0, pt.1);
  }
}

fn run(points: &Points, n: usize, iters: u32) -> Points
{
  let mut centroids: Points =
    points.iter().take(n).cloned().collect();
  for _ in 0..iters {
    centroids = clusters(points, &centroids).iter()
                  .map(avg).collect();
  }
  centroids
}

fn clusters<'a>(xs: &'a Points, centroids: &Points)
   -> Vec<RefPoints<'a>>
{
  let mut groups: HashMap<_, RefPoints> = HashMap::new();
  for pt in xs.iter() {
    match groups.entry(pt.closest(centroids)) {
      Occupied(slot) => slot.into_mut().push(pt),
      Vacant(slot) => { slot.insert(vec![pt]); }
    }
  }
  groups.values().cloned().collect()
}

//-- Point ---------------------------------------------------

#[derive(Debug, PartialEq, PartialOrd, Copy, Clone)]
struct Point(f64, f64);

impl Hash for Point
{
  fn hash<H: Hasher>(&self, state: &mut H)
  {
    let x: u64 = unsafe { mem::transmute(self.0) };
    let y: u64 = unsafe { mem::transmute(self.1) };
    x.hash(state);
    y.hash(state);
  }
}

impl Eq for Point {}

impl Point
{
  fn closest<'a>(&self, ys: &'a Points) -> &'a Point
  {
    let min_point = ys.first().unwrap();
    let min_dist = self.square_dist(min_point);
    ys.iter().fold((min_dist, min_point), |(md, mp), pt| {
      let dist = self.square_dist(pt);
      if dist < md { (dist, pt) } else { (md, mp) }
    }).1
  }

  fn square_dist(&self, w: &Point) -> f64
  {
    let dx = self.0 - w.0;
    let dy = self.1 - w.1;
    dx * dx + dy * dy
  }
}

impl Add for Point {
  type Output = Point;

  fn add(self, other: Point) -> Point {
    Point(self.0 + other.0, self.1 + other.1)
  }
}

//-- Points --------------------------------------------------

type Points = Vec<Point>;
type RefPoints<'c> = Vec<&'c Point>;

fn avg(points: &RefPoints) -> Point
{
  let Point(x, y) =
    points.iter().fold(Point(0.0, 0.0), |p, &&q| p + q);
  let k = points.len() as f64;
  Point(x / k, y / k)
}

fn load_points() -> Points
{
  let mut points = Vec::new();
  let file = File::open("../points.txt").unwrap();
  for line in BufReader::new(file).lines() {
    let v = line
      .unwrap()
      .split_whitespace()
      .filter_map(|s| s.parse::<f64>().ok())
      .collect::<Vec<_>>();
    points.push(Point(v[0], v[1]));
  }
  points
}

//------------------------------------------------------------
