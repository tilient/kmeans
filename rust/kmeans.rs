use std::hash::{Hash, Hasher};

//--- main ---------------------------------------------------

const TIMES: u64 = 30;
const ITERS: u64 = 15;
const NR_OF_CENTROIDS: usize = 10;

fn main()
{
  use std::time::Instant;

  let points = load_points();
  let start = Instant::now();
  for _ in 1 .. TIMES {
    run(&points);
  }
  let centroids = run(&points);
  let elapsed = start.elapsed();
  let total_time = 1000.0 * elapsed.as_secs() as f64
                 + elapsed.subsec_nanos() as f64 * 1e-6;
  println!("Average Time: {} ms",
           (total_time as u64) / TIMES);
  for pt in centroids.iter() {
    println!("(x: {}, y: {})", pt.0, pt.1);
  }
}

fn run(points: &Points) -> Points
{
  let mut centroids: Points =
    points.iter().take(NR_OF_CENTROIDS).cloned().collect();
  for _ in 0 .. ITERS {
    centroids = calc_centroids(points, &centroids)
  }
  centroids
}

fn calc_centroids(xs: &Points, centroids: &Points) -> Points
{
  use std::collections::HashMap;
  use std::collections::hash_map::Entry::{Occupied, Vacant};

  let mut groups: HashMap<_, RefPoints> = HashMap::new();
  for pt in xs.iter() {
    match groups.entry(pt.closest(centroids)) {
      Occupied(slot) => slot.into_mut().push(pt),
      Vacant(slot) => { slot.insert(vec![pt]); }
    }
  }
  groups.values().map(avg).collect()
}

//-- Point ---------------------------------------------------

#[derive(PartialEq, PartialOrd, Copy, Clone)]
struct Point(f64, f64);

const ZERO_POINT: Point = Point(0.0, 0.0);

impl Hash for Point
{
  fn hash<H: Hasher>(&self, state: &mut H)
  {
    use std::mem;

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
    let (dx, dy) = (self.0 - w.0, self.1 - w.1);
    dx * dx + dy * dy
  }

  fn add(self, other: &&Point) -> Point
  {
    Point(self.0 + other.0, self.1 + other.1)
  }

  fn div(self, k: f64) -> Point
  {
    Point(self.0 / k, self.1 / k)
  }
}

//-- Points --------------------------------------------------

type Points = Vec<Point>;
type RefPoints<'c> = Vec<&'c Point>;

fn avg(points: &RefPoints) -> Point
{
  points.iter()
    .fold(ZERO_POINT, Point::add)
    .div(points.len() as f64)
}

fn load_points() -> Points
{
  use std::fs::File;
  use std::io::{BufRead, BufReader};

  let mut points = Vec::new();
  let file = File::open("../points.txt").unwrap();
  for line in BufReader::new(file).lines() {
    let v = line.unwrap()
                .split_whitespace()
                .filter_map(|s| s.parse::<f64>().ok())
                .collect::<Vec<_>>();
    points.push(Point(v[0], v[1]));
  }
  points
}

//------------------------------------------------------------
