;;;; -*- Mode : Lisp -*-

;;;; Lorenzo Spizzuoco 879177

;;;; jsonparse.lisp

;; string parser

;; funzione parse-string
;; argomenti e valori:
;; jsonlist -> lista

;; descrizione:
;; la funzione ritorna l'output della funzione
;; parse-string-content

(defun parse-string (jsonlist)
  (if (eql #\" (first jsonlist))
      (parse-string-content (rest jsonlist) '())
      (error "syntax error")))

;; funzione parse-string-content

;; una stringa è composta da
;; '"' characters '"'
;; la funzione ritorna la stringa parsata
;; e tutti i caratteri presenti dopo la chiusura della stringa

(defun parse-string-content (jsonlist stringa)

  (let* ((carattere (parse-character jsonlist)))

    ;; controllo che il " non sia un carattere di escape
    ;; all'interno di una stringa

    (if (and
	 (not (eql (first jsonlist) #\\))
	 (eql #\" (first(first carattere))))
        (list stringa (rest jsonlist))
	
	(parse-string-content 
	 (second carattere) 
	 (append stringa (first carattere))))))

;; funzione parse-character
;; un carattere è valido se è un carattere
;; di escape valido oppure se è compreso tra
;; 0020 e 10FFFF 

(defun parse-character (jsonlist)
  (let* ((primo-carattere (first jsonlist)))
    (cond ((eql primo-carattere #\\)
           (if (eql #\" (second jsonlist))
               
               (list (list #\") (rest (rest jsonlist)))
               (list
		(list primo-carattere (escape-char (second jsonlist)))
		(rest (rest jsonlist)))))
          ((and 
            (>= (char-code primo-carattere) #x20)
            (<= (char-code primo-carattere) #x10ffff))
           (list (list primo-carattere) (rest jsonlist)))
          (t (error "syntax error: non-valid char")))))

(defparameter e-chars (list #\/ #\" #\\ #\b #\r #\t #\n #\f))

;; funzione che controlla se il carattere di escape trovato è valido
(defun escape-char (carattere)
  (if (find carattere e-chars)
      carattere
      (error "syntax error: non-valid escape char")))

;; funzione parse-object

;; argomenti e valori:
;; jsonlist -> lista da cui viene parsato un oggetto json

					; descrizione:
;; funzione che parsa un oggetto, ritorna una lista in cui
;; il primo elemento è la struttura dell'oggetto parsato
;; mentre il secondo elemento
;; è una lista con tutti i caratteri restanti
;; in jsonlist dopo l'oggetto parsato.
;; Se il primo carattere (dopo eventuali whitespace) dopo il parsing dei member
;; non è } allora viene generato un errore.


(defun parse-object (jsonlist)
  ;; caso oggetto vuoto
  (let* ((no-ws-jlist (parse-whitespace jsonlist)))
    (if (eql #\} (first no-ws-jlist))
        (list (list 'jsonobj) (rest no-ws-jlist))
	;; se non ho trovato l'oggetto vuoto
	;; controllo che il primo carattere dopo il parsing dei member sia }

	(let* ((members (parse-member jsonlist '()))
               (no-ws-rest-members (parse-whitespace (second members))))
	  (if (eql #\} (first no-ws-rest-members))
              (list 
               (append (list 'jsonobj) (first members))
	       ;; ritorno tutti i caratteri dopo la chiusura dell'oggetto 
               (rest no-ws-rest-members))
              (error "syntax error: bad form object"))
	  ))))

;; member parsing function
;; funzione parse-member

;; argomenti e valori:
;; jsonlist -> lista

;; descrizione:
;; funzione che parsa i members di un oggetto
;; members = pair*
;; questa funzione ritorna una lista composta nel seguente modo
;; (members rest)
;; dove members è una lista contenente tutte le pair parsate
;; e rest è una lista contenente tutti i caratteri
;; presenti dopo i member parsati
;; casi di errore:
;; non posso avere la lista in input vuota
;; il caso di oggetto vuoto è gestito da parse-object

(defun  parse-member (jsonlist members)
  (let* 
      ((no-ws-jlist (parse-whitespace jsonlist)))
    (if (null no-ws-jlist)
        (error "syntax error")
	(let* ((parsed-pair (parse-pair no-ws-jlist)))
          (if (eql #\, (first-afterws (second parsed-pair)))
              (parse-member
               (rest (parse-whitespace (second parsed-pair)))
               (append members (list (first parsed-pair))))
              (list
	       (append members (list (first parsed-pair)))
	       (second parsed-pair)))))))


;; argomenti e valori:
;; jsonlist -> lista

;; descrizione:
;; data la lista in input questa funzione effettua
;; il parsing di un singolo pair

;; dove attribute e una stringa mentre 
;; value = Object | stringa | numero | true | false | null
;; questa funzione ritorna una lista siffatta:
;; (pair rest)
;; dove 
;; pair = '(' attribute value ')'
;; rest è una lista contenente tutti i caratteri dopo il pair parsato
;; caso di errore: se l'attribute del pair è la stringa vuota oppure
;; il primo carattere dopo l'attribute non è : 

(defun parse-pair (jsonlist)
  (let*
      ((no-ws-jlist (parse-whitespace jsonlist))
       ;; chiamo il parser stringa per prendere l'attribute del pair
       (parsed-string (parse-string no-ws-jlist))
       ;; lista contenente tutto ciò che c'è dopo il pair attribute
       ;; senza whitespace iniziali
       (resto-nows (parse-whitespace (second parsed-string)))
       ;; controllo che dopo l'attribute del pair c'è :
       (pair-delimiter (eql  #\: (first resto-nows)))
       ;; attribute del pair
       (pair-attribute (first parsed-string))
       ;; se è presente sia l'attribute del pair che il : 
       ;; allora effettuo il parsing del value del pair
       (pair-value 
        (if (and pair-delimiter pair-attribute) 
            (parse-value (rest resto-nows))
            (error "syntax error"))))
    (if pair-value
	(list 
	 (list
          (list-to-string pair-attribute)
          (first pair-value))
	 (second pair-value))
	(error "syntax error"))))

;; funzione: parse-value

;; argomenti e valori:
;; jsonlist -> lista

;; descrizione:
;; parsa il value di un pair oppure di un elemento di un array
;; la funzione controlla il primo carattere dopo eventuali whitespace
;; e in base a questo chiama la funzione di parsing corretta
;; il valore di ritorno della funzione è sempre una lista siffatta:
;; (value rest)
;; value può essere una lista (nel caso di un oggetto o un array)
;; oppure un atomo (caso stringa, numero, true, false, null).
;; rest è la lista contenente tutti i caratteri presenti dopo il 
;; value parsato

(defun parse-value (jsonlist) 
  (let* ((no-ws-jsonlist (parse-whitespace jsonlist))
         (primo-carattere (first no-ws-jsonlist)))
    (cond
      ;; se quando effettuo il parsing del value trovo la chiusura
      ;; dell'oggetto oppure dell'array allora ho errore
      ((or (eql #\] primo-carattere) (eql #\} primo-carattere))
       (error "syntax error"))
      ;; caso stringa
      ((eql #\" primo-carattere)
       (let* ((parsed-string (parse-string no-ws-jsonlist)))
	 (list 
	  (list-to-string (first parsed-string))
	  (second parsed-string))))
      ;; caso oggetto
      ((eql #\{ primo-carattere) (parse-object (rest no-ws-jsonlist)))
      ;; caso array
      ((eql #\[ primo-carattere) (parse-array (rest no-ws-jsonlist)))
      ;; caso numero
      ((is-number primo-carattere) (parse-number no-ws-jsonlist))
      
      ((equal "true" (list-to-string (subseq no-ws-jsonlist 0 4)))
       (list 'true (subseq  no-ws-jsonlist 4)))

      ((equal "false" (list-to-string (subseq no-ws-jsonlist 0 5)))
       (list 'false (subseq no-ws-jsonlist 5)))

      ((equal "null" (list-to-string (subseq  no-ws-jsonlist 0 4))) 
       (list 'null (subseq no-ws-jsonlist 4))))))

;; funzione: parse-array

;; argomenti e valori: jsonlist -> lista

;; descrizione:
;; parsa un array
;; la funzione ritorna una lista siffatta:
;; (array rest)
;; dove array = '(' jsonarray elements ')'
;; rest è una lista contenente tutti i caratteri dopo l'array parsato

;; caso di errore:
;; se il primo carattere presente dopo gli elementi dell'array non è ]
;; allora la funzione segnala un errore

(defun parse-array (jsonlist)
  (if (eql #\] (first-afterws jsonlist))
      (list (list 'jsonarray) (rest (parse-whitespace jsonlist)))
      (let*
          ((array-elements (parse-element jsonlist '()))
           (array-close (eql #\] (first-afterws (second array-elements)))))
	(if array-close 
            (list
             (append (list 'jsonarray) (first array-elements))
             (rest (parse-whitespace (second array-elements))))
            (error "syntax error")))))

;; funzione parse-element
;; descrizione:
;; data la lista in input, effettua il parsing degli elementi di un array
;; casi di errore:
;; non posso avere la lista vuota come input
;; il caso array vuoto è gestito da parse-array

(defun parse-element (jsonlist elements)

  (if (null (parse-whitespace jsonlist)) 
      (error "syntax error")
      
      (let* ((parsed-value (parse-value jsonlist)))
	;; se dopo il il value parsato trovo una virgola,
	;; allora faccio la chiamata ricorsiva
	(if (eql #\, (first-afterws (second parsed-value)))
            (parse-element
             (rest (parse-whitespace (second parsed-value)))
             (append elements (list (first parsed-value))))

            (list (append elements (list (first parsed-value)))
		  (second parsed-value))
            ))))


;; funzione jsonparse
;; argomenti e valori:
;; jsonstr -> stringa 

;; descrizione:
;; riceve un input una stringa json da parsare
;; richiama la funzione jsonparsec passandole come input la jsonstr
;; trasformata in lista

(defun jsonparse (jsonstr)
  ;; no-ws-jsonlist -> stringa input trasformata in lista 
  ;; a cui viene tolto un eventuale whitespace iniziale
  (let ((no-ws-jsonlist (parse-whitespace (coerce jsonstr 'list))))
    (jsonparsec no-ws-jsonlist)))

;; funzione parse-whitespace

;; descrizione:
;; ritorna la lista passata in input senza whitespace all'inizio

(defun parse-whitespace (jsonlist &optional (ws nil))
  (let ((primo-carattere (first jsonlist)))
    (if (or
	 (eql #\Space primo-carattere)
	 (eql #\Newline primo-carattere)
	 (eql #\Tab primo-carattere)
	 (eql #\return primo-carattere)
	 (eql #\linefeed primo-carattere))
	(parse-whitespace
	 (rest jsonlist)
	 (append (list ws) primo-carattere)) 
	jsonlist)))

(defun jsonparsec (jsonlist)
  
  (cond
    
    ((null (parse-whitespace jsonlist)) nil)

    ((eql #\{ (first jsonlist)) 
     (let* ((parsed-obj (parse-object (rest jsonlist))))
       (if (null (parse-whitespace (second parsed-obj)))
           (first parsed-obj)
           (error "syntax error"))))
    
    ((eql #\" (first jsonlist))
     (let* ((parsed-string (parse-string jsonlist)))
       (if (null (parse-whitespace (second parsed-string)))
           (list-to-string (first parsed-string))
	   (error "syntax error"))))
    
    ((eql #\[ (first jsonlist))
     (let* ((parsed-array (parse-array (rest jsonlist))))
       (if (null (parse-whitespace (second parsed-array)))
           (first (parse-array (rest  jsonlist)))
           (error "syntax error"))))
    
    ((is-number (first jsonlist)) 
     (let* ((parsed-number (parse-number jsonlist)))
       (if (null (parse-whitespace (second parsed-number)))
           (first parsed-number)
           (error "syntax error"))))
    
    ((and (equal "null" (list-to-string (subseq jsonlist  0 4)))
          (null (parse-whitespace (coerce (subseq jsonlist 4) 'list))))
     'null)

    ((and (equal "true" (list-to-string (subseq jsonlist 0 4))) 
          (null (parse-whitespace (coerce (subseq jsonlist 4) 'list))))
     'true)

    ((and (equal "false" (list-to-string (subseq jsonlist 0 5))) 
          (null (parse-whitespace (coerce (subseq jsonlist 5) 'list))))
     'false)

    
    (t (error "Syntax error"))))



;; funzione che converte una lista in una stringa
(defun list-to-string (l) (coerce l 'string))


;; funzione: first-afterws
;; argomenti e valori: 
;; jsonlist -> lista
;; descrizione: 
;; la funzione ritorna il primo carattere nella lista dopo i whitespace

(defun first-afterws (l) (first (parse-whitespace l)))

;; NUMBER PARSING

;; funzione parse-number

;; argomenti valori:
;; jsonlist -> lista
;; descrizione:
;; la funzione ritorna una lista siffata:
;; (numero rest)
;; dove numero è il numero parsato da jsonlist e rest
;; sono tutti i caratteri presenti
;; dopo il numero parsato

(defun parse-number (jsonlist)
  (let* ((parsed-number-list (check-sign jsonlist)))
    ;; conversione da stringa a numero
    (list
     (with-input-from-string
	 (in (list-to-string (first parsed-number-list))) (read in))
     (second parsed-number-list))))

;; funzione check-sign
;; descrizione:
;; controlla se il primo carattere della lista
;; da cui parsare il numero è il segno meno

(defun check-sign (jsonlist)
  (if (eql #\- (first jsonlist))
      (let* ((numero (parse-number-list (rest jsonlist)))
             (segno-negativo (list #\-)))
        (list (append segno-negativo (first numero)) (second numero)))
      (parse-number-list jsonlist)))


;; funzione parse-number-list
;; effettua il parsing di un numero e lo ritorna lista
;; caso di errore: se manca il valore dell'esponente dopo la e

(defun parse-number-list (jsonlist &optional (numero nil))
  
  (cond
    ;; primo caso base: lista vuota
    ((null jsonlist) (list numero nil))
    ;; chiamata ricorsiva nel caso trovo un numero
    ((digit-char-p (first jsonlist))
     
     (parse-number-list 
      (rest jsonlist) 
      (append numero (list (first jsonlist)))))

    ;; se il carattere che sto leggendo è uguale al punto
    ;;allora chiamo il parser della parte decimale
    ((eql #\. (first jsonlist)) 
     ;; se trovo il punto controllo che la parte decimale ritornata non sia
     ;; null
     (let* ((decimal-part (parse-decimal (rest jsonlist))))
       (if (null (first decimal-part))
           (error "syntax error: missing decimal value")
           (list 
            (append numero (list (first jsonlist)) (first decimal-part))
            (second decimal-part)))))
    
    ;; se trovo e/E chiamo il parser per l'esponente
    ((eql #\e (char-downcase (first jsonlist))) 
     (let* ((exponent (parse-exp (rest jsonlist))))
       (list 
	(append numero (list (first jsonlist)) (first exponent)) 
	(second exponent)) ))
    ;; secondo caso base: carattere diverso da e . o numero
    (t (list numero jsonlist))))



;; parsing della parte decimale del numero

(defun parse-decimal (jsonlist &optional (numero nil))
  (cond

    ((null jsonlist) (list numero nil))
    
    ((digit-char-p (first jsonlist)) 
     (parse-decimal 
      (rest jsonlist) 
      (append numero (list (first jsonlist)))))
    
    ;; caso se trovo simbolo esponente
    ((eql #\e (char-downcase (first jsonlist))) 

     (let* ((exp-list (parse-exp (rest jsonlist))))
       (list
	(append numero (list (first jsonlist)) (first exp-list))
	(second exp-list))))
    
    (t (list numero  jsonlist))
    ))

;; exponent parser

;; funzione parse-exp
;; funzione di controllo per eventuale segno dell'esponente

(defun parse-exp (jsonlist)
  (cond 
    ((null jsonlist) (error "syntax error: missing exponent value"))
    
    ((or (eql #\- (first jsonlist)) (eql #\+ (first jsonlist)))
     (let* ((exp-value (parse-exp-v (rest jsonlist))))
       (list 
	(append (list (first jsonlist)) (first exp-value))
	(second exp-value))))
    
    ((digit-char-p (first jsonlist)) 
     (let* ((exp-value (parse-exp-v jsonlist)))
       (list
	(first exp-value)
	(second exp-value))))
    (t (error "syntax error"))))

;; exponent value parsing

(defun parse-exp-v (jsonlist &optional (numero nil))
  (cond
    ;; caso base: jsonlist vuota
    ((null jsonlist) (list numero nil))

    ((digit-char-p (first jsonlist))
     (parse-exp-v 
      (rest jsonlist) 
      (append numero (list (first jsonlist)))))
    
    ;; caso base: il carattere trovato non è un digit
    (t (list numero jsonlist))))


;; funzione di appoggio che controlla se un carattere è il segno
;; meno oppure un digit

(defun is-number (c) 
  (or (eql #\- c) (digit-char-p c)))


;; jsonaccess 

(defun jsonaccess (object &rest fields) 
  (let ((f (first object)))
    (if (or (equal f 'jsonobj) (equal f 'jsonarray))  

        (if (null fields)
            object
            (apply 'jsonacc (rest object) fields))
	(error "trying to access a non-object"))))

(defun jsonacc (object &rest fields)
  ;; caso base
  (if (null object) 
      (error "field not found")
      
      ;; caso numero
      (if (typep (first fields) 'integer)
          (apply 'seek-element object (first fields) (rest fields))
	  
	  (if (equal (first (first object)) (first fields))
              (if (null (rest fields))
		  (second (first object))
		  (apply 'jsonaccess (second (first object)) (rest fields)))
              (apply 'jsonacc (rest object) fields)))))

;; ricerca elemento all'interno di un array 
(defun seek-element (object n &rest fields)
  (if (or (< (- (length object) 1) n) (< n 0))
      (error "index out of bound")
      (if (null fields)
          (nth n object)
	  (apply 'jsonaccess (nth n object) fields))))

(defun jsonread (filename)
  (let ((r (app filename)))
    (jsonparse (subseq r 0 (- (length r) 3)))))

(defun app (filename)
  (if (null filename)
      (error "filename null")
      (with-open-file (in filename
                          :direction :input
                          :if-does-not-exist :error)
	(file-to-string in))))

(defun file-to-string (inputstream)
  (let ((json (read-char inputstream nil 'eof)))
    (unless (eq json 'eof)
      (string-append json (file-to-string inputstream)))))

;; dump su file

(defparameter tab  #\tab)

(defun jsondump (obj filename)
  (with-open-file (stream filename
                          :direction :output
                          :if-exists :supersede
                          :if-does-not-exist :create)
    (dump-object obj stream)
    filename))


(defun dump-object (obj stream)
  (let ((f (first obj)))
    (cond ((equal f 'jsonobj) (object-dump stream (rest obj) nil))
          ((equal f 'jsonarray) (array-dump stream (rest obj) '())))
    ))

(defun object-dump (stream obj tabs)
  (cond 
    ((null obj) (format stream "{}"))
    (t 
     (format stream "{~%") 
     (member-dump stream obj (append (list tab) tabs)) 
     (format stream "~%~{~A~^~}}" tabs))
    ))

(defun member-dump (stream obj tabs)
  (cond
    ;; caso member vuoto
    ((null obj) (format stream ""))

    ;; caso ultimo pair da stampare
    ((null (rest obj))
     (format stream "~{~A~^~}" tabs)
     (string-dump stream (first (first obj)))
     (format stream " : ")
     (value-dump stream (second (first obj)) tabs))

    ;; passo ricorsivo
    (t
     (format stream "~{~A~^~}" tabs)
     (string-dump stream (first (first obj)))
     (format stream " : ")
     (value-dump stream (second (first obj)) tabs)
     (format stream ",~%")
     (member-dump stream (rest obj) tabs))
    ))

(defun value-dump (stream value &optional tabs)
  (cond
    ;; controllo se è una stringa o un numero
    ((typep value 'string) (string-dump stream value))
    ((typep value 'number) (format stream "~A" (write-to-string value)))
    ((equal value 'true) (format stream "true"))
    ((equal value 'false) (format stream "false"))
    ((equal value 'null) (format stream "null"))
    ;; controllo se il value è un oggetto o un array
    ((equal (first value) 'jsonobj)
     (object-dump stream (rest value) tabs))
    
    ((equal (first value)  'jsonarray)
     (array-dump stream (rest value) tabs))))


(defun string-dump (stream str)
  (cond 
    (t
     (format stream "\"")
     (string-dump-list stream (coerce str 'list))
     (format stream "\""))))

(defun string-dump-list (stream str-list)
  (cond 
    ((not (null str-list))
     (let ((carattere (first str-list))
           (resto (rest str-list)))
       (if (eql carattere #\")
           (format stream "~C~C" #\\ carattere)
           (format stream "~C"  carattere))
       (string-dump-list stream resto)))))



(defun array-dump (stream obj tabs)
  (cond
    (t 
     (format stream "[")
     (elements-dump stream obj tabs)
     (format stream "]"))))

(defun elements-dump (stream obj tabs)
  (cond
    ((null (rest obj))
     (value-dump stream (first obj) tabs))
    (t 
     (value-dump stream (first obj) tabs)
     (format stream ", ")
     (elements-dump stream (rest obj) tabs))))


;;;; end of file - jsonparse.lisp
