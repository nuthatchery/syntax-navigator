module Triples
import util::Math;
import String;
import IO;
data Id 
	= uri(loc uri)
	| integer(int i)
	| ordinal(int i)
	| rational(rat r)
	| string(str s)
	| this()
	| root()
	| ident(str name)
	| ident(Id parent, str name)
	;


public Id Id(int i) = integer(i);
public Id Id(rat r) = rational(r);
public Id Id(str s) = string(s);
public Id Id(loc u) = uri(u);

alias Graph = rel[Id,Id,Id];


public Id MODELLING_ID = ident(root(), "modelling");
public Id CONFORMS_TO = ident(MODELLING_ID, "conformsTo");
public Id IDENTITY = ident(MODELLING_ID, "identity");
public Id NAME = ident(MODELLING_ID, "name");

public Graph newGraph(str name) {
	Graph g = {};
	g += <this(), IDENTITY, ident(root(), name)>;
	g += <this(), NAME, string(name)>;
	
	return g;
}

public Graph modelling = newGraph("modelling");

public Id getAll(Graph g, Id from, Id label) = g[from][label];

public Id getOne(Graph g, Id from, Id label) {
	xs = g[from][label];
	if({x} := xs)
		return x;
	else if({} := xs)
		throw "not found: <from> --<label>-\> <xs>";
	else
		throw "ambiguous: <from> --<label>-\> <xs>";
}

public set[Id] getLabels(Graph g, Id from) = g[from]<0>;

public loc toUri(integer(x)) = |values://integers/<"<x>">|;
public loc toUri(ordinal(x)) = |values://ordinals/<"<x>">|;
public loc toUri(rational(x)) = |values://rationals/<"<numerator(x)>">/<"<denominator(x)>">|;
public loc toUri(string(x)) = |values://strings/<"<percentEncode(escape(x, ("/":"\\/", "\\" : "\\\\")))>">|;
public loc toUri(uri(x)) = x;
	
public Id fromUri(loc u) {
	if(u.scheme == "values") {
		switch(u.authority) {
		case "integers": return integer(toInt(split("/", u.path)[1]));
		case "ordinals": return ordinal(toInt(split("/", u.path)[1]));
		case "rationals": return rational(toRat(toInt(split("/", u.path)[1]),toInt(split("/", u.path)[2])));
		case "strings": return string(replaceAll(replaceAll(u.path[1..], "\\/", "/"), "\\\\", "\\"));
		}
	}
	else {
		return uri(u);
	}
}


@doc{
.Synopsis
Return encoded characters as a list of bytes.
.Description
Return a list of the bytes representing `s`, encoded in `charset`.

Also see <<String-chars>>, <<String-stringChars>>, <<IO-charsets>> and <<IO-canEncode>>.

.Examples
[source,rascal-shell]
----
import String;
chars("abc","UTF-8");
stringChars(chars("åbø", "UTF-8"), "UTF-8") == "åbø";
----
}
@javaClass{library.Triples}
public java list[int] chars(str s, str charset);

@javaClass{library.Triples}
public java str stringChars(list[int] chars, str charset);

@doc{
.Synopsis
Percent-encodes a string.
.Description 
Percent encoding (aka URL-encoding) replaces all reserved characters as well
as all non-unreserved characters with the UTF-8 representation of the character as
a sequence of %xx bytes.
 
Percent encoding is specified in RFC 3986.
 
This method will also handle multi-word characters correctly (i.e., Unicode characters beyond 65535).

.Examples
[source,rascal-shell]
----
import String;
percentEncode("føø");
percentEncode("\ud801\udc00") == "%F0%90%90%80";
---- 
}
@javaClass{library.Triples}
public java str percentEncode(str s);

@javaClass{library.Triples}
public java str percentDecode(str s);

test bool uriConversionRat(rat r) {
	return fromUri(toUri(rational(r))).r == r; 
}

test bool uriConversionInt(int i) {
	return fromUri(toUri(integer(i))).i == i; 
}

test bool uriConversionOrd(int i) {
	i = abs(i);
	return fromUri(toUri(ordinal(i))).i == i; 
}

test bool uriConversionStr(str s) {
	return fromUri(toUri(string(s))).s == s; 
}

test bool uriConversionUri(loc l) {
	return fromUri(toUri(uri(l))).uri == l; 
}

