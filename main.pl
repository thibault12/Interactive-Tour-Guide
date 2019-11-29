:- use_module(library(http/http_open)).
:- use_module(library(http/json)).
:- use_module(library(http/json_convert)).
:- dynamic(found/2).

%% Constants
%% 
api_key('bearer 8dlgFpYOoxBynLkOIFGAL7QIuHn-7t23V9hKJEtJQzESjn0c80hUGP09Zqg9WhQ-JI_tM2c5cOPB8XnCDfHQu1R1cGMbpXXcPWrmILlfS_uPG7u9VK45vPkUNE3SXXYx').
base_url('https://api.yelp.com/v3/businesses/search?term=').
location_url('&location=').
limit_url('&limit=').

%% API
%% 
make_api_call(Url) :-
  api_key(Key),
  http_open(Url, In_stream,
      [request_header('Authorization'=Key)]),
  json_read_dict(In_stream, Dict),
  close(In_stream),
  access_json_array(Dict, R),
    traverse_json_array(R,S).

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
noun_phrase(L0, Subject, Object, Limit) :-
    det(L0, L1, Limit),
    noun(L1, Subject, End),
    ending(End, Object).

noun([Subject | L1], Subject, End) :-
    reln(L1, End).

reln([near | End], End).
reln([in | End], End).
reln([close, to | End], End).
reln([around | End], End).

ending([Object | End], Object) :- 
    member(End,[[],['?'],['.']]).

det([a | R], R, 1).
det([an | R], R, 1).
det([the | R], R, 1).
det([two | R], R, 2).
det([three | R], R, 3).
det([some | R], R, 5).

user_query([what, is | L0], Subject, Object, Limit) :-
    noun_phrase(L0, Subject, Object, Limit).
user_query([what, are | L0], Subject, Object, Limit) :-
    noun_phrase(L0, Subject, Object, Limit).
user_query([give, me | L0], Subject, Object, Limit) :-
    noun_phrase(L0, Subject, Object, Limit).
user_query([i, want | L0], Subject, Object, Limit) :-
    noun_phrase(L0, Subject, Object, Limit).
user_query([i, am, looking, for | L0], Subject, Object, Limit) :-
    noun_phrase(L0, Subject, Object, Limit).

%% Building the query
%% 
build_url(Subject, Object, Count, Url) :- 
  base_url(X),
  string_concat(X, Subject, Y),
  location_url(L),
  string_concat(Y, L, Yl),
  string_concat(Yl, Object, U),
  limit_url(Li),
  string_concat(U, Li, Ur),
  string_concat(Ur, Count, Url).

%% Program starts here!
%% 
q() :-
    write("Ask me: "), flush_output(current_output),
    readln(User_input),
    maplist(downcase_atom, User_input, Lowercase_atoms),
    user_query(Lowercase_atoms, Subject, Object, Limit),
    build_url(Subject, Object, Limit, Url),
    write('Suggestions for your request: '),
    make_api_call(Url).
