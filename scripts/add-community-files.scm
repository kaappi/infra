(import (scheme base)
        (scheme write)
        (scheme file)
        (scheme process-context))

;; Seeds CODE_OF_CONDUCT.md and SECURITY.md into repos that don't have them
;; yet, from the canonical copies in the kaappi/community repo (a sibling
;; checkout at ../../community relative to this script). Never overwrites an
;; existing file -- a repo with its own SECURITY.md (e.g. kaappi/kaappi, which
;; documents its sandbox/FFI threat model) keeps it as-is.

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

(define (seed-file! repo-path community-dir filename)
  (let ((dest-path (path-join repo-path filename))
        (source-path (path-join community-dir filename)))
    (if (file-exists? dest-path)
        (begin
          (display "  skip  ") (display dest-path)
          (display " (already exists)\n"))
        (begin
          (call-with-output-file dest-path
            (lambda (port) (display (read-template source-path) port)))
          (display "  wrote ") (display dest-path) (newline)))))

(define (main)
  (let ((args (cdr (command-line))))
    (when (null? args)
      (display "Usage: kaappi add-community-files.scm <repo-path> ...\n")
      (display "Seeds CODE_OF_CONDUCT.md and SECURITY.md from kaappi/community.\n")
      (exit 1))

    (let* ((script-dir (dirname (car (command-line))))
           (infra-dir (path-join script-dir ".."))
           (workspace-dir (path-join infra-dir ".."))
           (community-dir (path-join workspace-dir "community")))

      (for-each
       (lambda (repo-path)
         (display repo-path) (newline)
         (seed-file! repo-path community-dir "CODE_OF_CONDUCT.md")
         (seed-file! repo-path community-dir "SECURITY.md")
         (newline))
       args))))

(main)
