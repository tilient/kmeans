;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; to compile:
;;   kawa -C kmeans_kawa_04.scm
;; to run:
;;   kawa kmeans
;;
;; to create a jar file:
;;   cp xxx/kawa-xxx.jar kmeans.jar
;;   kawa --main -C kmeans_kawa_04.scm
;;   jar ufe kmeans.jar kmeans *.class
;; to run:
;;   java -jar kmeans.jar
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define-syntax do-times
  (syntax-rules ()
    ((do-times (ix f .. t) . body)
     (let ((from :: int f)
           (to   :: int t))
       (do ((ix :: int from (+ 1 ix)))
           ((>= ix to))
         . body)))
    ((do-times (ix n) . body)
     (do-times (ix 0 .. n) . body))
    ((do-times (n) . body)
     (do-times (ix n) . body))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(module-name kmeans)

(define-alias PntArr Point[])
(define-alias ArrLst java.util.ArrayList)
(define-alias PntArrLst ArrLst[Point])
(define-alias HashMap java.util.HashMap)
(define-alias PntArrLstHM HashMap[Point PntArrLst])

(define-constant n     :: int 10)
(define-constant iters :: int 15)
(define-constant times :: int 30)

(define-simple-class Point ()
  (x :: double)
  (y :: double)

  ((add! (p :: Point)) :: void
    (set! x (+ x p:x))
    (set! y (+ y p:y)))

  ((div! (d :: double)) :: void
    (set! x (/ x d))
    (set! y (/ y d)))

  ((distance (p :: Point)) :: double
     (let ((xd :: double (- x p:x))
           (yd :: double (- y p:y)))
       (sqrt (+ (* xd xd) (* yd yd))))))

(define (average (points :: PntArrLst)) :: Point
  (let ((len :: int   (length points))
        (pnt :: Point (Point x: 0.0 y: 0.0)))
    (for-each pnt:add! points)
    (pnt:div! len)
    pnt))

(define (closest (pt :: Point) (choices :: PntArr)) :: int
  (let* ((min-ix   :: int    0)
         (min-dist :: double (pt:distance (choices min-ix)))
         (len      :: int    (length choices)))
    (do-times (ix 1 .. len)
      (let* ((choice :: Point  (choices ix))
             (dist   :: double (pt:distance choice)))
        (when (< dist min-dist)
          (set! min-ix ix)
          (set! min-dist dist))))
    min-ix))

(define (group-by (points :: PntArr)
                  (centroids :: PntArr)) :: PntArrLstHM
  (let ((groups     :: PntArrLstHM (PntArrLstHM))
        (points-len :: int         (length points)))
    (for-each
      (cut groups:put <> (PntArrLst points-len))
      centroids)
    (do-times (pix points-len)
      (let* ((pt  :: Point     (points pix))
             (cix :: int       (closest pt centroids))
             (ctr :: Point     (centroids cix))
             (lst :: PntArrLst (groups:get ctr)))
        (lst:add pt)))
    groups))

(define (run (points :: PntArr)) :: PntArr
  (let ((centroids (PntArr length: n)))
    (do-times (ix n)
      (set! (centroids ix) (points ix)))
    (do-times (iters)
      (let ((groups :: PntArrLstHM (group-by points centroids)))
        (do-times (ix n)
          (let* ((centr :: Point     (centroids ix))
                 (group :: PntArrLst (groups:get centr))
                 (avg   :: Point     (average group)))
          (set! (centroids ix) avg)))))
    centroids))

(define (load-point-list)
  (with-input-from-file "../points.txt"
    (lambda ()
      (let loop ((lst (list))
                 (x   (read)))
        (if (eof-object? x)
          lst
          (loop (cons (Point x: x y: (read)) lst)
                (read)))))))

(define (load-points) :: PntArr
  (let* ((point-list (load-point-list))
         (len        (length point-list))
         (points     (PntArr length: len)))
    (do ((ix  :: int 0 (+ 1 ix))
         (lst point-list (cdr lst)))
        ((= ix len) points)
      (set! (points ix) (car lst)))))

(define (printPoints points :: PntArr) :: void
  (for-each
    (lambda (point)
      (format #t "~A, ~A~%" point:x point:y))
    points))

(define (main) :: void
  (let ((points :: PntArr (load-points)))
    (do-times (4) (run points))
    (let ((fromTime :: double (current-second)))
      (do-times (times) (run points))
      (format #t
        "average time per iteration : ~A seconds~%"
        (/ (- (current-second) fromTime) times))
      (printPoints (run points)))))

(main)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
