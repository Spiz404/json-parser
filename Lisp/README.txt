Studente: Spizzuoco Lorenzo 879177

La libreria implementata costruisce delle strutture dati
che rappresentano oggetti JSON a partire dalla loro rappresentazione
come stringhe.

Un oggetto json può essere:
1. object
2. array
3. value
4. string
5. number
6. true, false, null

Un object a sua volta si scompone  in:

'{' ws '}'
'{' members '}'

dove members è così composto:

member | member ',' members

member:

ws string ws ':' element

dove ws sta per whitespace mentre element:

ws value ws

Value può essere:

1. object
2. array
3. string
4. number
5. true, false, null

Un array si scompone in:

'[' ws ']'
'[' elements ']'

dove elements:

element
element ',' elements

ed element:

ws value ws

-------------------------------------------------------------------------

Principali funzioni della libreria:

1. jsonparse

La funzione jsonparse accetta in input una stringa e cerca di costruire
una struttura dati che può essere:
1. un oggetto
2. un array
3. una stringa
4. un oggetto
5. true, false, null

La sintassi degli oggetti JSON in Common Lisè è la seguente:

Object = '(' jsonobj members ')'
Object = '(' jsonarray elements ')'

dove:

members = pair*

pair = '(' attribute value ')'

attribute  = <stringa Common Lisp>

number = <numero Common Lisp>

value = string | number | Object | true | false | null

elements = value*

Il parsing non viene direttamente effettuato sulla stringa in input
ma sulla lista composta dai caratteri della stringa, infatti la funzione
jsonparse richiama la funzione jsonparsec passandole una lista costruita tramite la funzione:

(coerce stringa 'list)

dove stringa è l'input della funzione jsonparse.

Il parsing di tipi diversi è gestito da funzioni differenti, infatti jsonparsec, in base al
primo carattere della lista in input (dopo eventuali whitespace) chiama:

1. parse-object per il parsing di un oggetto;
2. parse-array per il parsing di un array;
3. parse-string per il parsing di una stringa;
4. parse-number per il parsing di un numero;
5. null, true e false sono direttamente gestiti da jsonparsec.

Ogni funzione ritorna una lista del tipo:
(elemento_parsato resto)
dove resto è una lista contenente tutti i caratteri dopo l'elemento parsato.

Per il parsing dei tipi composti jsonobj e jsonarray, le funzioni parse-object e parse-array
seguono la scomposizione ricorsiva di un oggetto o array json,
difatti vengono utilizzate
funzioni come parse-member, parse-element, parse-value.

Esempio di funzionamento:

CL-prompt> (defparameter x (jsonparse "{\"nome\" : \"Arthur\",
 \"cognome\" : \"Dent\"}"))
X

CL-prompt> x
(JSONOBJ ("nome" "Arthur") ("cognome" "Dent"))


2. jsonaccess

La funzione jsonaccess accetta come parametri un oggetto JSON costruito
dalla funzione jsonparse (rappresentato quindi in common lisp) e un numero variabile
di fields. La funzione ritorna il value rintracciabile seguendo la catena di fields.
Nel caso in fields sia presente un numero intero N >= 0, allora esso corrisponde all'indice
di un array.

Il numero variabile di fields è gestito tramite l'indicatore &rest.

Esempio di funzionamento:

CL-prompt> (jsonaccess (jsonparse
 	   	       "{\"name\" : \"Zaphod\",
		         \"heads\" : [[\"Head1\"], [\"Head2\"]]}")
 	   "heads" 1 0)

"Head2"

3. jsonread

La funzione jsonread apre un file il cui filename è passato come input e costruire un oggetto json
in common lisp a partire dal contenuto di filename.
La funzione legge l'intero contenuto del file come una stringa e richiama la funzione jsonparse.

4. jsondump

La funzione jsondump prende in input un oggetto json costruito da jsonparse e un filename.
Lo scopo della funzione è di scrivere in filename l'oggetto json passato in input in sintassi
json (viene effettuata tabulazione).

Nel caso filename non eista allora il file viene creato, se invece esiste, viene sovrascritto.

