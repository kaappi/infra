(import (scheme base)
        (scheme write)
        (scheme file)
        (scheme process-context)
        (kaappi json))

(define (read-file-text path)
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
  (let* ((args (cdr (command-line)))
         (base-dir (if (null? args) ".." (car args)))
         (script-dir (dirname (car (command-line))))
         (config-path (path-join (path-join script-dir "..") "repos.json"))
         (config (json-read-string (read-file-text config-path)))
         (pass 0)
         (fail 0))

    (display "Kaappi org repo audit\n")
    (display "=====================\n")
    (display "Base directory: ") (display base-dir) (newline)
    (newline)

    (for-each
     (lambda (repo)
       (let* ((name (cdr (assoc "name" repo)))
              (category (cdr (assoc "category" repo)))
              (expected (cdr (assoc "expect" repo)))
              (repo-path (path-join base-dir name)))
         (display name)
         (display " [") (display category) (display "]\n")
         (for-each
          (lambda (file)
            (let ((full-path (path-join repo-path file)))
              (if (file-exists? full-path)
                  (begin
                    (display "  ok   ") (display file) (newline)
                    (set! pass (+ pass 1)))
                  (begin
                    (display "  MISS ") (display file) (newline)
                    (set! fail (+ fail 1))))))
          expected)
         (newline)))
     config)

    (display "---\n")
    (display (number->string pass)) (display " passed, ")
    (display (number->string fail)) (display " missing\n")

    (when (> fail 0) (exit 1))))

(main)
