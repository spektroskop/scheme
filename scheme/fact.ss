(define (fact n)
  (let loop ((m 1) (n n))
    (if (= n 0) m
      (loop (* n m) (- n 1)))))

