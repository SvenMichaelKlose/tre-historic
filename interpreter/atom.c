/*
 * nix operating system project tre interpreter
 * Copyright (c) 2005-2007 Sven Klose <pixel@copei.de>
 *
 * Atom related section.
 */

#include "config.h"
#include "atom.h"
#include "number.h"
#include "list.h"
#include "sequence.h"
#include "string.h"
#include "eval.h"
#include "error.h"
#include "array.h"
#include "diag.h"
#include "gc.h"
#include "util.h"
#include "builtin.h"
#include "special.h"
#include "env.h"
#include "io.h"
#include "main.h"
#include "symbol.h"
#include "print.h"

#define _GNU_SOURCE
#include <string.h>
#include <strings.h>
#include <stdlib.h>

/*
 * The atom list is a growing table.
 */
struct tre_atom tre_atoms[NUM_ATOMS];
treptr tre_atoms_free;

const treptr treptr_nil = TYPEINDEX_TO_TREPTR(1, 0);
const treptr treptr_t = TYPEINDEX_TO_TREPTR(1, 1);
const treptr treptr_invalid = (treptr) -1;

treptr treptr_universe; /* *UNIVERSE* variable */

treptr treatom_quote;
treptr treatom_backquote;
treptr treatom_quasiquote;
treptr treatom_quasiquote_splice;
treptr treatom_function;
treptr treatom_values;
treptr treatom_lambda;

treptr tre_package_keyword;

void
treatom_init_nil (void)
{
    /* Initialise NIL atom manually to make list functions work. */
    ATOM_SET(0, tresymbol_add ("NIL"), treptr_nil, ATOM_VARIABLE);

    /* Reinitialize every slot that takes NIL. */
    tre_atoms[0].value = TYPEINDEX_TO_TREPTR(ATOM_VARIABLE, 0), 1;
    tre_atoms[0].fun = treptr_nil;
    tre_atoms[0].binding = treptr_nil;
}

void
treatom_init_atom_table (void)
{
    treptr   p;
    unsigned  i;

    /* Prepare unused atom entries. */
    for (i = 1; i < NUM_ATOMS; i++) {
        ATOM_SET(i, NULL, treptr_nil, ATOM_UNUSED);
    }

    /* Put atom entries on the free atom list, except NIL. */
    p = treptr_nil;
    for (i = NUM_ATOMS - 1; i > 0; i--)
        p = CONS(i, p);
    tre_atoms_free = p;
}

void
treatom_init_builtins (void)
{
    treptr   atom;
    unsigned  i;

    /* Builtin functions. */
    for (i = 0; tre_builtin_names[i] != NULL; i++) {
        atom = treatom_alloc (tre_builtin_names[i], treptr_nil,
                              ATOM_BUILTIN, treptr_nil);
        TREATOM_SET_DETAIL(atom, i);
        EXPAND_UNIVERSE(atom);
    }

    /* Special forms. */
    for (i = 0; tre_special_names[i] != NULL; i++) {
        atom = treatom_alloc (tre_special_names[i], treptr_nil,
                              ATOM_SPECIAL, treptr_nil);
        TREATOM_SET_DETAIL(atom, i);
        EXPAND_UNIVERSE(atom);
    }
}

/*
 * Initialise atom table.
 */
void
treatom_init (void)
{
    treptr t;

    treatom_init_nil ();
    treatom_init_atom_table ();

    t = treatom_get ("T", treptr_nil);
    tre_package_keyword = treatom_alloc ("", treptr_nil, ATOM_PACKAGE, treptr_nil);

    treptr_universe = treatom_alloc ("*UNIVERSE*", treptr_nil, ATOM_VARIABLE, treptr_nil);
    EXPAND_UNIVERSE(t);
    EXPAND_UNIVERSE(tre_package_keyword);
    treatom_init_builtins ();
}

void
treatom_set_name (treptr atom, char *name)
{
    TREATOM_NAME(atom) = name;
}

void
treatom_set_value (treptr atom, treptr value)
{
    TREATOM_VALUE(atom) = value;
}

void
treatom_set_function (treptr atom, treptr value)
{
    TREATOM_FUN(atom) = value;
}

void
treatom_set_binding (treptr atom, treptr value)
{
    TREATOM_BINDING(atom) = value;
}

/* Allocate an atom. */
treptr
treatom_alloc (char *symbol, treptr package, int type, treptr value)
{
    unsigned  atomi;
    treptr   ntop;

    if (tre_atoms_free == treptr_nil) {
        tregc_force ();
        if (tre_atoms_free == treptr_nil)
	    	return treerror (treptr_invalid, "atom table full");
    }

    /* Pop free atom from free atom list. */
    atomi = CAR(tre_atoms_free);
#ifdef TRE_DIAGNOSTICS
    if (TREPTR_TO_ATOM(atomi)->type != ATOM_UNUSED)
		treerror_internal (treptr_invalid, "trying to free unused atom");
#endif
    ntop = CDR(tre_atoms_free);
    trelist_free (tre_atoms_free);
    tre_atoms_free = ntop;

    /* Make self-referencing ordinary. */
    if (value == treptr_invalid)
		value = TYPEINDEX_TO_TREPTR(type, atomi);

    symbol = tresymbol_add (symbol);
    ATOM_SET(atomi, symbol, package, type);
    treatom_set_value (atomi, value);
    TRE_UNMARK(tregc_atommarks, atomi);

    /* Return typed pointer. */
    return TYPEINDEX_TO_TREPTR(type, atomi);
}

/* Free an atom. */
void
treatom_free (treptr atom)
{
#ifdef TRE_DIAGNOSTICS
    treptr  i;

    /* Check if atom is already on the free atom list. */
    if (tre_is_initialized) {
        _DOLIST(i, tre_atoms_free) {
            if (_CAR(i) == TREPTR_INDEX(atom))
                treerror_internal (
					treptr_invalid, "atom %d already on free list", TREPTR_INDEX(atom)
				);
        }
     }

    /* Check if atom is already marked as being unused. */
    if (TREPTR_TO_ATOM(atom)->type == ATOM_UNUSED)
	treerror_internal (treptr_invalid, "trying to free unused atom");
#endif

    if (TREATOM_VALUE(atom) != atom)
        treatom_set_value (atom, treptr_nil);
    treatom_set_function (atom, treptr_nil);
    treatom_set_binding (atom, treptr_nil);
    TREPTR_TO_ATOM(atom)->type = ATOM_UNUSED;

    /* Add entry to list of free atoms. */
    tre_atoms_free = CONS(TREPTR_INDEX(atom), tre_atoms_free);

    /* Release symbol string. */
    if (TREATOM_NAME(atom) != NULL) {
        tresymbol_free (TREATOM_NAME(atom));
    	TREATOM_NAME(atom) = NULL;
    }
}

/*
 * Get number atom.
 *
 * Already existing numbers with the same value are not reused.
 */
treptr
treatom_number_get (float value, int type)
{
    treptr   atom;
    unsigned  num;

    atom = treatom_alloc (NULL, treptr_nil, ATOM_NUMBER, treptr_nil);
    num = trenumber_alloc (value, type);
    TREATOM_SET_DETAIL(atom, num);

    return atom;
}

/* Seek symbolic atom. */
treptr
treatom_seek (char *symbol, treptr package)
{   
    unsigned  a;

    /* Reuse existing atom. */
    for (a = 0; a < NUM_ATOMS; a++) {
		if (tre_atoms[a].type == ATOM_UNUSED)
	    	continue;

		if (tre_atoms[a].name != NULL
	    		&& tre_atoms[a].package == package
            	&& strcmp (tre_atoms[a].name, symbol) == 0)
	    	return ATOM_TO_TREPTR(a);
    }

    return ATOM_NOT_FOUND;
}

/*
 * Seek or create symbolic atom.
 *
 * Create or reuse atom of name 'symbol'.
 */
treptr
treatom_get (char *symbol, treptr package)
{   
    treptr  atom;

    /* Reuse existing atom. */
    atom = treatom_seek (symbol, package);
    if (atom != ATOM_NOT_FOUND)
		return atom;

    /* Create number. */
    if (trenumber_is_value (symbol))
        return treatom_number_get (valuetofloat (symbol), TRENUMTYPE_FLOAT);

    return treatom_alloc (symbol, package, ATOM_VARIABLE, treptr_invalid);
}

/*
 * Remove atom and object.
 */
void
treatom_remove (treptr el)
{
    /* Do type specific clean-up. */
    switch (TREPTR_TYPE(el)) {
        case ATOM_NUMBER:
            trenumber_free (el);
	    	break;

        case ATOM_ARRAY:
	    	trearray_free (el);
	    	break;

        case ATOM_STRING:
	    	trestring_free (el);
	    	break;
    }

    treatom_free (el);
}

/* Lookup variable that points to function containing body. */
treptr
treatom_body_to_var (treptr body)
{        
    unsigned  a;
    unsigned  b; 

    for (a = 0; a < NUM_ATOMS; a++) {
        if (tre_atoms[a].type != ATOM_FUNCTION && tre_atoms[a].type != ATOM_MACRO)
	    	continue;

        if (CAR(CDR(tre_atoms[a].value)) != body)
	    	continue;

        for (b = 0; b < NUM_ATOMS; b++)
            if (tre_atoms[b].type == ATOM_VARIABLE
					&& tre_atoms[b].name != NULL
					&& tre_atoms[b].fun == TREATOM_PTR(a))
                return TREATOM_PTR(b);
    }

    return treptr_nil;
}

/* Return body of user-defined form. */
treptr
treatom_fun_body (treptr atomp)
{
    treptr fun;

    if (TREPTR_IS_VARIABLE(atomp) == FALSE) {
        treerror_internal (atomp, "variable expected");
		return treptr_nil;
    }

    fun = TREATOM_FUN(atomp);
    if (fun != treptr_nil)
        return CDR(TREATOM_VALUE(fun));

    return treptr_nil;
}
