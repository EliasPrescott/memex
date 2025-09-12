#lang racket

(require (prefix-in base: racket/base))
(require threading xml xml/path txexpr
         data/functor
         data/either data/monad data/applicative
         megaparsack megaparsack/text)

(provide resolve-reference)

(permissive-xexprs #t)

(define books
  '("Genesis"
    "Exodus"
    "Leviticus"
    "Numbers"
    "Deuteronomy"
    "Joshua"
    "Judges"
    "Ruth"
    "1 Samuel"
    "2 Samuel"
    "1 Kings"
    "2 Kings"
    "1 Chronicles"
    "2 Chronicles"
    "Ezra"
    "Nehemiah"
    "Esther"
    "Job"
    "Psalms"
    "Proverbs"
    "Ecclesiastes"
    "Song of Songs"
    "Isaiah"
    "Jeremiah"
    "Lamentations"
    "Ezekiel"
    "Daniel"
    "Hosea"
    "Joel"
    "Amos"
    "Obadiah"
    "Jonah"
    "Micah"
    "Nahum"
    "Habakkuk"
    "Zephaniah"
    "Haggai"
    "Zechariah"
    "Malachi"
    "Matthew"
    "Mark"
    "Luke"
    "John"
    "Acts"
    "Romans"
    "1 Corinthians"
    "2 Corinthians"
    "Galatians"
    "Ephesians"
    "Philippians"
    "Colossians"
    "1 Thessalonians"
    "2 Thessalonians"
    "1 Timothy"
    "2 Timothy"
    "Titus"
    "Philemon"
    "Hebrews"
    "James"
    "1 Peter"
    "2 Peter"
    "1 John"
    "2 John"
    "3 John"
    "Jude"
    "Revelation"))

(define (book->number book)
  (let ([num (index-of books book)])
    (if num
        (+ 1 num)
        (error (string-append "Cannot find book " book)))))

(define translations-directory (build-path (find-system-path 'orig-dir) "static/bible-translations/"))

(define versions
  (~> (directory-list translations-directory)
      (base:map (λ (p) (list (~> p (path-replace-extension "") file-name-from-path path->string)
                             (~> (build-path translations-directory p) open-input-file read-xml document-element xml->xexpr))) _)))
(define version-names (base:map car versions))

(define (get-translation translation-name)
  (let ([res (assoc translation-name versions)])
    (if res
        (~> res cdr car)
        (error (string-append "Could not load translation " translation-name)))))

(define (find-tags doc tag-name)
  (findf*-txexpr doc (λ (x) (and (txexpr? x)
                                      (eq? (get-tag x) tag-name)))))

(define (get-books doc)
  (find-tags doc 'book))

(define (get-chapters doc)
  (find-tags doc 'chapter))

(define (get-verses doc)
  (find-tags doc 'verse))

(define (get-book doc book)
  (~> (get-books doc)
      (findf (λ (x)
               (equal? (attr-ref x 'number)
                       (~> book book->number number->string)))
             _)))

(define (get-chapter doc num)
  (~> (get-chapters doc)
      (findf (λ (x)
               (equal? (attr-ref x 'number)
                       (number->string num)))
             _)))

(define (get-verse doc num)
  (~> (get-verses doc)
      (findf (λ (x)
               (equal? (attr-ref x 'number)
                       (number->string num)))
             _)))

(define (get-verse-range doc start end)
  (let ([verse-numbers (apply set (base:map number->string (inclusive-range start end)))]) 
    (~> (get-verses doc)
        (base:filter (λ (x) (set-member? verse-numbers (attr-ref x 'number)))
                     _))))

(define bible-book/p (apply or/p (base:map (λ (x) (~> x string/p try/p)) books)))
(define bible-version/p (apply or/p (base:map (λ (x) (~> x string/p try/p)) version-names)))
(define bible-verse-range/p
  (do
    [start <- integer/p]
    (char/p #\-)
    [end <- integer/p]
    (pure (list 'verse-range start end))))
(define bible-verse-single/p
  (do
    [verse <- integer/p]
    (pure (list 'verse-single verse))))
(define bible-reference/p
    (do
      [book <- bible-book/p]
      space/p
      [chapter <- integer/p]
      (char/p #\:)
      [verse <- (or/p (try/p bible-verse-range/p) bible-verse-single/p)]
      space/p
      (char/p #\()
      [version <- bible-version/p]
      (char/p #\))
      (pure (list version book chapter verse))))

(define (resolve-reference/either str)
  (map 
    (match-λ
      [(list version book chapter (list 'verse-range start end))
       (let* ([translation (get-translation version)]
              [book (get-book translation book)]
              [chapter (get-chapter book chapter)]
              [verses (get-verse-range chapter start end)])
         verses)]
      [(list version book chapter (list 'verse-single verse))
       (let* ([translation (get-translation version)]
              [book (get-book translation book)]
              [chapter (get-chapter book chapter)]
              [verse (get-verse chapter verse)])
         (list verse))])
    (parse-string bible-reference/p str)))

(define (resolve-reference str)
  ; TODO: error handling :)
  (either (λ (_err) (error "Something went wrong"))
          (λ (x) x)
          (resolve-reference/either str)))
