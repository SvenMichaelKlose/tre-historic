/*
 * tré - Copyright (c) 2005-2008,2012 Sven Michael Klose <pixel@copei.de>
 */

#ifndef TRE_ARGUMENTS_H
#define TRE_ARGUMENTS_H

extern treptr trearg_get (treptr args);
extern void   trearg_get2 (treptr *car, treptr *cdr, treptr args);

extern treptr trearg_correct (ulong argnum, int type, treptr, const char * descr);
extern treptr trearg_typed (ulong argnum, int type, treptr, const char * descr);

extern void   trearg_expand (treptr *rvars, treptr *rvals, treptr argdef, treptr args, bool do_argeval);

extern void   trearg_init (void);

extern treptr tre_atom_rest;
extern treptr tre_atom_body;

#endif 	/* #ifndef TRE_ARGUMENTS_H */
