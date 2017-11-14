module Grammars
import List;
import Productions;
import ParseTree;
import String;
import Grammar;
import util::Reflective;
import lang::rascal::grammar::definition::Modules;
import lang::rascal::grammar::definition::Layout;
import lang::rascal::grammar::definition::Names;
import lang::rascal::format::Escape;
import lang::rascal::\syntax::Rascal;
import IO;
import Triples;

alias SymTable = map[Symbol,Id];
alias ProdTable = map[Production,Id];

public Graph metaGraph = newGraph("metaGraph");

public Graph metaGrammar = newGraph("metaGrammar");
	
public Id GRAMMAR = newId(metaGrammar, "grammar");
public Id SORT = newId(metaGrammar, "sort");
public Id START = newId(metaGrammar, "start");
public Id STOP = newId(metaGrammar, "stop");
public Id CF_SORT = newId(metaGrammar, "cfSort");
public Id LEX_SORT = newId(metaGrammar, "lexSort");
public Id LAYOUT_SORT = newId(metaGrammar, "layoutSort");
public Id KW_SORT = newId(metaGrammar, "kwSort");
public Id SYMBOL = newId(metaGrammar, "symbol");
public Id PRODUCTION = newId(metaGrammar, "production");
public Id CF_SYM = newId(metaGrammar, "contextFree");
public Id LEX_SYM = newId(metaGrammar, "lexical");
public Id LAYOUT_SYM = newId(metaGrammar, "layout");
public Id KW_SYM = newId(metaGrammar, "keyword");
public Id LIT_SYM = newId(metaGrammar, "literal");
public Id CILIT_SYM = ident(newId(metaGrammar, "literal"), "insensitive");
public Id CC_SYM = newId(metaGrammar, "charClass");
public Id EMPTY_SYM = newId(metaGrammar, "empty");
public Id OPT_SYM = newId(metaGrammar, "optional");
public Id ITER_SYM = newId(metaGrammar, "iterate");
public Id REPEAT_MIN = newId(metaGrammar, "repeatMin");
public Id REPEAT_MAX = newId(metaGrammar, "repeatMax");
public Id SEPARATE_BY = newId(metaGrammar, "separateBy");
public Id ALTERNATIVES = newId(metaGrammar, "alternatives");
public Id SEQUENCE = newId(metaGrammar, "sequence");
public Id SOURCE = newId(metaGrammar, "source");
public Id STRING_VALUE = newId(metaGrammar, "stringValue");
public Id ELEMENT = newId(metaGrammar, "element");
public Id DEFINES = newId(metaGrammar, "defines");
public Id LABEL = newId(metaGrammar, "label");
public Id LABELLED = newId(metaGrammar, "labelled");
public Id NEXT = newId(metaGrammar, "next");
public Id BINDS_TO = newId(metaGrammar, "bindsTo");
public Id REFERS_TO = newId(metaGrammar, "refersTo");


Id nextId(this(), int childNum) = ident(".<childNum>");
Id nextId(ident(parent, old), int childNum) = ident(parent, "<old>.<childNum>");
Id nextId(ident(old), int childNum) = ident("<old>.<childNum>");
Id nextId(ident(parent, old), int childNum) = ident(parent, "<old>.<childNum>");
Id nextId(this(), str childNum) = ident(".<childNum>");
Id nextId(ident(parent, old), str childNum) = ident(parent, "<old>.<childNum>");
Id nextId(ident(old), str childNum) = ident("<old>.<childNum>");
Id nextId(ident(parent, old), str childNum) = ident(parent, "<old>.<childNum>");

public tuple[Graph,map[Production,Id]] loadGrammar(loc grammarModule) {
	Module m = parseModule(grammarModule);
	<n,_,_> = getModuleMetaInf(m);
	set[SyntaxDefinition] syntaxDefs = getModuleSyntaxDefinitions(m);
	Grammar gr = resolve(Productions::syntax2grammar(syntaxDefs));
	<nm, imps, exts> = getModuleMetaInf(m);
  	gd = \definition(nm, (nm:\module(nm, {}, {}, gr)));	
	gd = \layouts(gd);
	gr = fuse(gd);
	return grammarToGraph(gr, n);
}


public tuple[Graph, map[Production,Id]] grammarToGraph(Grammar gr, str name) {
	Graph g = newGraph(name);
	ProdTable prodTable = ();	
	SymTable symTable = ();
	id = this();
	
	g += <this(), CONFORMS_TO, GRAMMAR>;
	prodTable[\others(\start(\sort("$thisGrammar$")))] = this();
	
	int i = 0;	
	for(s <- gr.starts) {
		childId = nextId(id, i);
		<childId, symTable> = symToId(s, childId, symTable);
		g += <this(), START, childId>;
	}

	i = 0;	
	for(s <- gr.rules) {
		childId = nextId(id, i);
		<childId, symTable> = symToId(s, childId, symTable);
		g += <this(), ordinal("/metaGrammar/bindsTo", i), childId>;

//		println("<s>: <gr.rules[s]>");
		<g,symTable,tails, prodTable> = prodToGraph(gr.rules[s], childId, g, symTable, {}, prodTable);
		endId = nextId(childId, "end");
		g += <endId, CONFORMS_TO, SYMBOL>;
		g += <endId, CONFORMS_TO, STOP>;
		for(t <- tails)
			g += <t, NEXT, endId>;
		i += 1;
	}
	return <g, qualifyValue(prodTable, g)>;
}
public tuple[Graph,SymTable,set[Id], map[Production,Id]] prodToGraph(P:choice(_,{p}), Id id, Graph g, SymTable symTable, set[Id] tails, ProdTable prodTable)
	= prodToGraph(p, id, g, symTable, tails, prodTable);

public tuple[Graph,SymTable,set[Id], map[Production,Id]] prodToGraph(P:choice(s,alts), Id id, Graph g, SymTable symTable, set[Id] tails, ProdTable prodTable) {
	g += <id, CONFORMS_TO, PRODUCTION>;
	g += <id, CONFORMS_TO, SYMBOL>;
	g += <id, NAME, string("<sym2userName(s)>→")>;
	int i = 0;

	//childId = nextId(id, 0);
	//<childId, symTable> = symToId(s, childId, symTable);
	//g += <id, DEFINES, childId>;
	//<g, symTable> = symToGraph(s, childId, g, symTable);

	i += 1;
	tails = {};
	set[Id] last = {id};
	for(p <- alts) {
		childId = nextId(id, i);
		g += <id, ordinal("/metaGrammar/bindsTo", i), childId>;
		g += <id, NEXT, childId>;
		//g += <childId, DEFINES, id>;
		<g, symTable,ts, prodTable> = prodToGraph(p, childId, g, symTable, last, prodTable);
		tails += ts;
		last = ts;
		i += 1;
	}
	return <g, symTable, tails, prodTable>;
}
public tuple[Graph,SymTable,set[Id], map[Production,Id]] prodToGraph(P:prod(s,syms,_), Id id, Graph g, SymTable symTable, set[Id] tails, ProdTable prodTable) {
	//<id, symTable> = symToId(s, id, symTable);
	g += <id, CONFORMS_TO, PRODUCTION>;
	g += <id, CONFORMS_TO, SYMBOL>;
	g += <id, NAME, string("<sym2userName(s)>→")>;
//	g += <id, STRING_VALUE, string(prodToStr(P))>;
	if(P@\loc?) {
		g += <id, SOURCE, uri(P@\loc)>;
	}
	//childId = nextId(id, 0);
	//<childId, symTable> = symToId(s, childId, symTable);
	//g += <id, DEFINES, childId>;
	//<g, symTable> = symToGraph(s, childId, g, symTable);
	
	int i = 0;
	tails = {id};
	set[Id] last = {id};
	for(p <- syms) {
		childId = nextId(id, i);
		//<childId, symTable> = symToId(p, childId, symTable);
		for(t <- tails) {
			g += <t, NEXT, childId>;
		}
		g += <id, ordinal("/metaGrammar/element", i), childId>;
		if(label(n,_) := p) {
			g += <id, string(n), childId>;
		}
		<g, symTable,tails, prodTable> = symToGraph(p, childId, g, symTable, last, prodTable);
		last = tails;
		i += 1;
	}
	return <g, symTable, tails, prodTable>;
}

public tuple[Graph,SymTable,set[Id], map[Production,Id]] symToGraph(S:alt({s}), Id id, Graph g, SymTable symTable, set[Id] tails, ProdTable prodTable)
	= symToGraph(s, id, g, symTable, tails, prodTable);
	
public tuple[Graph,SymTable,set[Id], map[Production,Id]] symToGraph(S:alt(alts), Id id, Graph g, SymTable symTable, set[Id] tails, ProdTable prodTable) {
	g += <id, CONFORMS_TO, SYMBOL>;
	g += <id, IS, ALTERNATIVES>;
	//g += <id, NAME, string("…|…")>;
	int i = 0;
	tails = {};
	for(p <- alts) {
		childId = nextId(id, i);
		//<childId, symTable> = symToId(p, childId, symTable);
		g += <id, ELEMENT, childId>;
		if(label(n,_) := p) {
			g += <id, string(n), childId>;
		}
		g += <id, NEXT, childId>;
		<g, symTable, tl, prodTable> = symToGraph(p, childId, g, symTable, {id}, prodTable);
		tails += tl;
		
		i += 1;
	}
	return <g, symTable, tails, prodTable>;
}

public tuple[Graph,SymTable,set[Id], map[Production,Id]] symToGraph(S:seq([s]), Id id, Graph g, SymTable symTable, set[Id] tails, ProdTable prodTable)
	= symToGraph(s, id, g, symTable, tails, prodTable);

public tuple[Graph,SymTable,set[Id], map[Production,Id]] symToGraph(S:seq(syms), Id id, Graph g, SymTable symTable, set[Id] tails, ProdTable prodTable) {
	g += <id, CONFORMS_TO, SYMBOL>;
	g += <id, IS, SEQUENCE>;
	//g += <id, NAME, string("…,…")>;
	int i = 0;
	tails = {id};
	set[Id] last = {id};
	for(p <- syms) {
		childId = nextId(id, i);
		//<childId, symTable> = symToId(p, childId, symTable);
		g += <id, ordinal("/metaGrammar/element", i), childId>;
		for(t <- tails) {
			g += <t, NEXT, childId>;
		}
		if(label(n,_) := p) {
			g += <id, string(n), childId>;
		}
		<g, symTable, tails, prodTable> = symToGraph(p, childId, g, symTable, last, prodTable);
		last = tails;
		i += 1;
	}
	return <g, symTable, tails, prodTable>;
}

public tuple[Graph,SymTable,set[Id], map[Production,Id]] symToGraph(S:iter(Symbol s), Id id, Graph g, SymTable symTable, set[Id] tails, ProdTable prodTable)
	= iter(1, -1, [], s, id, g, symTable, tails, prodTable);

public tuple[Graph,SymTable,set[Id], map[Production,Id]] symToGraph(S:\iter-star(Symbol s), Id id, Graph g, SymTable symTable, set[Id] tails, ProdTable prodTable)
	= iter(0, -1, [], s, id, g, symTable, tails, prodTable);

public tuple[Graph,SymTable,set[Id], map[Production,Id]] symToGraph(S:\iter-seps(Symbol s, list[Symbol] seps), Id id, Graph g, SymTable symTable, set[Id] tails, ProdTable prodTable)
	= iter(1, -1, seps, s, id, g, symTable, tails, prodTable);

public tuple[Graph,SymTable,set[Id], map[Production,Id]] symToGraph(S:\iter-star-seps(Symbol s, list[Symbol] seps), Id id, Graph g, SymTable symTable, set[Id] tails, ProdTable prodTable)
	= iter(0, -1, seps, s, id, g, symTable, tails, prodTable);


public tuple[Graph,SymTable,set[Id], map[Production,Id]] iter(int min, int max, list[Symbol] seps, Symbol s, Id id, Graph g, SymTable symTable, set[Id] tails, ProdTable prodTable) {
	g += <id, IS, ITER_SYM>;
	g += <id, REPEAT_MIN, integer(min)>;
	if(max < 0) {
		g += <id, REPEAT_MAX, uri(|values://integer/infinity|)>;
	}
	else {
		g += <id, REPEAT_MAX, integer(max)>;
	}
	
	<g, symTable, symTails, prodTable> = symToGraph(s, id, g, symTable, {id}, prodTable);

	set[Id] iterTails = {};
	set[Id] last = symTails;
	Id sepId;
	if(seps != []) {
		sep = size(seps) == 1 ? seps[0] : seq(seps);
		sepId = nextId(id, "sep");
		//<childId, symTable> = symToId(sep, childId, symTable);
		<g, symTable, iterTails, prodTable> = symToGraph(sep, sepId, g, symTable, last, prodTable);
		last = iterTails;
		g += <id, SEPARATE_BY, sepId>;
		g += <sepId, NEXT, id>;
	}

	for(t <- symTails) {
		if(seps != [])
			g += <t, NEXT, sepId>;
		else
			g += <t, NEXT, id>;
	}
	
	if(min == 0)
		symTails += tails;
		
	childName = "";
	if({Id i:string(n)} := g[id][NAME]) {
		g -= <id, NAME, i>;
		childName = n;
	}
	if(seps != [])
		childName = "{<childName>}";
	if(min == 0 && max == -1)
		childName = "<childName>*";
	else if(min == 1 && max == -1)
		childName = "<childName>+";
	else
		childName = "<childName>{<min>,<max>}";
	g += <id, NAME, string(childName)>; 
	
	println(symTails);
	return <g, symTable, symTails, prodTable>;
}

public tuple[Graph,SymTable,set[Id], map[Production,Id]] symToGraph(S:\char-class(rng), Id id, Graph g, SymTable symTable, set[Id] tails, ProdTable prodTable) {
	g += <id, CONFORMS_TO, SYMBOL>;
	g += <id, IS, ALTERNATIVES>;
	g += <id, NAME, string(printSymbol(S,false))>;
	for(range(f,t) <- rng) {
		if(f == t) {
			rId = uri(|values://characters/<"<f>">|);
			g += <id, ELEMENT, rId>;
			if(g[rId][NAME] == {})
				g += <rId, NAME, string("[<makeCharClassChar(f)>]")>;
		}
		else {
			rId = uri(|values://characters/<"<f>">/to/<"<t>">|);
			g += <id, ELEMENT, rId>;
			if(g[rId][NAME] == {})
				g += <rId, NAME, string("[<makeCharClassChar(f)>-<makeCharClassChar(t)>]")>;
		}
	}
	return <g, symTable, {id}, prodTable>;
}

public tuple[Graph,SymTable,set[Id], map[Production,Id]] symToGraph(S:\label(l, s), Id id, Graph g, SymTable symTable, set[Id] tails, ProdTable prodTable) {
	g += <id, LABEL, string(l)>;
	g += <id, IS, LABELLED>;
	<g, symTable, tails, prodTable> = symToGraph(s, id, g, symTable, tails, prodTable);
	if({Id i:string(n)} := g[id][NAME]) {
		g -= <id, NAME, i>;
		g += <id, NAME, string("<l>: <n>")>; 
	}
	return <g, symTable, tails, prodTable>;
}

public tuple[Graph,SymTable,set[Id], map[Production,Id]] symToGraph(S:\lex(s), Id id, Graph g, SymTable symTable, set[Id] tails, ProdTable prodTable)
	= basicSymToGraph(S, s, LEX_SYM, id, g, symTable, prodTable);
public tuple[Graph,SymTable,set[Id], map[Production,Id]] symToGraph(S:\sort(s), Id id, Graph g, SymTable symTable, set[Id] tails, ProdTable prodTable)
	= basicSymToGraph(S, s, CF_SYM, id, g, symTable, prodTable);
public tuple[Graph,SymTable,set[Id], map[Production,Id]] symToGraph(S:\lit(s), Id id, Graph g, SymTable symTable, set[Id] tails, ProdTable prodTable)
	= basicSymToGraph(S, s, LIT_SYM, id, g, symTable, prodTable);
public tuple[Graph,SymTable,set[Id], map[Production,Id]] symToGraph(S:\cilit(s), Id id, Graph g, SymTable symTable, set[Id] tails, ProdTable prodTable)
	= basicSymToGraph(S, s, CILIT_SYM, id, g, symTable, prodTable);
public tuple[Graph,SymTable,set[Id], map[Production,Id]] symToGraph(S:\keywords(s), Id id, Graph g, SymTable symTable, set[Id] tails, ProdTable prodTable)
	= basicSymToGraph(S, s, KW_SYM, id, g, symTable, prodTable);
public tuple[Graph,SymTable,set[Id], map[Production,Id]] symToGraph(S:\layouts(s), Id id, Graph g, SymTable symTable, set[Id] tails, ProdTable prodTable)
	= basicSymToGraph(S, s, LAYOUT_SYM, id, g, symTable, prodTable);
	
public tuple[Graph,SymTable,set[Id], map[Production,Id]] basicSymToGraph(Symbol S, str s, Id kind, Id id, Graph g, SymTable symTable, ProdTable prodTable) {
	if(SYMBOL notin g[id][CONFORMS_TO]) {
		g += <id, CONFORMS_TO, SYMBOL>;
		g += <id, IS, kind>;
		if(kind in {CF_SYM, LEX_SYM, KW_SYM, LAYOUT_SYM}) {
			<symId, symTable> = symToId(S, symTable);
			g += <id, REFERS_TO, symId>;
		}
		if(kind in [LIT_SYM,CILIT_SYM])
			g += <id, STRING_VALUE, string(s)>;
		g += <id, NAME, string(sym2userName(S) ? "<S>")>;
		//g += <id, IS, NT_SYM>;
	}
	return <g, symTable, {id}, prodTable>;
}

public default tuple[Graph,SymTable,set[Id], map[Production,Id]] symToGraph(Symbol s, Id id, Graph g, SymTable symTable, set[Id] tails, ProdTable prodTable) {
	println("Default: <s>");
	if(SYMBOL notin g[id][CONFORMS_TO]) {
		g += <id, CONFORMS_TO, SYMBOL>;
		g += <id, NAME, string(sym2userName(s) ? "<s>")>;
	//g += <id, IS, NT_SYM>;
	}
	return <g, symTable, {id}, prodTable>;
}

public tuple[Id,SymTable] symToId(Symbol s, SymTable symTable) {
	if(s in symTable) {
		return <symTable[s], symTable>;
	}

	id = ident(sym2name(s));
	symTable[s] = id;
	return <id, symTable>;
}

public tuple[Id,SymTable] symToId(Symbol s, Id id, SymTable symTable) {
	if(s in symTable) {
		return <symTable[s], symTable>;
	}
	else if(sym2name(s)?) {
		id = ident(sym2name(s));
	}
	
	symTable[s] = id;
	return <id, symTable>;
}

public map[Production, loc] findGrammarLocs(Grammar g) {
	map[Production, loc] result = ();
	top-down visit(g) {
		case p:prod(def, syms, attrs): {
			if(p@\loc?)
				result[p] = p@\loc;
		}	
	}
	return result;
}

str sym2name(Symbol sym) {
        switch (sym) {
        case \label(_, s): return sym2name(s);
        case \sort(str s): return "cf-<s>";
        case \lex(str s): return "lex-<s>";
        case \layouts(str s): return "layout-<s>";
        case \keywords(str s): return "kw-<s>";
        case \empty(): return "empty";
        case \opt(s): return "optional-<sym2name(s)>";
        case \iter(s): return "one-or-more-<sym2name(s)>";
        case \iter-star(s): return "zero-or-more-<sym2name(s)>";
        case \iter-seps(s, [by]): return "one-or-more-<sym2name(s)>-sep-by-<sym2name(by)>";
        case \iter-star-seps(s, [by]): return "zero-or-more-<sym2name(s)>-sep-by-<sym2name(by)>";
//        case \parameterized-sort(str s, [sort(str z)]): return "<s><z>";
//        case \iter(\parameterized-sort(str s, [sort(str z)])): return "<s><z>List";
//        case \iter-star(\parameterized-sort(str s, [sort(str z)])): return "<s><z>List";
//        case \iter-seps(\parameterized-sort(str s, [sort(str z)]), _): return "<s><z>List";
//        case \iter-star-seps(\parameterized-sort(str s, [sort(str z)]), _): return "<s><z>List";
   }
   throw "Unexpected symbol <sym>";
}

str sym2userName(Symbol sym) {
        switch (sym) {
        case \label(_, s): return sym2name(s);
        case \sort(str s): return "<s>";
        case \lex(str s): return "<s>";
        case \layouts(str s): return "<s>";
        case \keywords(str s): return "<s>";
        case \empty(): return "\u025b";
        case \opt(s): return "<sym2userName(s)>?";
        case \iter(s): return "<sym2userName(s)>+";
        case \iter-star(s): return "<sym2userName(s)>*";
        case \iter-seps(s, [by]): return "<sym2userName(s)>+,";
        case \iter-star-seps(s, [by]): return "<sym2userName(s)>*,";
//        case \parameterized-sort(str s, [sort(str z)]): return "<s><z>";
//        case \iter(\parameterized-sort(str s, [sort(str z)])): return "<s><z>List";
//        case \iter-star(\parameterized-sort(str s, [sort(str z)])): return "<s><z>List";
//        case \iter-seps(\parameterized-sort(str s, [sort(str z)]), _): return "<s><z>List";
//        case \iter-star-seps(\parameterized-sort(str s, [sort(str z)]), _): return "<s><z>List";
   }
   throw "Unexpected symbol <sym>";
}

public str prodToStr(prod(s,as,_)) = "<printSymbol(s, true)> = <intercalate(", ", [printSymbol(a, true) | a <- as])>;";
public str prodToStr(regular(s)) = "<printSymbol(s, true)>";
