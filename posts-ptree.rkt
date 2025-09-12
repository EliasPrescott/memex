#lang racket

(require threading pollen/pagetree)

(provide generate-ptree)

(define (post-paths)
  (find-files
    (λ (p) (string-suffix? (path->string p) "index.html.pm"))
    "posts/"))

(define (convert-path p)
  (~> p
      path->string
      (string-trim _ ".pm" #:left? #f)
      string->symbol))

(define (make-pt) `(pagetree-root
              ,@(map convert-path (post-paths))))

(define (generate-ptree)
  (let ([pt (make-pt)])
    (if (pagetree? pt)
        pt
        "failed to create valid pagetree")))
