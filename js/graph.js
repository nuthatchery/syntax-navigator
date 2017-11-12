/**
 * graph.js
 */

function addElementsFromJson(data) {
	cy.startBatch();

	var newElements = [];
	data.forEach(function(ele) {
		o = cy.add(ele);
		newElements.push(o);
	});
	newElements.forEach(function(o) {
		addAnimations(o);
		o.addClass(o.data('owner'));
		// addOwnerLinks(o);
		o.style('opacity', 0.01);
		if (o.isEdge() && o.data('label') == '/modelling/conformsTo') {
			o.source().addClass(o.target().data('id'))
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
			o.animate({
				style : {
					'opacity' : 1.0
				}
			}, {
				duration : 100 + 400 * Math.random()
			});
		} else {
			o.animate({
				style : {
					'opacity' : 1.0
				}
			}, {
				duration : 500 + 3000 * Math.random()
			});
		}
	});

	cy.endBatch();
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
	return cy.$id(id).data('id') == id;
}

function edgeExists(src, lbl, tgt) {
	cy.$id(src).edgesTo(cy.$id(tgt)).forEach(function(e) {
		if (e.data('label') == lbl)
			return true;
	});
	return false;
}

function getAll(src, lbl) {
	var eles = [];
	cy.$id(src).outgoing().forEach(function(e) {
		if (e.data('label') == lbl)
			eles.push(e.target.data('id'));
	});
	return eles;
}

function getOne(src, lbl) {
	cy.$id(src).outgoing().forEach(function(e) {
		if (e.data('label') == lbl)
			return e.target.data('id');
	});
}

function getAttr(src, lbl) {
	node = cy.$id(src);
	if (node.data(lbl)) {
		return node.data(lbl);
	} else {
		return getAll(src, lbl);
	}
}

function hasAttr(src, lbl, tgt) {
	node = cy.$id(src);
	if (node.data(lbl)) {
		return node.data(lbl).indexOf(tgt) >= 0;
	} else {
		return edgeExists(src, lbl, tgt);
	}
}
