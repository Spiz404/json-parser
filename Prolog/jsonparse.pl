%%%% -*- Mode: Prolog -*-

%%%% jsonparse.pl

% OBJECT PARSER

% jsonobj/3

% jsonobj effettua il parsing di un oggetto json

jsonobj([C | ObjectStringList], jsonobj(Members), Rest) :-
    % controllo che il primo carattere sia la parentesi aperta
    C = '{',
    % parsing members oggetto
    parse_members(ObjectStringList, Members, Remaning),
    % dopo il parsing dei member dell'oggetto controllo
    %che sia presente dopo whitespace la chiusura dell'oggetto
    parse_whitespace(Remaning, [LastDelimiter | Rest]),
    LastDelimiter = '}',
    !.

% JSON OBJECT MEMBER PARSING

% parse_members/3

% predicato vero se è possibile costruire una lista di members
% da memberStringList

% caso [ Members ] lista vuota

parse_members(MemberStringList, [], [Delimiter | Rest]) :-
    parse_whitespace(MemberStringList, [Delimiter | Rest]),
    Delimiter = '}',
    !.

% caso in cui sono presenti più pair

parse_members(MemberStringList, [W | OtherMembers], R) :-
    parse_whitespace(MemberStringList, [Delimiter | Rest]),
    Delimiter = '"',
    parse_pair(Rest, W, MemberRest),
    parse_whitespace(MemberRest, [D | Mns]),
    D = ',',
    /*
     se trovo una virgola, devo controllare che il delimiter successivo
     non sia la chisura dell'oggetto,
     in quanto dopo la virgola devo per forza avere un altro Member
    */
    parse_whitespace(Mns, [NextMemberDelimiter | _]),
    NextMemberDelimiter \= '}',
    !,
    parse_members(Mns, OtherMembers, R).

% caso in cui è presente un solo pair

parse_members(MemberStringList, [W], Remaning) :-
    parse_whitespace(MemberStringList, [Delimiter | Rest]),
    Delimiter = '"',
    !,
    parse_pair(Rest, W, Remaning).


parse_members(MemberStringList, _, _) :-
    parse_whitespace(MemberStringList, _),
    fail.

% caso in cui sono presenti più pair

parse_pair(Rest, (String, Value), MemberRest) :-

    parse_string(Rest, String, PairRest),
    parse_whitespace(PairRest, [Delimiter | ValueRest]),
    Delimiter = ':',
    parse_value_delimiter(ValueRest, Value, MemberRest),
    !.

% parsing value di un pair

% parse_value_delimiter/3

parse_value_delimiter(ValueStringList, Value, MemberRest) :-
    parse_whitespace(ValueStringList, [Delimiter | ValueRest]),
    parse_value([Delimiter | ValueRest], Value, MemberRest).


% parse_value/3
% richiama il predicato corretto in base al primo carattere
% della lista in input

parse_value(['"' | ValueRest], Value, MemberRest) :-

    !,
    parse_string(ValueRest, Value, MemberRest).

% value è un numero

% caso numero negativo

parse_value(['-' | ValueRest], Value, MemberRest) :-

    !,
    parse_number(['-' | ValueRest], Value, MemberRest).

% caso numero positivo

parse_value([Delimiter | ValueRest], Value, MemberRest) :-

    is_digit(Delimiter),
    !,
    parse_number([Delimiter | ValueRest], Value, MemberRest).

% caso value è un oggetto

parse_value([Delimiter | ValueRest], Value, MemberRest) :-

    Delimiter = '{',
    !,
    jsonobj([Delimiter | ValueRest], Value, MemberRest).

% caso value è un array

parse_value([Delimiter | ValueRest], Value, MemberRest) :-

    Delimiter = '[',
    !,
    jsonarray([Delimiter | ValueRest], Value, MemberRest).

% casi value è true, false, null

parse_value(['t', 'r', 'u', 'e' | MemberRest], true, MemberRest) :- !.

parse_value(['f', 'a', 'l', 's', 'e' | MemberRest], false, MemberRest) :- !.

parse_value(['n', 'u', 'l', 'l' | MemberRest], null, MemberRest) :- !.

% parsing array

jsonarray([C | MoreChars], jsonarray(Elements), Rest) :-
    C = '[',
    parse_elements(MoreChars, Elements, R),
    parse_whitespace(R, [Delimiter | Rest]),
    !,
    Delimiter = ']'.

% caso Element lista vuota

parse_elements(List, [], [Delimiter | Rest]) :-
    parse_whitespace(List, [Delimiter | Rest]),
    Delimiter = ']',
    !.

% caso singolo Element

parse_elements(List, [Element | MoreElements], Rest) :-
    parse_whitespace(List, NowsList),
    parse_value(NowsList, Element, Er),
    parse_whitespace(Er, [Delimiter | ElementRest]),
    Delimiter = ',',
    % se incontro la virgola devo controllare
    % che il delimiter successivo non sia la chiusura dell'array
    parse_whitespace(ElementRest, [D | _]),
    D \= ']',
    !,
    parse_elements(ElementRest, MoreElements, Rest).

parse_elements(List, [Element], Rest) :-
    parse_whitespace(List, NowsList),
    parse_value(NowsList, Element, Rest), !.

% jsonparse/2
% interface per jsonparsec
% effettua prima il parsing dei whitespace all'inizio della lista

jsonparse(JSONString, L) :-
    string_chars(JSONString,  JSONStringChars),
    parse_whitespace(JSONStringChars, JStringNoWs),
    jsonparsec(JStringNoWs, L).

% jsonparsec/2

% predicato vero se riesce a costruire un elemento dalla lista

% caso oggetto

jsonparsec([X | Rest], L) :-
    X = '{',
    !,
    jsonobj([X | Rest], L, R),
    parse_whitespace(R, []).


% caso array

jsonparsec([X | Rest], Jarray) :-
    X = '[',
    !,
    jsonarray([X | Rest], Jarray, R),
    parse_whitespace(R, []).

% caso stringa

jsonparsec([X | Rest], S) :-
    X = '"',
    !,
    parse_string(Rest, S, R),
    parse_whitespace(R, []).

% caso numero negativo

jsonparsec([X | Rest], W) :-
    X = '-',
    !,
    parse_number([X | Rest], W, R),
    parse_whitespace(R, []).

% caso numero positivo

jsonparsec([X | Rest], W) :-
    is_digit(X),
    !,
    parse_number([X | Rest], W, R),
    parse_whitespace(R, []).

% casi true, false, null

jsonparsec(['t', 'r', 'u', 'e' | Rest], true) :-
    !,
    parse_whitespace(Rest, []).

jsonparsec(['f', 'a', 'l', 's', 'e' | Rest], false) :-
    !,
    parse_whitespace(Rest, []).

jsonparsec(['n', 'u', 'l', 'l' | Rest], null) :-
    !,
    parse_whitespace(Rest, []).


jsonparsec([], _).

% STRING PARSING

% parse_string/3
% Chars = lista contenente la sequenza "caratteri"
% I = stringa presente in Chars a partire dal primo elemento e racchiusa
% tra ""
% Rest = tutti i caratteri dopo il delimiter " di chiusura della stringa

parse_string(Chars, I, Rest) :-
    parse_string(Chars, [], I, Rest).


parse_string([C | Cs], CharsInvertiti, Stringa, Cs) :-
    C = '"',
    !,
    reverse(CharsInvertiti, Chars),
    string_chars(Stringa, Chars).

% dsSoFar contiene tutti i caratteri incontrati prima della chiusura
% della stringa.

% casi implementati per la lettura da file
% la lettura di una stringa da file gestisce caratteri come \n come
% due caratteri e non solo uno

parse_string(['\\' , '\"' | Ds], DsSoFar, Stringa, Chars) :-
    !,
    parse_string(Ds, ['"' | DsSoFar], Stringa, Chars).


parse_string(['\\' , 'n' | Ds], DsSoFar, Stringa, Chars) :-
    !,
    parse_string(Ds, [ '\n' | DsSoFar], Stringa, Chars).

parse_string(['\\' , 'b' | Ds], DsSoFar, Stringa, Chars) :-
    !,
    parse_string(Ds, [ '\b' | DsSoFar], Stringa, Chars).

parse_string(['\\' , 't' | Ds], DsSoFar, Stringa, Chars) :-
    !,
    parse_string(Ds, [ '\t' | DsSoFar], Stringa, Chars).

parse_string(['\\' , 'f' | Ds], DsSoFar, Stringa, Chars) :-
    !,
    parse_string(Ds, [ '\f' | DsSoFar], Stringa, Chars).

parse_string(['\\' , 'r' | Ds], DsSoFar, Stringa, Chars) :-
    !,
    parse_string(Ds, [ '\r' | DsSoFar], Stringa, Chars).

parse_string(['\\' , '\\' | Ds], DsSoFar, Stringa, Chars) :-
    !,
    parse_string(Ds, [ '\\' | DsSoFar], Stringa, Chars).

parse_string(['\\' , '/' | Ds], DsSoFar, Stringa, Chars) :-
    !,
    parse_string(Ds, [ '\\/' | DsSoFar], Stringa, Chars).


parse_string([D | Ds], DsSoFar, Stringa, Chars) :-
    !,
    parse_string(Ds, [D | DsSoFar], Stringa, Chars).


% NUMBER PARSING

% controllo segno

parse_number([C | Chars], N, Resto) :-
    C = '-',
    !,
    parse_number_unsigned(Chars, U, Resto),
    string_concat("-", U, Ns),
    number_string(N, Ns).

parse_number(Chars, N, Resto) :-
    parse_number_unsigned(Chars, N, Resto).

% caso in cui è presente la parte decimale ed esponente
% caso esponente con segno positivo

parse_number_unsigned(Chars, N, Resto) :-

    parse_integer(Chars, IntegerPart, [M | MoreChars]),
    M = '.',
    parse_integer(MoreChars, Decimal, [E, Sign | Exp]),
    to_lower(E, EcodeLower),
    char_code(El, EcodeLower),
    El = 'e',
    Sign = '+',
    !,
    parse_integer(Exp, ExpList, Resto),
    append(IntegerPart, ['.' | Decimal], P),
    append(P, ['e', '+' | ExpList], Tot),
    number_string(N, Tot).

% caso esponente con segno negativo

parse_number_unsigned(Chars, N, Resto) :-

    parse_integer(Chars, IntegerPart, [M | MoreChars]),
    M = '.',
    parse_integer(MoreChars, Decimal, [E, Sign | Exp]),
    to_lower(E, EcodeLower),
    char_code(El, EcodeLower),
    El = 'e',
    Sign = '-',
    !,
    parse_integer(Exp, ExpList, Resto),
    append(IntegerPart, ['.' | Decimal], P),
    append(P, ['e', '-' | ExpList], Tot),
    number_string(N, Tot).

% caso con esponente senza segno

parse_number_unsigned(Chars, N, Resto) :-
    parse_integer(Chars, IntegerPart, [M | MoreChars]),
    M = '.',
    parse_integer(MoreChars, Decimal, [E | Exp]),
    to_lower(E, EcodeLower),
    char_code(El, EcodeLower),
    El = 'e',
    !,
    parse_integer(Exp, ExpList, Resto),
    append(IntegerPart, ['.' | Decimal], P),
    append(P, ['e' | ExpList], Tot),
    number_string(N, Tot).

% caso in cui è presente la parte decimale e non esponente

parse_number_unsigned(Chars, N, Resto) :-

    parse_integer(Chars, IntegerPart, [M | MoreChars]),
    M = '.',
    !,
    parse_integer(MoreChars, Decimal, Resto),
    append(IntegerPart, ['.' | Decimal], Tot),
    number_string(N, Tot).

% caso in cui non è presente la parte decimale ed è presente l'exp
% caso esponente con segno positivo

parse_number_unsigned(Chars, N, Resto) :-

    parse_integer(Chars, IntegerPart, [E, Sign | Exp]),
    to_lower(E, EcodeLower),
    char_code(El, EcodeLower),
    El = 'e',
    Sign = '+',
    !,
    parse_integer(Exp, ExpList, Resto),
    append(IntegerPart, ['e', Sign | ExpList], Tot),
    number_string(N, Tot).

% caso esponente con segno negativo

parse_number_unsigned(Chars, N, Resto) :-

    parse_integer(Chars, IntegerPart, [E, Sign | Exp]),
    to_lower(E, EcodeLower),
    char_code(El, EcodeLower),
    El = 'e',
    Sign = '-',
    !,
    parse_integer(Exp, ExpList, Resto),
    append(IntegerPart, ['e', Sign | ExpList], Tot),
    number_string(N, Tot).

% caso esponente senza segno

parse_number_unsigned(Chars, N, Resto) :-
    parse_integer(Chars, IntegerPart, [E | Exp]),
    to_lower(E, EcodeLower),
    char_code(El, EcodeLower),
    El = 'e',
    !,
    parse_integer(Exp, ExpList, Resto),
    append(IntegerPart, ['e' | ExpList], Tot),
    number_string(N, Tot).

% caso in cui è presente solo la parte intera

parse_number_unsigned(Chars, N, Resto) :-
    parse_integer(Chars, IntegerPart, Resto),
    !,
    number_string(N, IntegerPart).


parse_integer(Chars, Digits, MoreChars) :-
    parse_integer(Chars, [], Digits, MoreChars).

parse_integer([D | Ds], DsSoFar, ICs, Rest) :-
    is_digit(D),
    !,
    parse_integer(Ds, [D | DsSoFar], ICs, Rest).

parse_integer([C | Cs], DsR, Digits, [C | Cs]) :-
    !,
    reverse(DsR, Digits).


parse_integer([], DsR, Digits, []) :-
    !,
    reverse(DsR, Digits).


% WHITESPACE PARSING

% parse_whitespace/2
% il predicato è vero se il secondo argomento
% è la lista nel primo argomento senza
% whitespace all'inizio

parse_whitespace([C | Chars], Delimiter) :-
    C = ' ',
    !,
    parse_whitespace(Chars, Delimiter).

parse_whitespace([C | Chars], Delimiter) :-
    C = '\n',
    !,
    parse_whitespace(Chars, Delimiter).

parse_whitespace([C | Chars], Delimiter) :-
    C = '\t',
    !,
    parse_whitespace(Chars, Delimiter).

parse_whitespace([C | Chars], Delimiter) :-
    C = '\r',
    !,
    parse_whitespace(Chars, Delimiter).

parse_whitespace([C | Rest], [C | Rest]) :- !.
parse_whitespace([C], [C]).
parse_whitespace([], []).


% implementazione jsonaccess


jsonaccess(jsonobj(_), [], _) :- !.

jsonaccess(jsonobj(Members), [Field, N], Result) :-
    number(N),
    search_member(Members, [Field], Array),
    Array = jsonarray(Elements),
    search_element(Elements, N, Result),
    !.

jsonaccess(jsonobj(Members), [Field, N | OtherFields], Result) :-
    number(N),
    search_member(Members, [Field], Array),
    Array = jsonarray(Elements),
    search_element(Elements, N, R),
    jsonaccess(R, OtherFields, Result),
    !.

jsonaccess(jsonobj(Members), [Field], Result) :-
    search_member(Members, [Field], Result), !.

jsonaccess(jsonobj(Members), Field, Result) :-
    string(Field),
    search_member(Members, [Field], Result), !.

jsonaccess(jsonobj(Members), [Field | OtherFields], Result) :-
    search_member(Members, [Field], R),
    jsonaccess(R, OtherFields, Result).

search_member([(Field, Result) | _], [Field], Result) :- !.

search_member([_ | Rest], [Field], Result) :-
    search_member(Rest, [Field], Result),
    !.

search_element([Result | _], Index, Result) :- Index = 0, !.

search_element([_ | RestElements], Index, Result) :-
    Index > 0,
    NewIndex is Index - 1,
    search_element(RestElements, NewIndex, Result).

% implementazione jsonread

jsonread(FileName, JSON) :-
    open(FileName, read, In),
    read_string(In, _, JsonStr),
    jsonparse(JsonStr, JSON),
    close(In).

% implementazione jsondump

jsondump(FileName, jsonobj(Members)) :-
    open(FileName, write, Out),
    write(Out, "{\n"),
    write_member(Members, Out, ['\t']),
    write(Out, "\n}"),
    close(Out), !.

write_member([], _, _) :- !.

write_member([(String, Value)], Out, Tabs) :-
    string_chars(S, Tabs),
    write(Out, S),
    writeq(Out, String),
    write(Out, " : "),
    write_value(Value, Out, Tabs),
    !.

write_member([(String, Value) | OtherMembers], Out, Tabs) :-
    string_chars(S, Tabs),
    write(Out, S),
    writeq(Out, String),
    write(Out, " : "),
    write_value(Value, Out, Tabs),
    write(Out, ",\n"),
    write_member(OtherMembers, Out, Tabs).

% caso stampa oggetto
write_value(jsonobj(M), Out, Tabs) :-
    write(Out, "{\n"),
    write_member(M, Out, ['\t' | Tabs]),
    write(Out, '\n'),
    string_chars(S, Tabs),
    write(Out, S),
    write(Out, "}"), !.

% caso stampa array

write_value(jsonarray(Elements), Out, Tabs) :-
    write(Out, "["),
    write_element(Elements, Out, Tabs),
    write(Out, "]"), !.

% stampa stringa

write_value(Value, Out, _) :-
    string(Value),
    !,
    writeq(Out, Value),
    !.

% stampa true, false e null

write_value(Value, Out, _) :-
    write(Out, Value).

write_element([], _, _) :- !.

write_element([E], Out, Tabs) :-
    E = jsonobj(_),
    write_value(E, Out, Tabs),
    !.


write_element([E | Es], Out, Tabs) :-
    E = jsonobj(_),
    write(Out, '\n'),
    string_chars(S, Tabs),
    write(Out, S),
    write_value(E, Out, Tabs),
    write(Out, ",\n "),
    string_chars(S, Tabs),
    write(Out, S),
    write_element(Es, Out, Tabs),
    !.

write_element([E], Out, _) :-
    write_value(E, Out, []),
    !.

write_element([E | Es], Out, Tabs) :-
    write_value(E, Out, []),
    write(Out, ", "),
    write_element(Es, Out, Tabs).

%%%% end of file -- jsonparse.pl
