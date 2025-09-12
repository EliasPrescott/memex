#lang racket/base

(require racket/set racket/list pollen/core pollen/decode pollen/misc/tutorial pollen/pagetree txexpr threading racket/string pollen/tag net/url)
(require (prefix-in posts-ptree: "posts-ptree.rkt"))
(require (prefix-in bible: "bible.rkt"))
(provide root post-list
         generate-posts-pt
         section
         backlinks
         yt
         code-listing
         bible-reference
         callout)

(define (id x) x)

(define (code-listing type . elements)
  (txexpr 'pre `((code-listing "")
                 (type ,type))
          (list (txexpr 'code '()
                        elements))))

(define (section . elements)
  (txexpr 'section
          empty
          (decode-paragraphs
            elements
            #:linebreak-proc id
            #:force? #t)))

(define (callout . elements)
  `(blockquote ()
               ,(apply section elements)))

(define (add-spaces-to-verses verses)
  (map (λ (verse)
         (map-elements (λ (x) (if (string? x)
                                  (string-append " " x " ")
                                  x))
                       verse))
       verses))

(define (add-verse-numbers-to-verses verses)
  (apply append
         (map (λ (verse)
                (list `(sup ,(attr-ref verse 'number))
                      verse))
              verses)))

(define (format-verses verses)
  (~> verses add-spaces-to-verses add-verse-numbers-to-verses))

(define (bible-reference ref)
  `(blockquote ()
               (p () (bible-reference ((ref ,ref))
                                      ,@(format-verses (bible:resolve-reference ref))))
               (footer ()
                       ,ref)))

(define (root . elements)
   (txexpr 'root empty (decode-elements elements)))

(define (yt title url)
  `(yt-embed
     ((url ,url)
      (title ,title))
     (list (iframe
             ((width "560")
              (height "315")
              (src ,url)
              (allowfullscreen "")
              (frameborder "0"))
             empty))))

(define (is-path-a-post? path)
  (let ([path-str (symbol->string path)])
    (and (string-prefix? path-str "posts/")
         (string-suffix? path-str "index.html")
         (> (length (explode-path path-str)) 2))))

(define (get-posts)
  (~> (get-pagetree (build-path (find-system-path 'orig-dir) "index.ptree"))
      pagetree->list
      (filter is-path-a-post? _)))

(define (doc->title path)
  (~> path get-doc (select 'h1 _)))

(define (clean-path path)
  (if (eq? path "/index.html")
      "/"
      (~> path
          (string-trim _ "/index.html" #:left? #f)
          (string-append "/" _))))

(define (doc->link path)
  (~> path symbol->string clean-path))

(define (doc->posting-date path)
  (select 'posting-date path))

(define (find-tags tagname doc)
  (findf*-txexpr (get-doc doc)
                 (λ (x) (and (txexpr? x) (eq? tagname (get-tag x))))))

(define (doc->yt-embeds doc)
  (find-tags 'yt-embed doc))

(define (doc->code-listings doc)
  (~> (find-tags 'pre doc)
      (or '())
      (filter (λ (x) (attrs-have-key? x 'code-listing)) _)))

(define (internal-link? str)
  (let ([url (string->url str)])
    (and (url-path url)
         (not (url-scheme url))
         (not (url-host url))
         (not (url-port url)))))

(define (doc->internal-links doc)
  (~> (find-tags 'a doc)
      (or '())
      (filter (λ (x) (not (attrs-have-key? x 'backlink))) _)
      (filter (λ (x) (internal-link? (attr-ref x 'href #f))) _)))

(define (get-all-internal-links)
  (~> (pagetree->list (current-pagetree))
      (map (λ (x) (cons x (doc->internal-links x))) _)
      append))

(define (dedup lst) (~> lst list->set set->list))

(define (get-backlinks doc)
  (let ([links (get-all-internal-links)])
    (~> links
        (filter (λ (x) (not (eq? (car x) doc))) _)
        (map (λ (x) (cons (car x)
                               (~> (cdr x)
                                   (filter (λ (link) 
                                             (or (equal? (attr-ref link 'href #f)
                                                         (string-append "/" (symbol->string doc)))
                                                 (equal? (string-append (attr-ref link 'href #f) "/index.html")
                                                         (string-append "/" (symbol->string doc)))))
                                           _)
                                   dedup)))
             _)
        (filter (λ (x) (not (null? (cdr x)))) _))))

(define (backlinks doc)
  (let* ([all-links (get-backlinks doc)])
    (if (> (length all-links) 0)
        `(section
           (h2 "Backlinks")
           (p (ul ,@(apply append
                           (map (λ (x)
                                  (let ([doc (car x)]
                                        [links (cdr x)])
                                    (map (λ (link)
                                           `(li (a ((href ,(doc->link doc))
                                                    (backlink ""))
                                                   ,(doc->title doc))))
                                         links)))
                                all-links)))))
        '(section ()))))

(define (post-list)
  (let ([sorted-posts (~> (get-posts)
                          (sort (λ (a b) (string<? (doc->posting-date b)
                                                        (doc->posting-date a)))))])
    `(ul ,@(map (λ (path)
                      `(li (a ((href ,(doc->link path)))
                              ,(doc->title path)
                              ,(string-append " (" (doc->posting-date path) ")"))))
                sorted-posts))))

(define generate-posts-pt posts-ptree:generate-ptree)
