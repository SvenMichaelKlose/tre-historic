/*
 * tré – Copyright (c) 2012–2013 Sven Michael Klose <pixel@copei.de>
 */

#include "config.h"
#include "atom.h"
#include "number.h"
#include "cons.h"
#include "list.h"
#include "string2.h"
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
#include "thread.h"
#include "image.h"
#include "alloc.h"
#include "compiled.h"
#include "bytecode.h"
#include "queue.h"

#include <string.h>
#include <strings.h>
#include <stdlib.h>

treptr treptr_set;
treptr treptr_funcall;
treptr treptr_builtin;
treptr treptr_special;
treptr treptr_jmp;
treptr treptr_cond;
treptr treptr_stack;
treptr treptr_vec;
treptr treptr_set_vec;
treptr treptr_set_atom_fun;
treptr treptr_cons;
treptr treptr_quote;
treptr treptr_apply;
treptr treptr_funref;
treptr treptr_quote;

treptr trecode_get (treptr ** p);

treptr
trecode_list (treptr ** p, int len)
{
    treptr  l = tre_make_queue ();
    treptr  v;
    treptr  * x = *p;
    int     i;

    tregc_push (l);
    DOTIMES(i, len) {
        v = trecode_get (&x);
        tre_enqueue (l, v);
    }
    tregc_pop ();
    *p = x;

    return CDR(l);
}

void
trecode_set_place (treptr ** p, treptr value)
{
    treptr * x = *p;
    treptr v = *x++;

    if (v == treptr_stack)
        trestack_ptr[TRENUMBER_INT(*x++)] = value;
    else if (v != treptr_nil)
        TREATOM_VALUE(v) = value;

    *p = x;
}

void
trecode_set_fun (treptr ** p, treptr value)
{
    treptr * x = *p;
    treptr v = *x++;

    if (v == treptr_stack)
        TREATOM_FUN(trestack_ptr[TRENUMBER_INT(*x++)]) = value;
    else if (v != treptr_nil)
        TREATOM_FUN(v) = value;

    *p = x;
}

void
trecode_print_args (int num_args)
{
    int i;

    DOTIMES(i, num_args) {
        printf("Argument %d: ", i);
        treprint (trestack_ptr[num_args - i]);
    }
}

treptr
trecode_call (treptr fun, treptr args)
{
    treptr i;
    treptr v;
    treptr num_args = 0;

    tregc_push (fun);
    DOLIST(i, args) {
        *--trestack_ptr = CAR(i);
        num_args++;
    }
    v = trecode_exec (fun);
    trestack_ptr += num_args;
    tregc_pop ();

    return v;
}

treptr
trecode_get (treptr ** p)
{
    treptr  a;
    treptr  v;
    treptr  fun;
    treptr  args;
    treptr  car;
    treptr  cdr;
    treptr  vec;
    treptr  lex;
    treptr  * x = *p;
    int     num_args;
    int     i;

    v = *x++;

    if (v == treptr_funcall) {
        fun = *x++;
        if (TREPTR_IS_BUILTIN(fun)) {
            if (fun == treptr_cons) {
                car = trecode_get (&x);
                tregc_push (car);
                cdr = trecode_get (&x);
                v = CONS(car, cdr);
                tregc_pop ();
            } else if (fun == treptr_set_atom_fun) {
                trecode_set_place (&x, trecode_get (&x));
            } else {
                num_args = TRENUMBER_INT(*x++);
                args = trecode_list (&x, num_args);
                tregc_push (args);
                v = treeval_xlat_function (treeval_xlat_builtin, fun, args, FALSE);
                tregc_pop ();
            }
        } else if (TREPTR_IS_ATOM(fun) && TREPTR_IS_ARRAY(TREATOM_FUN(fun))) {
            tregc_push (TREATOM_FUN(fun));
            num_args = TRENUMBER_INT(*x++);
            v = tre_make_queue ();
            tregc_push (v);
            DOTIMES(i, num_args)
                tre_enqueue (v, trecode_get (&x));
            DOLIST(a, tre_queue_list (v))
                *--trestack_ptr = CAR(a);
            tregc_pop ();
            v = trecode_exec (TREATOM_FUN(fun));
            trestack_ptr += num_args;
            tregc_pop ();
        } else 
            treerror_norecover (fun, "tried to call an unsupported function type in bytecode");
    } else if (v == treptr_stack) {
        v = trestack_ptr[TRENUMBER_INT(*x++)];
    } else if (v == treptr_quote) {
        v = *x++;
    } else if (v == treptr_vec) {
        vec = trecode_get (&x);
        v = _TREVEC(vec, TRENUMBER_INT(*x++));
    } else if (v == treptr_funref) {
        fun = *x++;
        tregc_push (fun);
        lex = trecode_get (&x);
        tregc_push (lex);
        v = CONS(treptr_funref, CONS(fun, lex));
        tregc_pop ();
        tregc_pop ();
    } else if (TREPTR_IS_VARIABLE(v))
        v = TREATOM_VALUE(v);
    *p = x;

    return v;
}

void
trecode_set (treptr ** x)
{
    trecode_set_place (x, trecode_get (x));
}

treptr
trecode_exec (treptr fun)
{
    treptr   * code;
    treptr   * x;
    treptr   dest;
    treptr   v;
    unsigned num_locals;
    unsigned i = 0;
    int      vec;

    if (TREPTR_IS_ARRAY(fun) == FALSE)
        treerror_norecover (fun, "bytecode array function expected");
    x = &TREARRAY_RAW(fun)[2]; /* skip over argument definition and body */
    num_locals = TRENUMBER_INT(*x++);
    code = x;

    DOTIMES(i, num_locals)
        *--trestack_ptr = treptr_nil;

    while (1) {
        v = *x++;
        if (v == treptr_set) {
            trecode_set (&x);
        } else if (v == treptr_jmp) {
            dest = *x++;
            if (dest == treptr_nil)
                break;
            x = &code[TRENUMBER_INT(dest)];
        } else if (v == treptr_cond) {
            if (trecode_get (&x) != treptr_nil) {
                x++;
            } else {
                x = &code[TRENUMBER_INT(*x)];
            }
        } else if (v == treptr_set_vec) {
            vec = trecode_get (&x);
            tregc_push (vec);
            i = TRENUMBER_INT(*x++);
            v = _TREVEC(vec, i) = trecode_get (&x);
            tregc_pop ();
        } else
            treerror_norecover (v, "illegal bytecode instruction");
    }

    v = *trestack_ptr;
    trestack_ptr += num_locals;
    return v;
}

void
trecode_init ()
{
    treptr_set = treatom_get ("%BC-SET", TRECONTEXT_PACKAGE());
    EXPAND_UNIVERSE(treptr_set);
    treptr_set_vec = treatom_get ("%BC-SET-VEC", TRECONTEXT_PACKAGE());
    EXPAND_UNIVERSE(treptr_set_vec);
    treptr_funcall = treatom_get ("%BC-FUNCALL", TRECONTEXT_PACKAGE());
    EXPAND_UNIVERSE(treptr_funcall);
    treptr_builtin = treatom_get ("%BC-BUILTIN", TRECONTEXT_PACKAGE());
    EXPAND_UNIVERSE(treptr_builtin);
    treptr_special = treatom_get ("%BC-SPECIAL", TRECONTEXT_PACKAGE());
    EXPAND_UNIVERSE(treptr_special);
    treptr_jmp = treatom_get ("%%VM-GO", TRECONTEXT_PACKAGE());
    EXPAND_UNIVERSE(treptr_jmp);
    treptr_cond = treatom_get ("%%VM-GO-NIL", TRECONTEXT_PACKAGE());
    EXPAND_UNIVERSE(treptr_cond);
    treptr_stack = treatom_get ("%STACK", TRECONTEXT_PACKAGE());
    EXPAND_UNIVERSE(treptr_stack);
    treptr_vec = treatom_get ("%VEC", TRECONTEXT_PACKAGE());
    EXPAND_UNIVERSE(treptr_vec);
    treptr_set_atom_fun = treatom_get ("%SET-ATOM-FUN", TRECONTEXT_PACKAGE());
    EXPAND_UNIVERSE(treptr_set_atom_fun);
    treptr_cons = treatom_get ("CONS", TRECONTEXT_PACKAGE());
    EXPAND_UNIVERSE(treptr_cons);
    treptr_quote = treatom_get ("%QUOTE", TRECONTEXT_PACKAGE());
    EXPAND_UNIVERSE(treptr_quote);
    treptr_apply = treatom_get ("APPLY", TRECONTEXT_PACKAGE());
    EXPAND_UNIVERSE(treptr_apply);
    treptr_funref = treatom_get ("%FUNREF", TRECONTEXT_PACKAGE());
    EXPAND_UNIVERSE(treptr_funref);
    treptr_quote = treatom_get ("%QUOTE", TRECONTEXT_PACKAGE());
    EXPAND_UNIVERSE(treptr_quote);
}
