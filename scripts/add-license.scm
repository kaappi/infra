(import (scheme base)
        (scheme write)
        (scheme file)
        (scheme process-context)
        (scheme time))

(define (current-year)
  (let* ((secs (current-second))
         (days (exact (floor (/ secs 86400))))
         (year (let loop ((y 1970) (d days))
                 (let ((yd (if (and (= (modulo y 4) 0)
                                    (or (not (= (modulo y 100) 0))
                                        (= (modulo y 400) 0)))
                               366 365)))
                   (if (< d yd)
                       y
                       (loop (+ y 1) (- d yd)))))))
    (number->string year)))

(define (read-template path)
  (call-with-input-file path
    (lambda (port)
      (let loop ((lines '()))
        (let ((line (read-line port)))
          (if (eof-object? line)
              (string-join (reverse lines) "\n")
              (loop (cons line lines))))))))

(define (string-join lst sep)
  (if (null? lst) ""
      (let loop ((rest (cdr lst)) (acc (car lst)))
        (if (null? rest) acc
            (loop (cdr rest)
                  (string-append acc sep (car rest)))))))

(define (string-replace-all s old new)
  (let ((old-len (string-length old)))
    (let loop ((i 0) (acc ""))
      (if (> (+ i old-len) (string-length s))
          (string-append acc (substring s i (string-length s)))
          (if (string=? (substring s i (+ i old-len)) old)
              (loop (+ i old-len) (string-append acc new))
              (loop (+ i 1) (string-append acc (string (string-ref s i)))))))))

(define (path-join a b)
  (if (and (> (string-length a) 0)
           (char=? (string-ref a (- (string-length a) 1)) #\/))
      (string-append a b)
      (string-append a "/" b)))

(define (dirname path)
  (let loop ((i (- (string-length path) 1)))
    (cond
      ((< i 0) ".")
      ((char=? (string-ref path i) #\/) (substring path 0 i))
      (else (loop (- i 1))))))

(define (main)
  (let ((args (cddr (command-line))))
    (when (null? args)
      (display "Usage: kaappi add-license.scm <repo-path> ...\n")
      (display "Generates MIT LICENSE files from template.\n")
      (exit 1))

    (let* ((script-dir (dirname (cadr (command-line))))
           (template-path (path-join
                           (path-join script-dir "..")
                           "templates/LICENSE-MIT"))
           (template (read-template template-path))
           (year (current-year))
           (content (string-replace-all template "{{YEAR}}" year)))

      (for-each
       (lambda (repo-path)
         (let ((license-path (path-join repo-path "LICENSE")))
           (if (file-exists? license-path)
               (begin
                 (display "  skip  ")
                 (display license-path)
                 (display " (already exists)\n"))
               (begin
                 (call-with-output-file license-path
                   (lambda (port) (display content port)))
                 (display "  wrote ")
                 (display license-path)
                 (newline)))))
       args))))

(main)
