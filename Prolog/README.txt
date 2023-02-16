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

Predicati principali della libreria:

1. jsonparse(JSONString, Object)

Il predicato jsonparse/2 risulta vero se  JSONString (che può essere
o una stringa SWI Prolog o un atomo Prolog)
può essere scomposto in una stringa, un numero oppure in:

Object = jsonobj(Members)
Object = jsonarray(Elements)

dove Members = [] oppure
Members [Pair | MoreMembers]

Pair = (Attribute, Value)

Attribute = <string SWI Prolog>

Number = <numero Prolog>

Value = <string SWI Prolog> | Number | Object | true | false | null

Nel caso di un array:
Elements = [] oppure
Elements [Value | MoreElements]

Esempio di funzionamento jsonparse:

jsonparse('{"a" : "b", "o" : {}}', L).
L = jsonobj([("a", "b"), ("o", jsonobj([]))]).

Tutti i predicati relativi al parsing non utilizzano direttamente la stringa
JSONstring ma la sua scomposizione in lista di caratteri tramite il predicato:

string_chars(String, CharList).

Difatti il predicato jsonparse è vero se risulta vero il predicato

jsonparsec(JSONList, R).

Il predicato jsonparsec/2 risulta vero se riesce a costruire un oggetto json
a partire dalla list JSONlist.

In base al primo carattere di JSONList, il predicato cerca di costruire o:

1. un oggetto, con il predicato parse_object(Lista, Oggetto, Resto);
2. un array, con il predicato parse_array(Lista, Array, Resto);
3. una stringa, con il predicato parse_string(Lista, Stringa, Resto);
4. un numero, con il predicato parse_number(Lista, Numero, Resto);
5. true, false, null.

Per la costruzione di oggetti e array, i predicati parse_object e
parse_array seguono la possibile scomposizione ricorsiva di un oggetto
o array utilizzando altri predicati come per esempio
parse_members/3 e parse_value/3.

Tutti i predicati cercano di costruire il corrispettivo elemento da una
lista e risultano veri se è possibile costruire anche la lista di caratteri
rimanenti dopo l'elemento costruito.


2. jsonaccess(Jsonobj, Fields, Result).

Il predicato jsonaccess risulta vero se è possibile recuperare Result
seguendo la sequenza di campi presente in Fields a partire da Jsobj.
Nel caso un field sia un integer N >= 0, allora corrisponde ad un indice
di un array JSON.
Fields può anche essere una singola stringa SWI Prolog.

Esempio di funzionamento jsonaccess:

jsonparse('{"nome" : "Arthur", "cognome" : "Dent"}', O),
jsonaccess(O, ["nome"], R).
O = jsonobj([("nome", "Arthur"), ("cognome", "Dent")])
R = "Arthur".

3. jsonread(FileName, JSON).

Il predicato jsonread/2 apre e legge il file FileName e ha
successo se riesce a costruire un oggetto JSON.
Il predicato funziona leggendo l'intero file in una stringa e
richiamando jsonparse/2.
Se FileName non esiste il predicato fallisce.

4. jsondump(JSON, FileName).

Il predicato jsondump/2 scrive l'oggetto JSON sul file FileName in sintassi JSON
(viene effettuata tabulazione).
In caso non esiste FileName, viene creato il file e se esiste viene sovrascritto.




