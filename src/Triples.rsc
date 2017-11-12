module Triples
import util::Math;
import String;
import IO;
import Set;
import List;

syntax TripleQuery
	= "and" "(" {TripleQuery ","}* ")"
	| "or" "(" {TripleQuery ","}* ")"
	| "not" "(" TripleQuery ")"
	| "label" "(" TripleId ")"
	| "from" "(" TripleId ")"
	| "to" "(" TripleId ")"
	| "true"
	| "false"
	;
	
lexical TripleId
	= Ident: ![\ \t\n\f()\[\]0-9\"\'] (![#:\ \t\n\f()\[\]\"\'] | ([\\] ![]))*
	| Card: TripleIdNameChar+ ":" ([0-9]+|"*")     
	| Ord: TripleIdNameChar+ "#" ([0-9]+|"*")     
	| Int: [0-9]+
	; 

lexical TripleIdNameChar
	= [a-zA-Z]
	;
	
data Id 
	= uri(loc uri)
	| integer(int i)
	| character(int i)
	| cardinal(str name, int i)
	| ordinal(str name, int i)
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

Id valueOwner(str s) = ident(ident(root(), "values"), s);
public Id ownerOf(integer(x)) = valueOwner("integers");
public Id ownerOf(character(x)) = valueOwner("characters");
public Id ownerOf(cardinal(n,x)) = valueOwner("cardinals");
public Id ownerOf(ordinal(n,x)) = valueOwner("ordinals");
public Id ownerOf(rational(x)) = valueOwner("rationals");
public Id ownerOf(string(x)) = valueOwner("strings");
public Id ownerOf(root()) = root();
public Id ownerOf(uri(x)) = valueOwner("uris");
public Id ownerOf(ident(root(), x)) = root();
public Id ownerOf(ident(p:ident(root(),_), x)) = p;
public Id ownerOf(ident(parent, x)) = ownerOf(parent);
public Id ownerOf(this()) = this();
public Id ownerOf(ident(x)) = this();

public Id qualify(Id domain, Id base, Id i) = top-down visit(i) {
	case this() => base
	case ident(name) => ident(domain, name)
};

public Id MODELLING_ID = ident(root(), "modelling");
public Id CONFORMS_TO = ident(MODELLING_ID, "conformsTo");
public Id IDENTITY = ident(MODELLING_ID, "identity");
public Id NAME = ident(MODELLING_ID, "name");
public Id IS = ident(MODELLING_ID, "is");
public Id HAS = ident(MODELLING_ID, "has");
public Id PART_OF = ident(MODELLING_ID, "partOf");
public Id ONE_OF = ident(MODELLING_ID, "oneOf"); // xor
public Id ANY_OF = ident(MODELLING_ID, "anyOf"); // or
public Id ALL_OF = ident(MODELLING_ID, "allOf"); // and

public Graph newGraph(str name) {
	Graph g = {};
	g += <this(), IDENTITY, ident(root(), name)>;
	g += <this(), NAME, string(name)>;
	
	return g;
}

public Id newId(Graph g, str name) {
	return ident(getOne(g, this(), IDENTITY), name);
}
public Graph modelling = newGraph("modelling");

public set[Id] getAll(Graph g, Id from, Id label) = g[from][label];

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

public str escape(str s) = escape(s,
	("\"" : "\\\"", "\\":"\\\\",
	 "\b" : "\\b", "\f":"\\f", "\n":"\\n", "\r":"\\r", "\t":"\\t"));
public str unescape(str s) = s;
public loc toUri(integer(x)) = |values://integers/<"<x>">|;
public loc toUri(character(x)) = |values://characters/<"<x>">|;
public loc toUri(cardinal(n,x)) = |values://cardinals/<n>/<"<x>">|;
public loc toUri(ordinal(n,x)) = |values://ordinals/<n>/<"<x>">|;
public loc toUri(rational(x)) = |values://rationals/<"<numerator(x)>">/<"<denominator(x)>">|;
public loc toUri(string(x)) = |values://strings/<"<percentEncode(escape(x, ("/":"\\/", "\\" : "\\\\")))>">|;
public loc toUri(root()) = |values:///|;
public loc toUri(uri(x)) = x;
public loc toUri(ident(parent, x)) = toUri(parent) + x;
public loc toUri(this()) { throw "Unqualified Id: this()"; }
public loc toUri(ident(x)) { throw "Unqualified Id: ident(<x>)"; }

public str uriStyle = "query";  // or "fragment"

public str locToStr(loc l, str style = uriStyle) {
	str frag = "";
	str query = "";
	if(style == "fragment") {
		if(l.begin?) {
			frag += "<l.begin.line>:<l.begin.column>";
			if(l.end?) {
				frag += "-<l.end.line>:<l.end.column>";
			}		
		}
		if(l.offset? && l.length?) {
			frag += "@<l.offset>+<l.length>";
		}
	}
	else if(style == "query") {
		if(l.offset? && l.length?) {
			query = "offset=<l.offset>&length=<l.length>";
		}
		if(l.begin?) {
			frag = "line<l.begin.line>";
		}
	}

	if(l.fragment == "") {
		l.fragment = frag;
	}
	if(query != "") {
		l.query = l.query == "" ? query : "<l.query>&<query>";
	}
	return l.uri;
}

public loc strToLoc(str s) {
	loc l = toLocation(s);
	
	if(/^<pre1:.*>(&|^)offset=<offset:[0-9]+><post1:.*>$/ := l.query) {
		l.query = "<pre1><post1>";
		if(/^<pre2:.*>(&|^)length=<length:[0-9]+><post2:.*>$/ := l.query) {
			l.query = "<pre2><post2>";
			l = l(toInt(offset),toInt(length),<1,0>,<1,0>);
		}

		if(/^line[0-9]+$/ := l.fragment)
			l.fragment = "";
	}
	if(/^<bline:[0-9]+>:<bcol:[0-9]+>-<eline:[0-9]+>:<ecol:[0-9]+>@<offset:[0-9]+>\+<length:[0-9]+>$/ := l.fragment) {
		l = l(toInt(offset),toInt(length),<toInt(bline),toInt(bcol)>,<toInt(eline),toInt(ecol)>);
		l.fragment = "";		
	}
	
	return l;
}
	
public str toString(uri(x)) = "<x>";
public str toString(integer(x)) = "<x>";
public str toString(character(x)) = "\'<escape(stringChar(x))>\'";
public str toString(cardinal(n,x)) = "<n>=<x>";
public str toString(ordinal(n,x)) = "<n>#<x>";
public str toString(rational(x)) = "<x>";
public str toString(string(x)) = "\"<escape(x)>\"";
public str toString(ident(root(),x)) = "/<x>";
public str toString(ident(p,x)) = "<toString(p)>/<x>";
public str toString(ident(x)) = "<x>";
public str toString(root()) = "/";
public str toString(this()) = "@";
public str toString(<Id f, Id l, Id t>) = "<toString(f)> --<toString(l)>-\> <toString(t)>";
public str toString(Graph g) = intercalate("\n", [toString(x) | x <- sort(g)]);



public Id fromString(/^\|<x:.*>\|$/) = uri(toLocation(x));
public Id fromString(/^<x:[0-9]+>$/) = integer(toInt(x));
public Id fromString(/^\'<x:.*>\'$/) = character(charAt(unescape(x),0));
public Id fromString(/^<n:[a-zA-Z]+>=<x:[0-9]+>$/) = cardinal(n,toInt(x));
public Id fromString(/^<n:[a-zA-Z]+>#<x:[0-9]+>$/) = ordinal(n,toInt(x));
public Id fromString(/^<n:[0-9]+>r<d:[0-9]+>$/) = rational(toRat(toInt(n),toInt(d)));
public Id fromString(/^\"<x:.*>\"$/) = string(unescape(x));
public Id fromString(/^\/$/) = root();
public Id fromString(/^@$/) = this();
public Id fromString(/^\/<x:[^\/]+>$/) = ident(root(),x);
public Id fromString(/^<p:.+>\/<x:[^\/]+>$/) = ident(fromString(p),x);
public Id fromString(/^<x:.+>$/) = ident(x);
//public Id fromString(<Id f, Id l, Id t>) = "<toString(f)> --<toString(l)>-\> <toString(t)>";
//public Id fromString(Graph g) = intercalate("\n", [toString(x) | x <- sort(g)]);

public Id fromUri(loc u) {
	if(u.scheme == "values") {
		switch(u.authority) {
		case "integers": return integer(toInt(split("/", u.path)[1]));
		case "characters": return character(toInt(split("/", u.path)[1]));
		case "cardinals": return cardinal(split("/", u.path)[1], toInt(split("/", u.path)[2]));
		case "ordinals": return ordinal(split("/", u.path)[1], toInt(split("/", u.path)[2]));
		case "rationals": return rational(toRat(toInt(split("/", u.path)[1]),toInt(split("/", u.path)[2])));
		case "strings": return string(replaceAll(replaceAll(u.path[1..], "\\/", "/"), "\\\\", "\\"));
		}
	}
	else {
		return uri(u);
	}
}

str obj(str key, str val) = "{\"type\":\"<key>\", \"value\":\"<escape(val)>\"}";
str jsonObj(map[str,str] obj) = "{<intercalate(", ", ["\"<escape(k)>\":<obj[k]>" | k <- obj])>}";
str jsonObj(list[str] obj) = "[<intercalate(", ", [k | k <- obj])>]";
str jsonStr(str obj) = "\"<escape(obj)>\"";
public str toJson(uri(x)) = obj("uri", locToStr(x));
public str toJson(character(x)) = obj("character", escape(stringChar(x)));
public str toJson(integer(x)) = "{\"type\":\"integer\", \"value\":<x>}";
public str toJson(cardinal(n,x)) = "{\"type\":\"cardinal\", \"name\":\"<escape(n)>\", \"value\":<x>}";
public str toJson(ordinal(n,x)) = "{\"type\":\"ordinal\", \"name\":\"<escape(n)>\", \"value\":<x>}";
public str toJson(rational(x)) = "{\"type\":\"rational\", \"value\":[<numerator(x)>,<denominator(x)>]}";
public str toJson(string(x)) = "\"<escape(x)>\"";
public str toJson(i:ident(p,x)) = obj("identity", toString(i));
public str toJson(i:ident(x)) = obj("identity", toString(i));
public str toJson(root()) = obj("identity", "/");
public str toJson(this()) = obj("identity", "@");
public str toJson(<Id f, Id l, Id t>) = "{\"<toString(f)>\" : {\"<toString(l)>\":<toJson(t)>}}";
public str toJson(<Id l, Id t>) = "\"<toString(l)>\" : <toJson(t)>";
public bool jsonSimplified = true;
public str toJson(rel[Id,Id] subG) {
	vals = for(i <- subG<0>) {
		tos = subG[i];
		if(jsonSimplified && {t} := tos) {
			append "\t\"<escape(toString(i))>\" : \"<escape(toString(t))>\"";
		}
		else {
			append "\t\"<escape(toString(i))>\" : [<intercalate(", ", ["\"<escape(toString(e))>\"" | e <- subG[i]])>]";
		}
	}
	return "{\n<intercalate(",\n", vals)>\n\t}";
}
public str toJson(Graph g) {
	list[str] r;
	list[str] vals;
	r = for(k <- sort(g<0>))  {
		append "\"<escape(toString(k))>\" : <toJson(g[k])>\n";
	}
 	return "{\n<intercalate(",\n", r)>\n}\n";
}

public str toCyto(Id id) = jsonObj(toCytoMap(id));
public map[str,str] toCytoMap(I:uri(x)) = (("id":jsonStr(toString(I)), "type":jsonStr("uri"), "uri":jsonStr(locToStr(x))));
public map[str,str] toCytoMap(I:character(x)) = (("id":jsonStr(toString(I)), "type":jsonStr("character"), "intValue":"<x>", "strValue":jsonStr(stringChar(x))));
public map[str,str] toCytoMap(I:integer(x)) = (("id":jsonStr(toString(I)), "type":jsonStr("integer"), "intValue":"<x>"));
public map[str,str] toCytoMap(I:cardinal(n,x)) = (("id":jsonStr(toString(I)), "type":jsonStr("cardinal"), "name":jsonStr(n), "intValue":"<x>"));
public map[str,str] toCytoMap(I:ordinal(n,x)) = (("id":jsonStr(toString(I)), "type":jsonStr("ordinal"), "name":jsonStr(n), "intValue":"<x>"));
public map[str,str] toCytoMap(I:rational(x)) = (("id":jsonStr(toString(I)), "type":jsonStr("rational"), "value":"[<numerator(x)>,<denominator(x)>]"));
public map[str,str] toCytoMap(I:string(x)) = (("id":jsonStr(toString(I)), "type":jsonStr("string"), "strValue":jsonStr(x)));
public map[str,str] toCytoMap(I:ident(p,x)) = (("id":jsonStr(toString(I)), "type":jsonStr("identity")));
public map[str,str] toCytoMap(I:ident(x)) = (("id":jsonStr(toString(I)), "type":jsonStr("identity")));
public map[str,str] toCytoMap(I:root()) = (("id":jsonStr(toString(I)), "type":jsonStr("identity")));
public map[str,str] toCytoMap(I:this()) = (("id":jsonStr(toString(I)), "type":jsonStr("identity")));
//public map[str,str] toCytoMap(<Id f, Id l, Id t>) = "{\"<toString(f)>\" : {\"<toString(l)>\":<toCytoMap(t)>}}";
//public map[str,str] toCytoMap(<Id l, Id t>) = "\"<toString(l)>\" : <toCytoMap(t)>";
public str toCyto(Graph g, set[Id] unlink = {}) {
	list[str] r;
	list[str] vals;
	set[Id] nodes = g<0>;
	r = for(k <- nodes) {
		s = toString(k);
		map[str,str] cm = toCytoMap(k);
		cm["local"] = "true";
		cm["owner"] = jsonStr(toString(ownerOf(k)));
		for(l <- g[k]<0>) {
			cm[toString(l)] = "[<intercalate(", ", [jsonStr(toString(t)) | t <- g[k][l]])>]";
		}
		append jsonObj(("group":jsonStr("nodes"), "data":jsonObj(cm)));
	}
	g = {<f,l,t> | <f,l,t> <- g, l notin unlink};
	set[Id] targets = g<2>;
	set[Id] labels = g<1>;
	r += for(k <- targets) {
		if(k notin nodes) {
			map[str,str] cm = toCytoMap(k);
			cm["local"] = "false";
			cm["owner"] = jsonStr(toString(ownerOf(k)));
			append jsonObj(("group":jsonStr("nodes"), "data":jsonObj(cm)));
		}
	}
	r += for(<f,l,t> <- g) {
		<fStr,lStr,tStr> = <toString(f),toString(l),toString(t)>;
		map[str,str] cm = toCytoMap(l);
		cm["id"] = jsonStr("<fStr>–<lStr>→<tStr>");
		cm["label"] = jsonStr(lStr);
		cm["source"] = jsonStr(fStr);
		cm["target"] = jsonStr(tStr);
		cm["local"] = f in nodes && t in nodes ? "true" : "false";
		cm["owner"] = jsonStr(toString(ownerOf(l)));
		append jsonObj(("group":jsonStr("edges"), "data":jsonObj(cm)));
	}
 	return "[\n<intercalate(",\n", r)>\n]\n";
}



public Graph qualifyGraph(Graph g) = qualifyGraph(g, getOne(g, this(), IDENTITY));

public Graph qualifyGraph(Graph g, Id id) = visit(g) {
	case this() => id
	case ident(s) => ident(id, s)
};

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
	return fromUri(toUri(ordinal("foo", i))).i == i; 
}

test bool uriConversionStr(str s) {
	return fromUri(toUri(string(s))).s == s; 
}

test bool uriConversionUri(loc l) {
	return fromUri(toUri(uri(l))).uri == l; 
}

test bool uriConversionUri(Id i) {
	return fromUri(toUri(i)) == i; 
}

test bool locToStrToLoc(loc l) {
	return strToLoc(locToStr(l, style="fragment")) == l;
}
