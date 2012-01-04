/*
 * tré - Copyright (c) 2005-2006,2010 Sven Klose <pixel@copei.de>
 */

#ifndef TRE_BUILTIN_ARITH_H
#define TRE_BUILTIN_ARITH_H

extern treptr trenumber_builtin_plus (treptr);
extern treptr trenumber_builtin_character_plus (treptr);
extern treptr trenumber_builtin_difference (treptr);
extern treptr trenumber_builtin_character_difference (treptr);
extern treptr trenumber_builtin_times (treptr);
extern treptr trenumber_builtin_quotient (treptr);
extern treptr trenumber_builtin_mod (treptr);
extern treptr trenumber_builtin_logxor (treptr);
extern treptr trenumber_builtin_number_equal (treptr);
extern treptr trenumber_builtin_lessp (treptr);
extern treptr trenumber_builtin_greaterp (treptr);

#endif	/* #ifndef TRE_BUILTIN_ARITH_H */
