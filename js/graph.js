/**
 * graph.js
 */

function Graph(eles, settings) {
	var _obj = this;
	var rL; var lL; var tL; var bL;
	
	if(settings.leftOf) {
		rL = settings.leftOf.leftLimit; 
		tL = tl ? tl : settings.leftOf.topLimit; 
		bL = bl ? bl : settings.leftOf.bottomLimit; 
	}
	if(settings.rightOf) {
		lL = settings.rightOf.rightLimit; 
		tL = tL ? tL : settings.rightOf.topLimit; 
		bL = bL ? bL : settings.rightOf.bottomLimit; 
	}
	if(settings.below) {
		tL = settings.below.bottomLimit; 
		rL = rL ? rL : settings.below.rightLimit; 
		lL = lL ? lL : settings.below.leftLimit; 
	}
	if(settings.above) {
		bL = settings.above.topLimit; 
		rL = rL ? rL : settings.above.rightLimit; 
		lL = lL ? lL : settings.above.leftLimit; 
	}
	
	this.rightLimit =  rL ? rL : cy.add({
		group: "nodes",
		data: { },
		style: { width: 5, height: 100, 'background-color': '#f00', 'shape': 'rectangle'},
		position: { x: cy.width(), y: 0 }
	});
	this.leftLimit = lL ? lL : cy.add({
		group: "nodes",
		data: { },
		style: { width: 5, height: 100, 'background-color': '#f00', 'shape': 'rectangle'},
		position: { x: 0, y: 0 }
	});
	this.topLimit = tL ? tL : cy.add({
		group: "nodes",
		data: { },
		style: { width: 100, height: 5, 'background-color': '#f00', 'shape': 'rectangle'},
		position: { x: 0, y: cy.height() }
	});
	this.bottomLimit = bL ? bL : cy.add({
		group: "nodes",
		data: { },
		style: { width: 100, height: 5, 'background-color': '#f00', 'shape': 'rectangle'},
		position: { x: 0, y: 0 }
	});
	
	this.elements = eles; 
}

function makeBoxConstraints(graph) {
	var boxConstraints = [];
	
	graph.elements.nodes('[?local]').forEach(function(ele) {
		if(graph.rightLimit != undefined)
			boxConstraints.push({axis: 'x', left: ele, right: graph.rightLimit, gap: 100});
		if(graph.leftLimit != undefined)
			boxConstraints.push({axis: 'x', left: graph.leftLimit, right: ele, gap: 100});
		if(graph.topLimit != undefined)
			boxConstraints.push({axis: 'y', left: graph.topLimit, right: ele, gap: 100});
		if(graph.bottomLimit != undefined)
			boxConstraints.push({axis: 'y', left: ele, right: graph.bottomLimit, gap: 100});
	});
	return boxConstraints;
}
function addElementsFromJson(data) {
	cy.startBatch();

	var newElements = cy.collection();
	
	data.forEach(function(ele) {
		id = ele['data']['id'];
		o = cy.$id(id);
		if(!o.inside()) {
			o = cy.add(ele);
		}
		else {
			o.data(ele['data']);
			console.log(o);
		}
		newElements = newElements.add(o);
	});
	newElements.forEach(function(o) {
		addAnimations(o);
		o.addClass(o.data('owner'));
		// addOwnerLinks(o);
		//o.style('opacity', 0.01);
		if (o.isEdge() && o.data('label') == '/modelling/conformsTo') {
			o.source().addClass(o.target().data('id'))
		}
		if (o.isEdge() && o.data('label') == '/modelling/is') {
			o.source().addClass("is_" + o.target().data('id'))
		}
		if (o.isEdge() && o.data('label') == '/metaParseTree/nodeType') {
			o.source().addClass("nodeType_" + o.target().data('id'))
		}
		if (o.isEdge() && o.data('label')) {
			o.data('text', o.data('label').split("/").pop());
			desc = cy.$id(o.data('label'));
			if (hasAttr(o.data('label'), '/modelling/is',
					'/metaGraph/structural')) {
				o.data('structural', true);
			} else if (o.data('type') == 'ordinal'
					&& o.source().data('structural')) {
				o.data('structural', true);
			}
		} else {
			if (hasAttr(o.data('label'), '/modelling/is',
					'metaGraph/structural')) {
				o.data('structural', true);
			}
			o.data('text', getText(o));
		}
		if (o.data('local')) {
			o.removeStyle('display');
			/*o.animate({
				style : {
					'opacity' : 1.0
				}
			}, {
				duration : 1100 + 400 * Math.random(),
				queue: false
			});*/
		} else {
			o.style('display', 'none');
			/*o.animate({
				style : {
					'opacity' : 1.0
				}
			}, {
				duration : 1500 + 3000 * Math.random(),
				queue: false
			});*/
		}
	});

	cy.endBatch();
	return newElements;
}

function addOwnerLinks(ele) {
	cy.add([ {
		group : "nodes",
		data : {
			id : "__" + ele.data('owner') + "__",
			text : ele.data('owner')
		},
		classes : "owner"
	}, {
		group : "edges",
		data : {
			source : ele.id(),
			target : "__" + ele.data('owner') + "__"
		},
		classes : "owner"
	} ]);
}

function nodeExists(id) {
	return cy.$id(id).isNode();
}

function edgeExists(src, lbl, tgt) {
	node = cy.$id(src);
	if(node.isNode()) {
		node.edgesTo(cy.$id(tgt)).forEach(function(e) {
			if (e.data('label') == lbl)
				return true;
		});
	}
	return false;
}

function edgeExists(src, lbl) {
	node = cy.$id(src);
	if(node.isNode()) {
		node.outgoers().forEach(function(e) {
			if (e.data('label') == lbl)
				return true;
		});
	}
	return false;
}

function getAll(src, lbl) {
	var eles = [];
	node = cy.$id(src);
	if(node.isNode()) {
		node.outgoers().forEach(function(e) {
			if (e.data('label') == lbl) {
				console.log(e);
				console.log(e.target());
				eles.push(e.target().data('id'));
			}
		});
	}
	return eles;
}

function getOne(src, lbl) {
	cy.$id(src).outgoers().forEach(function(e) {
		if (e.data('label') == lbl)
			return e.target().data('id');
	});
}

function getAttrList(src, lbl) {
	node = cy.$id(src);
	if(node.isNode()) {
		if (node.data(lbl)) {
			return node.data(lbl);
		} else {
			return getAll(src, lbl);
		}
	}
}

function getOneAttr(src, lbl) {
	as = getAttrList(src,lbl);
	if(as.length == 0)
		return undefined;
	else
		return as[0];
}

function hasAttr(src, lbl, tgt) {
	node = cy.$id(src);
	if(node.isNode()) {
		if (node.data(lbl)) {
			return node.data(lbl).indexOf(tgt) >= 0;
		} else {
			return edgeExists(src, lbl, tgt);
		}
	}
	else {
		return false;
	}
}

function hasAttr(src, lbl) {
	node = cy.$id(src);
	return node.isNode() && (node.data(lbl) || edgeExists(src, lbl));
}
