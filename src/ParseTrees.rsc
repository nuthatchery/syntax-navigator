module ParseTrees
import List;
import Productions;
import ParseTree;
import String;
import Grammar;
import util::Reflective;
import lang::rascal::grammar::definition::Modules;
import lang::rascal::\syntax::Rascal;
import IO;
import Triples;

syntax Expr 
	= "(" Expr ")"
	| left Expr a "+" Expr b
//	| left (Expr "*" Expr | Expr "/" Expr)
	//> left (Expr a ":")* "."
	| Var
	| Num
	;

lexical Var = [a-zA-Z\u51f0]+;

lexical Num = [0-9]+;

layout LAYOUT = [\ \n\r\f\t]*;

anno loc Expr@\loc;


Id nextId(ident(old), int childNum) = ident("<old>.<childNum>");
Id nextId(ident(parent, old), int childNum) = ident(parent, "<old>.<childNum>");

public Graph metaParseTree = newGraph("metaParseTree");
public Id PARSE_TREE = newId(metaParseTree, "parseTree");
public Id PT_CONFORMS_TO = newId(metaParseTree, "conformsTo");
public Id PRODUCTION_STRING = newId(metaParseTree, "productionString");
public Id PRODUCTION = newId(metaParseTree, "production");
public Id APPL = newId(metaParseTree, "appl");
public Id NODE_TYPE = newId(metaParseTree, "nodeType");
public Id SOURCE = newId(metaParseTree, "source");
public Id STRING_VALUE = newId(metaParseTree, "stringValue");
public Id AMB = newId(metaParseTree, "amb");
public Id ALTERNATIVE = newId(metaParseTree, "alternative");
public Id CHAR = newId(metaParseTree, "char");
public Id CHAR_CODE = newId(metaParseTree, "charCode");
public Id CHAR_SYMBOL = newId(metaParseTree, "charSymbol");
public Id ROOT = newId(metaParseTree, "root");

public Graph ptToGraph(Tree t, str name, map[Production, Id] prodTable) {
	Graph g = newGraph(name);
	g += <this(), CONFORMS_TO, PARSE_TREE>;	
	g += <this(), ROOT, ident("0")>;

	gId = prodTable[\others(\start(\sort("$thisGrammar$")))];
	g += <this(), PT_CONFORMS_TO, gId>;
	
	return ptToGraph(t, ident("0"), g, "cf", prodTable);
}
public Graph ptToGraph(tree:appl(p, args), Id id, Graph g, str mode, map[Production, Id] prodTable) {
	g += <id, CONFORMS_TO, APPL>;
	g += <id, PRODUCTION_STRING, string("<p>")>;
	if(p.def?) {
		if(\sort(s) := p.def || \lex(s) := p.def || \keywords(s) := p.def || \lit(s) := p.def || \cilit(s) := p.def || \layouts(s) := p.def)
			g += <id, NAME, string(s)>;
		else if(mode == "lex" || mode == "layout") {
			g += <id, STRING_VALUE, string(unparse(tree))>;
		}
		if(\lex(s) := p.def || \keywords(s) := p.def)
			mode = "lex";
		else if(\layouts(s) := p.def)
			mode = "layout";	
	}

	g += <id, NODE_TYPE, ident(ident(root(), "metaParseTree"), mode)>;
	println(<id, NODE_TYPE, ident(ident(root(), "metaParseTree"), mode)>);
	prodNoLayouts = p; // innermost visit(p) { case [*Symbol as1,\layouts(_),*Symbol as2] => [*as1,*as2] };
	
	if(prodNoLayouts in prodTable) {
		g += <id, PRODUCTION,  prodTable[prodNoLayouts]>;
	}
	else {
		println("no location found for <prodToStr(prodNoLayouts)>: <prodNoLayouts>");
	}
	if(tree@\loc?) {
		g += <id, SOURCE, uri(tree@\loc)>;
	}
	
	/*if(prod(lit(_),_,_) := p 
	   || prod(lex(_),_,_) := p) {
		g += <id, STRING_VALUE, string(unparse(tree))>;
 	}*/
	int layoutCount = 0;
	for(i <- index(args)) {
		child = nextId(id, i);
		subTree = args[i];
		g += <id, ordinal("/metaParseTree/child", i), child>;
		if(appl(prod(layouts(_),_,_),_) := subTree) {
			g += <id, ordinal("/metaParseTree/layout", layoutCount), child>;
			layoutCount = layoutCount + 1;
		}
		else {
			g += <id, ordinal("/metaParseTree/subTree", i-layoutCount), child>;
		}
		g = ptToGraph(subTree, child, g, mode, prodTable);
	}

	return g;
}

public Graph ptToGraph(amb(args), Id id, Graph g, str mode, map[Production, Id] prodTable) {
	g += <id, CONFORMS_TO, AMB>;
	g += <id, NODE_TYPE, ident(ident(root(), "metaParseTree"), mode)>;

	int i = 0;
	for(a <- args) {
		child = nextId(id, i);
		g += <id, ALTERNATIVE, child>;
		g = ptToGraph(a, child, g, mode, prodTable);
		i = i + 1;
	}
	
	return g;
}

public Graph ptToGraph(char(c), Id id, Graph g, str mode, map[Production, Id] prodTable) {
	g += <id, CONFORMS_TO, CHAR>;
	g += <id, CHAR_CODE, character(c)>;
	g += <id, STRING_VALUE, string(stringChar(c))>;
	g += <id, NODE_TYPE, ident(ident(root(), "metaParseTree"), mode)>;

	return g;
}

public default Graph ptToGraph(Tree tree, Id id, Graph g, str mode, map[Production, Id] prodTable) {
	throw "ptToGraph: don\'t know what to do with <tree>";
}

public str prodToStr(prod(s,as,_)) = "<printSymbol(s, true)> = <intercalate(", ", [printSymbol(a, true) | a <- as])>;";
public str prodToStr(regular(s)) = "<printSymbol(s, true)>";
public str prodToSymStr(prod(s,as,_)) = "<printSymbol(s, false)>";
public str prodToSymStr(regular(s)) = "<printSymbol(s, false)>";
 