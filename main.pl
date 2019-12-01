:- use_module(library(http/http_open)).
:- use_module(library(http/json)).

%% Constants
%% 
api_key('bearer 8dlgFpYOoxBynLkOIFGAL7QIuHn-7t23V9hKJEtJQzESjn0c80hUGP09Zqg9WhQ-JI_tM2c5cOPB8XnCDfHQu1R1cGMbpXXcPWrmILlfS_uPG7u9VK45vPkUNE3SXXYx').
base_url('https://api.yelp.com/v3/businesses/search?term=').
location_url('&location=').
limit_url('&limit=').
price_url('&price=').

%% API
%% 
make_api_call(Url) :-
  api_key(Key),
  http_open(Url, In_stream,
      [request_header('Authorization'=Key)]),
  json_read_dict(In_stream, Dict),
  close(In_stream),
  access_json_array(Dict, R),
    traverse_json_array(R,_).

%% Building the query
%% 
handle_punctuation(R) :- 
  member(_,R),
  write(', ').
handle_punctuation(R) :-
  not(member(_,R)),
  write('.').

access_json_array(X, X.businesses).

traverse_json_array([], _).
traverse_json_array([H|R], H) :-
  W = H.name,
  write(W),
  handle_punctuation(R),
  traverse_json_array(R, _).

%% Dictionaries to parse user input
%% 
noun_phrase(L0, Adj, Subject, Object, Limit) :-
    det(L0, L1, Limit),
    adj(L1, Adj, L2),
    noun(L2, Subject, End),
    ending(End, Object).

adj([expensive | L], '3,4', L).
adj([fancy | L], '3,4', L).
adj([pricey | L], '3,4', L).
adj([nice | L], '3', L).
adj([cheap | L], '1', L).
adj([affordable | L], '2', L).
adj(L, '1,2,3,4', L).

noun([Subject | L1], Subject, End) :-
    reln(L1, End).

reln([near | End], End).
reln([in | End], End).
reln([close, to | End], End).
reln([around | End], End).

ending([Object | End], Object) :- 
    member(End,[[],['?'],['.'], ['!']]).

det([a | R], R, 1).
det([an | R], R, 1).
det([the | R], R, 1).
det([two | R], R, 2).
det(['2' | R], R, 2).
det([three | R], R, 3).
det(['3' | R], R, 3).
det(['4' | R], R, 4).
det(['5' | R], R, 5).
det([some | R], R, 5).

user_query([what, is | L0], Adj, Subject, Object, Limit) :-
    noun_phrase(L0, Adj, Subject, Object, Limit).
user_query([what, are | L0], Adj, Subject, Object, Limit) :-
    noun_phrase(L0, Adj, Subject, Object, Limit).
user_query([give, me | L0], Adj, Subject, Object, Limit) :-
    noun_phrase(L0, Adj, Subject, Object, Limit).
user_query([give | L0], Adj, Subject, Object, Limit) :-
    noun_phrase(L0, Adj, Subject, Object, Limit).
user_query([i, want | L0], Adj, Subject, Object, Limit) :-
    noun_phrase(L0, Adj, Subject, Object, Limit).
user_query([i, am, looking, for | L0], Adj, Subject, Object, Limit) :-
    noun_phrase(L0, Adj, Subject, Object, Limit).


%% Building the query
%% 
handle_price(Url, Adj, Final) :- 
  price_url(P),
  string_concat(Url, P, Temp),
  string_concat(Temp, Adj, Final).

handle_price(Url, Adj, Url) :-
  member(Adj, [[]]),
  write('Adj is empty').

build_url(Adj, Subject, Object, Count, Final) :- 
  base_url(X),
  string_concat(X, Subject, Y),
  location_url(L),
  string_concat(Y, L, Yl),
  string_concat(Yl, Object, U),
  limit_url(Li),
  string_concat(U, Li, Ur),
  string_concat(Ur, Count, Url),
  handle_price(Url, Adj, Final).

%% Program starts here!
%% 
%% Example queries
%% 
%% What are five restaurants in Vancouver?
%% Give me two museums in Chicago!
%% 
q :-
    write("Ask me: "), flush_output(current_output),
    readln(User_input),
    maplist(downcase_atom, User_input, Lowercase_atoms),
    user_query(Lowercase_atoms, Adj, Subject, Object, Limit),
    build_url(Adj, Subject, Object, Limit, Url),
    write('Suggestions for your request: '),
    make_api_call(Url).

run :-
  not(q),
  write('Sorry we did not quite get that, please try again!').

run.
