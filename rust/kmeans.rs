use std::mem;
use std::io::{BufReader,BufRead};
use std::fs::File;
use std::time::Instant;
use std::collections::HashMap;
use std::collections::hash_map::Entry::{Occupied, Vacant};
use std::hash::{Hash, Hasher};

/// Main ///////////////////////////////////////////////// ///

fn main() {
  let points = load_points();
  let start = Instant::now();
  for _ in 1 .. 30 {
    run(&points, 10, 15);
  }
  let centroids = run(&points, 10, 15);
  let elapsed = start.elapsed();
  let total_time = 1000.0 * elapsed.as_secs() as f64
                 + elapsed.subsec_nanos() as f64 * 1e-6;
  let iter_time = (total_time as u64) / 30;
  println!("The average time is {} ms", iter_time);
  for pt in centroids.iter() {
    println!("{}, {}", pt.0, pt.1);
  }
}

fn run(points: &Vec<Point>,
       n: usize, iters: u32) -> Vec<Point>{
  let mut centroids: Vec<Point> =
      points.iter().take(n).cloned().collect();
  for _ in 0 .. iters {
    centroids = clusters(points, &centroids)
                  .iter()
                  .map(|g| avg(&g))
                  .collect();
  }
  centroids
}

fn load_points() -> Vec<Point> {
  let mut points = Vec::new();
  let file = File::open("../points.txt").unwrap();
  for line in BufReader::new(file).lines() {
    let v = line.unwrap().split_whitespace()
       .filter_map(|s| s.parse::<f64>().ok())
       .collect::<Vec<_>>();
    points.push(Point(v[0], v[1]));
  }
  points
}

fn clusters(xs: &Vec<Point>,
            centroids: &Vec<Point>) -> Vec<Vec<Point>> {
  let mut groups: HashMap<Point, Vec<Point>> = HashMap::new();
  for x in xs.iter() {
    let y = x.closest(centroids);
    match groups.entry(y) {
      Occupied(e) => { e.into_mut().push(*x)  },
      Vacant(e)   => { e.insert(vec![*x]); () }
    }
  }
  groups.into_iter()
        .map(|(_, v)| v)
        .collect::<Vec<Vec<Point>>>()
}

/// Point //////////////////////////////////////////////// ///

#[derive(Debug, PartialEq, PartialOrd, Copy, Clone)]
struct Point(f64, f64);

impl Hash for Point
{
  fn hash<H: Hasher>(&self, state: &mut H) {
    let Point(x, y) = *self;
    let x: u64 = unsafe { mem::transmute(x) };
    let y: u64 = unsafe { mem::transmute(y) };
    x.hash(state);
    y.hash(state);
  }
}

impl Eq for Point {}

impl Point
{
  fn closest(&self, ys: &Vec<Point>) -> Point {
    let mut min_point = ys.first().unwrap();
    let mut min_dist = self.square_dist(min_point);
    for x in ys.iter() {
      let dist = self.square_dist(x);
      if dist < min_dist {
        min_dist = dist;
        min_point = x;
      }
    }
    min_point.clone()
  }

  fn square_dist(&self, w: &Point) -> f64 {
    let dx = self.0 - w.0;
    let dy = self.1 - w.1;
    dx * dx + dy * dy
  }
}

fn avg(points: &Vec<Point>) -> Point {
  let mut x = 0.0;
  let mut y = 0.0;
  for pt in points.iter() {
    x += pt.0;
    y += pt.1;
  }
  let k = points.len() as f64;
  Point(x / k, y / k)
}

