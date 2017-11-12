(use vector-lib srfi-4 srfi-1 srfi-69)

(define n 10)
(define iterations 15)

(define (load-points)
  (with-input-from-file "../points.txt"
    (lambda ()
      (let loop ((lst (list))
                 (x   (read)))
        (if (eof-object? x)
          lst
          (loop (cons (f64vector x (read)) lst) (read)))))))

(define (distance pt1 pt2)
  (let ([dx (fp- (f64vector-ref pt1 0) (f64vector-ref pt2 0))]
        [dy (fp- (f64vector-ref pt1 1) (f64vector-ref pt2 1))])
    (sqrt (fp+ (fp* dx dx) (fp* dy dy)))))

(define (point-add pt1 pt2)
  (f64vector
    (fp+ (f64vector-ref pt1 0) (f64vector-ref pt2 0))
    (fp+ (f64vector-ref pt1 1) (f64vector-ref pt2 1))))

(define (points-average points)
  (let ([sum-points   (fold point-add (f64vector 0.0 0.0) points)]
        [nr-of-points (exact->inexact (length points))])
    (f64vector
      (fp/ (f64vector-ref sum-points 0) nr-of-points)
      (fp/ (f64vector-ref sum-points 1) nr-of-points))))

(define (closest-centroid centroids point
               #!optional (min-dst maximum-flonum) min-centr)
  (if [null? centroids]
    min-centr
    (let* ([centr (car centroids)]
           [dst   (distance point centr)])
      (if (fp< dst min-dst)
        (closest-centroid (cdr centroids) point dst centr)
        (closest-centroid (cdr centroids) point min-dst min-centr)))))

(define (group-by-centroids points centroids
                            #!optional (groups (make-hash-table)))
  (if [null? points]
    groups
    (let ([point (car points)])
      (hash-table-update!/default
        groups
        (closest-centroid centroids point)
        (lambda (point-list) (cons point point-list))
        (list))
      (group-by-centroids (cdr points) centroids groups))))

(define (updated-centroids points centroids)
  (let ([groups (group-by-centroids points centroids)])
    (hash-table-map
      groups
      (lambda (_ points) (points-average points)))))

(define (print-points points)
  (for-each print points))

(define (calculate-centroids points)
  (let loop ([ix iterations]
             [centroids (take points n)])
    (if [fx> ix 0]
      (loop (fx- ix 1) (updated-centroids points centroids))
      centroids)))

(let ([points (load-points)])
  (print-points
    (time
      (let loop ([ix 10]
                 [centroids (take points n)])
        (if [fx> ix 0]
          (loop (fx- ix 1) (calculate-centroids points))
          centroids)))))

