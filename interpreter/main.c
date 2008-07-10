/*
 * nix operating system project tre interpreter
 * Copyright (c) 2005-2008 Sven Klose <pixel@copei.de>
 *
 * Top-level control
 */

#include "config.h"
#include "atom.h"
#include "list.h"
#include "number.h"
#include "io.h"
#include "io_std.h"
#include "read.h"
#include "gc.h"
#include "special.h"
#include "print.h"
#include "eval.h"
#include "builtin.h"
#include "macro.h"
#include "debug.h"
#include "thread.h"
#include "error.h"
#include "argument.h"
#include "alloc.h"
#include "symbol.h"
#include "string.h"
#include "image.h"
#include "util.h"

#include <setjmp.h>
#include <stdlib.h>
#include <string.h>
#include <signal.h>

char * tremain_self = NULL;   /* Path to running executable. */
char * tremain_imagelaunch = NULL;
char * tremain_launchfile = NULL;

treptr tremain_history;
treptr tremain_history_2;
treptr tremain_history_3;

bool tremain_noimage = FALSE;

struct tremain_arg {
    char * option;
    char ** value;
} tremain_args[] = {
    { "-i", &tremain_imagelaunch}
};

jmp_buf jmp_main;
treptr tre_restart_fun;

int tre_is_initialized;

void
tre_exit (int code)
{
    exit (code);
}

bool tre_interrupt_debugger;

void
tre_signal (int signum)
{
	switch (signum) {
	case SIGINT:
		if (! tre_interrupt_debugger)
#ifdef TRE_EXIT_ON_STDIO_SIGINT
			exit (-1);
#else
			break;
#endif
		printf ("*USER-BREAK*");
		fflush (stdout);
		tredebug_mode = TREDEBUGM_STEP;
		break;
	}
}

void
tre_restart (treptr fun)
{
    tre_restart_fun = fun;
    treiostd_undivert_all ();
    longjmp (jmp_main, -1);
}

treptr
tre_main_line (struct tre_stream *stream)
{
    treptr  expr;

    /* Read expression. */
    expr = treread (stream);
    if (expr == treptr_invalid)  /* End of file. */
        return expr;

#ifdef TRE_VERBOSE_READ
    treprint (expr);
#endif

	/* The stdin prompt may have disabled the debugger. */
	tre_interrupt_debugger = TRUE;

    tregc_push (expr);

	/* Update history. */
/*
	TREATOM_VALUE(tremain_history_3) = TREATOM_VALUE(tremain_history_2);
	TREATOM_VALUE(tremain_history_2) = TREATOM_VALUE(tremain_history);
	TREATOM_VALUE(tremain_history) = expr;
*/

    /* Expand macros. */
    expr = tremacro_builtin_macroexpand (expr);
    tregc_pop ();

#ifdef TRE_PRINT_MACROEXPANSIONS
    treprint (expr);
#endif

    /* Evaluate expression. */
    tregc_push (expr);
	trethread_push_call (tremain_history);
    expr = treeval (expr);
	trethread_pop_call ();
    tregc_pop ();

    /* Print result on stdout if expression was read from stdin. */
    if (treio_readerstreamptr == 1)
        treprint (expr);

    return expr;
}

void
tre_main (void)
{
    while (1)
        if (tre_main_line (treio_reader) == treptr_invalid)
	    	break;
}

/* Initialise everything. */
void
tre_init (void)
{
    tre_is_initialized = FALSE;
    tre_interrupt_debugger = FALSE;

    treio_init ();
    tredebug_init ();
    trethread_make ();
    tregc_init ();

    trelist_init ();
    tresymbol_init ();
    treatom_init ();
    trenumber_init ();
    treread_init ();
    trearg_init ();
    treeval_init ();
    tremacro_init ();
    trespecial_init ();
    treimage_init ();

    MAKE_VAR("*ENVIRONMENT-PATH*", trestring_get (TRE_ENVIRONMENT));

	MAKE_VAR("*BOOT-IMAGE*", trestring_get (TRE_BOOT_IMAGE));
	MAKE_VAR("*LIBC-PATH*", trestring_get (LIBC_PATH));
	MAKE_VAR("*ENDIANESS*", treatom_alloc (TRE_ENDIANESS_STRING, TRECONTEXT_PACKAGE(), TRETYPE_VARIABLE, treptr_invalid));

	MAKE_HOOK_VAR(tremain_history, "_");
	MAKE_HOOK_VAR(tremain_history_2, "__");
	MAKE_HOOK_VAR(tremain_history_3, "___");

    tre_restart_fun = treptr_nil;

	signal (SIGINT, tre_signal);

    tre_is_initialized = TRUE;
    tre_interrupt_debugger = TRUE;
}

void
tremain_init_after_image_loaded ()
{
    /* Create global %LAUNCHFILE variable containing the application file
     * to evaluate after the environment is set up. */
    MAKE_VAR("%LAUNCHFILE", (tremain_launchfile ?
                				trestring_get (tremain_launchfile) :
                				treptr_nil));
}

void
tremain_help (void)
{
	printf (TRE_INFO
			TRE_COPYRIGHT
            "Usage: tre [-h] [-i image-file] [source-file]\n"
            "\n"
            " -h  Print this help message.\n"
            " -i  Load image file before source-file.\n"
            " -n  Make new default image.\n"
            "\n"
            "See MANUAL for details.\n");
}

void
tremain_get_args (int argc, char *argv[])
{
    unsigned  i;
	int  p;

    tremain_self = argv[0];

    for (p = 1; p < argc; p++) {
		char * v = argv[p];
        if (!strcmp ("-n", v)) {
			tremain_noimage = TRUE;
			continue;
		}
        if (!strcmp ("-h", v)) {
			tremain_help ();
            exit (0);
        }
        DOTIMES(i, sizeof tremain_args / sizeof (struct tremain_arg)) {
            if (!strcmp (tremain_args[i].option, v)) {
                * tremain_args[i].value = argv[++p];
                goto next;
            }
        }
        tremain_launchfile = v;
next:
        continue;
    }
}

/* Program entry point. */
int
main (int argc, char *argv[])
{
    static int c = 0;

    tremain_get_args (argc, argv);
    tre_init ();

    /* Return here on errors. */
    setjmp (jmp_main);
    if (c == 1)
		goto load_error;
    if (c == 2)
		goto user;

	if (tremain_noimage)
		goto boot;

    c = 2;
    treimage_load (tremain_imagelaunch ? tremain_imagelaunch : TRE_BOOT_IMAGE);
    tremain_imagelaunch = NULL;

boot:
    /* Execute boot code. */
    c = 1;
    treiostd_divert (treiostd_open_file (TRE_BOOTFILE));
    tremain_init_after_image_loaded ();
    tre_main ();

load_error:
    c = 2;
    treiostd_undivert ();

user:
	/* Call init function. */
    if (tre_restart_fun != treptr_nil) {
        treeval (CONS(tre_restart_fun, treptr_nil));
        tre_restart_fun = treptr_nil;
    }

    /* Start the toplevel eval loop. */
    tre_main ();

    return 0;
}
