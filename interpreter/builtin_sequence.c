/*
 * tré – Copyright (c) 2005–2009,2012 Sven Michael Klose <pixel@copei.de>
 */

#include "config.h"
#include "atom.h"
#include "cons.h"
#include "list.h"
#include "number.h"
#include "string2.h"
#include "eval.h"
#include "error.h"
#include "print.h"
#include "gc.h"
#include "ptr.h"
#include "builtin_sequence.h"
#include "argument.h"
#include "array.h"
#include "diag.h"
#include "xxx.h"

#include <stdlib.h>
#include <stdio.h>
#include <math.h>

struct tre_sequence_type * tre_sequence_types [] = {
	&trelist_seqtype,	/* #define TRETYPE_CONS        0 */
	NULL,	            /* #define TRETYPE_VARIABLE    1 */
	NULL,	            /* #define TRETYPE_NUMBER      2 */
	&trestring_seqtype,	/* #define TRETYPE_STRING      3 */
	&trearray_seqtype,	/* #define TRETYPE_ARRAY       4 */
	NULL,	            /* #define TRETYPE_BUILTIN     5 */
	NULL,	            /* #define TRETYPE_SPECIAL     6 */
	NULL,	            /* #define TRETYPE_MACRO       7 */
	NULL,	            /* #define TRETYPE_FUNCTION    8 */
	NULL,	            /* #define TRETYPE_USERSPECIAL 9 */
	NULL,	            /* #define TRETYPE_PACKAGE     10 */
};
	
struct tre_sequence_type *
tresequence_get_type (treptr seq)
{
	unsigned type = TREPTR_TYPE(seq);
	struct tre_sequence_type * seqtype;

#ifdef TRE_DIAGNOSTICS
	if (type > TRETYPE_MAXTYPE)
		treerror_internal (treptr_nil,
						   "tresequence_get_type: type out of range");
#endif

	seqtype = tre_sequence_types[type];
	if (seqtype == NULL)
		treerror_norecover (seq, "not a sequence");
	
    return seqtype;
}

/*tredoc
  (cmd :name %%USEFT-ELT
	(arg :name value)
	(arg :name index :type unsigned-integer)
	(arg :type sequence)
	(descr "Set element at index of sequence to new value.")
	(returns-argument value))
 */
treptr
tresequence_builtin_set_elt (treptr args)
{
    struct tre_sequence_type *t;
    treptr  val = CAR(args);
    treptr  seq = CADR(args);
    treptr  idx = CADDR(args);

    if (TREPTR_IS_NUMBER(idx) == FALSE)
		return treerror (idx, "index must be integer");

    t = tresequence_get_type (seq);
    if (t == NULL)
        return treerror (treptr_invalid, "sequence expected");

    if (t->set == NULL)
        return treerror (seq, "sequence cannot be modified");
    (*t->set) (seq, (ulong) TRENUMBER_VAL(idx), val);

    return val;
}

/*tredoc
  (cmd :name -ELT
	(arg :name value)
	(arg :name index :type unsigned-integer)
	(arg :type sequence)
	(returns "Element at index of sequence."))
 */
treptr
tresequence_builtin_elt (treptr args)
{
    struct tre_sequence_type *t;
    treptr  seq;
    treptr  idx;

    trearg_get2 (&seq, &idx, args);

    if (TREPTR_IS_NUMBER(idx) == FALSE)
		return treerror (idx, "index must be integer");

	RETURN_NIL(seq);

    t = tresequence_get_type (seq);
    if (t == NULL)
        return treerror (seq, "sequence expected");
    return (*t->get) (seq, (ulong) TRENUMBER_VAL(idx));
}

/*tredoc
  (cmd :name LENGTH
	(arg :type sequence)
	(returns :type unsigned-integer
			 "Return number of elements in sequence."))
 */
treptr
tresequence_builtin_length (treptr args)
{
	treptr ret;
    treptr seq = trearg_get (args);
    struct tre_sequence_type *t;

	CHKPTR(seq);
    if (seq == treptr_nil)
		return treatom_number_get (0, TRENUMTYPE_INTEGER);

    t = tresequence_get_type (seq);
    if (t == NULL)
        return treerror (seq, "sequence expected");

    ret = treatom_number_get ((double) (*t->length) (seq), TRENUMTYPE_INTEGER);
	CHKPTR(ret);
	return ret;
}
