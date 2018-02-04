package main

import (
	"encoding/json"
	"flag"
	"fmt"
	"log"
	//"math"
	"os"
	"runtime/pprof"
	"time"
)

const (
	n          = 10
	iterations = 15
	executions = 30
)

type (
	point struct {
		x, y float64
	}

	clusterMap map[*point][]point
)

func (p1 *point) add(p2 point) {
	p1.x += p2.x
	p1.y += p2.y
}

func (p1 *point) divide(d float64) {
	p1.x /= d
	p1.y /= d
}

func (p1 *point) dist(p2 *point) float64 {
	dx := p1.x - p2.x
	dy := p1.y - p2.y
	//return math.Sqrt(dx*dx + dy*dy)
	return dx*dx + dy*dy
}

func (average *point) average(points []point) {
	average.x, average.y = 0, 0
	for _, point := range points {
		average.add(point)
	}
	average.divide(float64(len(points)))
}

func (rp *point) closest(choices []point) *point {
	minIx := 0
	minDist := rp.dist(&choices[minIx])
	for ix := 1; ix < len(choices); ix++ {
		dist := rp.dist(&choices[ix])
		if dist < minDist {
			minDist = dist
			minIx = ix
		}
	}
	return &choices[minIx]
}

func clusters(xs, centroids []point) clusterMap {
	clusters := make(clusterMap)
	for _, x := range xs {
		closest := x.closest(centroids)
		clusters[closest] = append(clusters[closest], x)
	}
	return clusters
}

func mainLoop(xs []point) []point {
	centroids := make([]point, 0, n)
	for i := 0; i < executions; i++ {
		centroids = centroids[:0]
		for j := 0; j < n; j++ {
			centroids = append(centroids, xs[j])
		}
		for j := 0; j < iterations; j++ {
			clusters := clusters(xs, centroids)
			for k := 0; k < len(centroids); k++ {
				centroid := &centroids[k]
				centroid.average(clusters[centroid])
			}
		}
	}
	return centroids
}

func readPoints(filename string) []point {
	xs := make([]point, 0)

	file, err := os.Open(filename)
	if err != nil {
		log.Fatal(err)
	}
	defer file.Close()

	dec := json.NewDecoder(file)

	_, err = dec.Token()
	if err != nil {
		log.Fatal(err)
	}

	var coords [2]float64
	for dec.More() {
		err := dec.Decode(&coords)
		if err != nil {
			log.Fatal(err)
		}
		xs = append(xs, point{coords[0], coords[1]})
	}

	_, err = dec.Token()
	if err != nil {
		log.Fatal(err)
	}

	return xs
}

var cpuprofile = flag.String(
	"cpuprofile", "", "write cpu profile to file")

func main() {
	xs := readPoints("../points.json")
	flag.Parse()
	if *cpuprofile != "" {
		f, err := os.Create(*cpuprofile)
		if err != nil {
			log.Fatal(err)
		}
		pprof.StartCPUProfile(f)
		defer pprof.StopCPUProfile()
	}
	start := time.Now()
	centroids := mainLoop(xs)
	d := time.Now().Sub(start)
	fmt.Printf("average time is %v ms\n",
		1000*d.Seconds()/executions)
	for _, p := range centroids {
		fmt.Printf("%v\n", p)
	}
}
