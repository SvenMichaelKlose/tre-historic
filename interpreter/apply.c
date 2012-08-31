/*
 * tré – Copyright (c) 2005–2012 Sven Michael Klose <pixel@copei.de>
 */

#include "config.h"
#include "ptr.h"
#include "alloc.h"
#include "atom.h"
#include "list.h"
#include "number.h"
#include "eval.h"
#include "builtin.h"
#include "error.h"
#include "gc.h"
#include "debug.h"
#include "thread.h"
#include "env.h"
#include "argument.h"
#include "xxx.h"
#include "eval.h"
#include "bytecode.h"
#include "array.h"
#include "io.h"
#include "main.h"
#include "print.h"
#include "special.h"
#include "apply.h"

#include "builtin_debug.h"
#include "builtin_atom.h"

#include <stdio.h>
#include <ffi.h>

#define FUNREF_FUNCTION(x)  CAR(CDR(x))
#define FUNREF_LEXICALS(x)  CDR(CDR(x))

treptr treatom_funref;

bool
trebuiltin_is_compiled_funref (treptr x)
{
	return TREPTR_IS_CONS(x) && CAR(x) == treatom_funref;
}

treptr
trebuiltin_call_compiled (treptr func, treptr x)
{
	ffi_cif cif;
	ffi_type **args;
	treptr *refs;
	void **values;
	treptr rc;
	int i;
	void * fun;
    int len = trelist_length (x) + 1;

    args = trealloc (sizeof (ffi_type *) * len);
    refs = trealloc (sizeof (treptr) * len);
    values = trealloc (sizeof (void *) * len);
	for (i = 0; x != treptr_nil; i++, x = CDR(x)) {
		args[i] = &ffi_type_ulong;
		refs[i] = CAR(x);
		values[i] = &refs[i];
	}

	if (ffi_prep_cif(&cif, FFI_DEFAULT_ABI, i, &ffi_type_ulong, args) == FFI_OK) {
		fun = TREATOM_COMPILED_FUN(func);
		ffi_call(&cif, fun, &rc, values);
	} else
        treerror_norecover (treptr_nil, "libffi: cif is not O.K.");

    trealloc_free (args);
    trealloc_free (refs);
    trealloc_free (values);
	return rc;
}

treptr
treeval_compiled_expr (treptr func, treptr args, treptr argdef, bool do_expand)
{
    treptr  expforms;
    treptr  expvals;
	treptr  result;

   	tregc_push (func);
   	tregc_push (args);
   	trearg_expand (&expforms, &expvals, argdef, args, do_expand);
   	tregc_push (expvals);

    result = TREPTR_IS_ARRAY(func) ?
             trecode_call (func, expvals) :
	         trebuiltin_call_compiled (func, expvals);

	tregc_pop ();
	tregc_pop ();
	tregc_pop ();

	return result;
}

treptr
treapply_bytecode (treptr func, treptr args, bool do_argeval)
{
    treptr  expforms;
    treptr  expvals;
	treptr  result;
	treptr  i;
    int     num_args;

    tregc_push (func);
    tregc_push (args);

   	trearg_expand (&expforms, &expvals, TREARRAY_RAW(func)[0], args, do_argeval);
   	tregc_push (expvals);

    num_args = trelist_length (expvals);
    DOLIST(i, expvals)
        *--trestack_ptr = CAR(i);

	result = trecode_exec (func);
    trestack_ptr += num_args;

	tregc_pop ();
	tregc_pop ();
	tregc_pop ();

	return result;
}

treptr
treapply_compiled (treptr func, treptr args)
{
	return TREPTR_IS_ARRAY(func) ?
		       treapply_bytecode (func, args, FALSE) :
	           treeval_compiled_expr (func, args, CAR(TREATOM_VALUE(func)), FALSE);
}

treptr
function_arguments (treptr f)
{
     return TREPTR_IS_ARRAY(f) ?
                TREARRAY_RAW(f)[0] :
                CAR(TREATOM_VALUE(f));
}

treptr
trefuncall_0 (treptr func, treptr args)
{
    treptr  f;
	treptr  a;
	treptr  args_with_ghost;

	if (trebuiltin_is_compiled_funref (func)) {
        f = TREATOM_FUN(FUNREF_FUNCTION(func));
		args_with_ghost = CONS(FUNREF_LEXICALS(func), args);
        a = function_arguments (f);
		return treeval_compiled_expr (f, args_with_ghost, a, FALSE);
	}
	if (IS_COMPILED_FUN(func))
		return treapply_compiled (func, args);
    if (TREPTR_IS_FUNCTION(func))
        return treeval_funcall (func, args, FALSE);
    if (TREPTR_IS_BUILTIN(func))
        return treeval_xlat_function (treeval_xlat_builtin, func, args, FALSE);
    if (TREPTR_IS_SPECIAL(func))
        return trespecial (func, args);
    return treerror (func, "function expected");
}

treptr
trefuncall (treptr func, treptr args)
{
    treptr  result;

    tregc_push (args);
    result = trefuncall_0 (func, args);
    tregc_pop ();

    return result;
}

void
treapply_init ()
{
    treatom_funref = treatom_get ("%FUNREF", TRECONTEXT_PACKAGE());
    EXPAND_UNIVERSE(treatom_funref);
}
