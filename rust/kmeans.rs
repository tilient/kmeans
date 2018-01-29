// extern crate time;
// extern crate serde;
// extern crate serde_json;
// #[macro_use]
// extern crate serde_derive;
//
// use std::path::Path;
// use std::fs::File;
// use std::io::Read;
// use std::collections::hash_map::Entry::{Occupied, Vacant};
// use std::ops::{Add, Sub};
//
// use time::now;


use std::mem;
use std::io::{BufReader,BufRead};
use std::fs::File;
use std::time::Instant;
use std::collections::HashMap;
use std::hash::{Hash, Hasher};

/// Main ///////////////////////////////////////////////// ///

fn main() {
  let points = load_points();
  println!("{:?}", points.len());
  let iterations = 100;
  let start = Instant::now();
  for _ in 0 .. iterations {
    run(&points, 10, 15);
  }
  let elapsed = start.elapsed();
  let total_time = elapsed.as_secs() as f64
                 + elapsed.subsec_nanos() as f64 * 1e-9;
  let iter_time = total_time / (iterations as f64);
  println!("The average time is {}", iter_time);
}

fn run(points: &Vec<Point>, n: usize, iters: u32) {
  let mut centroids: Vec<Point> =
      points.iter().take(n).cloned().collect();
//
//     for _ in 0..iters {
//         centroids = clusters(points, &centroids)
//             .iter()
//             .map(|g| avg(&g))
//             .collect();
//     }
//     clusters(points, &centroids)
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
  for x in centroids.iter() {
    groups.insert(*x, Vec::new());
  }

  for x in xs.iter() {
    let y = x.closest(centroids);
    match groups.get(&y) {
      Some(v) => v.into_mut().push(*x),
      _ => println!("ERROR"),
    }
//
//        // Notable change: avoid double hash lookups
//        match groups.entry(y) {
//            Occupied(entry) => entry.into_mut().push(*x),
//            Vacant(entry) => {
//                entry.insert(vec![*x]);
//                ()
//            }
//        }
  }

  groups.into_iter()
        .map(|(_, v)| v)
        .collect::<Vec<Vec<Point>>>()
}

/// Point //////////////////////////////////////////////// ///

#[derive(Debug, PartialEq, PartialOrd, Copy, Clone)]
struct Point(f64, f64);

impl Hash for Point {
  fn hash<H: Hasher>(&self, state: &mut H) {
    let Point(x, y) = *self;
    let x: u64 = unsafe { mem::transmute(x) };
    let y: u64 = unsafe { mem::transmute(y) };
    x.hash(state);
    y.hash(state);
  }
}

impl Eq for Point {}

impl Point {
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

//
// fn avg(points: &[Point]) -> Point {
//     let Point(x, y) = points.iter().fold(Point(0.0, 0.0), |p, &q| p + q);
//     let k = points.len() as f64;
//
//     Point(x / k, y / k)
// }
//
// fn closest(x: Point, ys: &[Point]) -> Point {
//     let y0 = ys[0];
//     let d0 = dist(y0, x);
//     let (_, y) = ys.iter()
//         .fold((d0, y0), |(m, p), &q| {
//             let d = dist(q, x);
//             if d < m { (d, q) } else { (m, p) }
//         });
//     y
// }
//
//
// fn sq(x: f64) -> f64 {
//     x * x
// }
//
// impl Point {
//     pub fn norm(self: &Point) -> f64 {
//         (sq(self.0) + sq(self.1)).sqrt()
//     }
// }
//
//
// impl Add for Point {
//     type Output = Point;
//
//     fn add(self, other: Point) -> Point {
//         Point(self.0 + other.0, self.1 + other.1)
//     }
// }
//
// impl Sub for Point {
//     type Output = Point;
//
//     fn sub(self, other: Point) -> Point {
//         Point(self.0 - other.0, self.1 - other.1)
//     }
// }
//
// impl Eq for Point {}
//
