/*
 * nix operating system project tre interpreter
 * Copyright (c) 2005-2007 Sven Klose <pixel@copei.de>
 *
 * Built-in string functions
 */

#include "config.h"
#include "atom.h"
#include "list.h"
#include "string.h"
#include "number.h"
#include "error.h"
#include "eval.h"
#include "sequence.h"
#include "thread.h"
#include "argument.h"
#include "builtin_string.h"

#define _GNU_SOURCE
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <strings.h>

/*
 * (STRINGP obj)
 *
 * Returns T if the argument is a string. NIL otherwise. 
 */
treptr
trestring_builtin_stringp (treptr list)
{
    treptr arg = trearg_get (list);

    if (TREPTR_IS_STRING(arg) == FALSE)
        return treptr_nil;
    return treptr_t;
}

/*
 * (MAKE-STRING n)
 *
 * Makes new string consisting of n elements.
 */
treptr
trestring_builtin_make (treptr list)
{
    treptr  arg = trearg_get (list);
    struct tre_string *str;
    treptr atom;

    if (TREPTR_IS_NUMBER(arg) == FALSE)
		return treerror (arg, "integer expected");

    str = trestring_get_raw ((unsigned) TRENUMBER_VAL(arg));
    atom = treatom_alloc (NULL, TRECONTEXT_PACKAGE(), ATOM_STRING, treptr_nil);
    TREATOM_SET_STRING(atom, str);
    return atom;
}

/*
 * (STRING-CONCAT string*)
 *
 * Concatenates string arguments in order as a new string.
 */
treptr
trestring_builtin_concat (treptr list)
{
    struct tre_string  *news;
    treptr   p;
    treptr   car;
    treptr   atom;
    char      *newp;
    unsigned  len = 0;

    /* Sum up length of all elements in the list. */
    DOLIST(p, list) {
        car = CAR(p);
		if (TREPTR_IS_STRING(car) == FALSE)
	    	return treerror (car, "can only concatenate strings");
	   	len += strlen (TREATOM_STRINGP(car));
    }

    /* Copy elements to new string. */
    news = trestring_get_raw (len);
    if (news == NULL)
		return treerror (treptr_invalid, "out of memory");
    newp = &news->str;

    DOLIST(p, list)
		newp = stpcpy (newp, TREATOM_STRINGP(CAR(p)));

    /* Return new string atom. */
    atom = treatom_alloc (NULL, TRECONTEXT_PACKAGE(), ATOM_STRING, treptr_nil);
    TREATOM_SET_STRING(atom, news);
    return atom;
}

/*
 * (STRING obj)
 *
 * Returns a copy of 'obj' of type string. If 'obj' is already a string,
 * returns the original.
 */
treptr
trestring_builtin_string (treptr list)
{
    char     buf[TRE_MAX_STRINGLEN];
    treptr  arg = trearg_get (list);

    switch (TREPTR_TYPE(arg)) {
        case ATOM_VARIABLE:
        case ATOM_BUILTIN:
	    	/* Convert symbol to string. */
	    	strcpy (buf, TREATOM_NAME(arg));
            return trestring_get (buf);

        case ATOM_STRING:
	    	return arg;

        case ATOM_NUMBER:
            sprintf (buf, "%-g", TRENUMBER_VAL(arg));
            return trestring_get (buf);
    }

    return treerror (treptr_invalid, "conversion unsupported");
}

/*
 * (SYMBOL-NAME obj)
 *
 * Returns the symbol name of obj as a string.
 */
treptr
trestring_builtin_symbol_name (treptr list)
{
    char     buf[TRE_MAX_STRINGLEN];
    treptr  arg;
    char     *an;

    arg = trearg_get (list);
    if (TREPTR_IS_ATOM(arg) == FALSE)
        arg = treerror (arg, "atom expected");

    an = TREATOM_NAME(arg);

    buf[0] = 0;
    if (an)
        strcpy (buf, an);
    return trestring_get (buf);
}
