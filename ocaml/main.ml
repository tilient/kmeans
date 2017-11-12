type point = {x: float; y: float}

let ( ++ ) {x = x1; y = y1} {x = x2; y = y2} =
  {x = x1 +. x2; y = y1 +. y2}

let ( -- ) {x = x1; y = y1} {x = x2; y = y2} =
  {x = x1 -. x2; y = y1 -. y2}

let ( // ) {x; y} k =
  {x = x /. k; y = y /. k}

let norm {x; y} =
  sqrt (x *. x +. y *. y)

let dist x y =
  norm (x -- y)

let closest p (q::qs) =
  let rec closest_acc min_q min_dist = function
    | []       -> min_q
    | hd::tail -> let dst = dist p hd in
                  if dst < min_dist then
                    closest_acc hd dst tail
                  else
                    closest_acc min_q min_dist tail
  in
  closest_acc q (dist p q) qs

let average qs =
  let rec sum = function
    | []     -> (1, {x = 0.0; y = 0.0})
    | hd::tl -> let (cnt, sm) = sum tl in
                (cnt + 1, hd ++ sm) in
  let (cnt, sm) = sum qs in
  sm // (float_of_int cnt)

let clusters points centroids =
  let open Hashtbl in
  let table = create 16 in
  let add_to_closest pt =
    let lst = find table (closest pt centroids) in
    lst := (pt::(!lst))
  in
  let avg _ ptlst lst =
    (average !ptlst) :: lst
  in
  List.iter (fun pt -> add table pt (ref [])) centroids;
  List.iter add_to_closest points;
  fold avg table []

let rec take (hd::tl) = function
  | 0 -> []
  | n -> hd :: (take tl (n - 1))

let rec run points iters n =
  let rec run_acc centroids = function
    | 0   -> ()
    | itr -> run_acc (clusters points centroids) (itr - 1)
  in
  run_acc (take points n) iters

let read_points path =
  let read_point json =
    let open Yojson.Basic.Util in
    let [x; y] = List.map to_float (json |> to_list) in
    { x; y } in
  let json = Yojson.Basic.from_file path in
  let open Yojson.Basic.Util in
  let values = json |> to_list in
  List.map read_point values

let () =
  let runs = 10 in
  let points = read_points "../points.json" in
  let start = Sys.time() in
  for t = 1 to runs do
    run points 15 10
  done;
  let finish = Sys.time() in
  let milliseconds = (finish -.start) *. 1000.0 in
  Printf.printf "average of %f ms\n"
                (milliseconds /. (float_of_int runs))

