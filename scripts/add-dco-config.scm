(import (scheme base)
        (scheme write)
        (scheme file)
        (scheme process-context))

;; Seeds .github/dco.yml (config for the DCO2 GitHub App) into repos that
;; don't have it yet, from the template in this repo. Never overwrites an
;; existing file, so a repo that has already customized its config keeps it.

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

(define (main)
  (let ((args (cdr (command-line))))
    (when (null? args)
      (display "Usage: kaappi add-dco-config.scm <repo-path> ...\n")
      (display "Seeds .github/dco.yml from templates/dco.yml.\n")
      (exit 1))

    (let* ((script-dir (dirname (car (command-line))))
           (template-path (path-join
                           (path-join script-dir "..")
                           "templates/dco.yml"))
           (template (read-template template-path)))

      (for-each
       (lambda (repo-path)
         (let ((github-dir (path-join repo-path ".github"))
               (dest-path (path-join (path-join repo-path ".github") "dco.yml")))
           (unless (file-exists? github-dir)
             (create-directory github-dir))
           (if (file-exists? dest-path)
               (begin
                 (display "  skip  ") (display dest-path)
                 (display " (already exists)\n"))
               (begin
                 (call-with-output-file dest-path
                   (lambda (port) (display template port)))
                 (display "  wrote ") (display dest-path) (newline)))))
       args))))

(main)
