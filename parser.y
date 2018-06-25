%{
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
    
int screen_done = 1; /* 1 if done, 0 otherwise */
char *act_str;   /* extra argument for an action */
char *cmd_str;   /* extra argument for command */
char *item_str;  /* extra argument for 
                  * item description */
%}

%union {
    char    *string;     /* string buffer */
    double    number;          /* command value */
}

%token <string> STRING
%token <number> NUMBER 
%token <cmd> OPEN_LOOP CLOSE_LOOP SUM SUB MUL DIV
%token <cmd> ASSIGN END GREATER LESSER END_LINE
%type <cmd> action line attribute command
%type <string> id 
%token <number> operation

%start screens

%%

statement:    VAR ID ASSIGN STRING END_LINE { printf("char* %s = %s\n", $2, $4); }
            | VAR ID ASSIGN operation END_LINE { printf("double %s = %d\n", $2, $4); }
            | ID ASSIGN STRING END_LINE { printf("%s = %s\n", $1, $3); }
            | ID ASSIGN operation END_LINE { printf("%s = %d\n", $1, $3); }


operation:    operation SUM operation { $$ = $1 + $3 }
            | operation SUB operation { $$ = $1 + $3 }
            | operation MUL operation { $$ = $1 * $3 }
            | operation DIV operation {
                                        if($3 == 0.0)
                                            yyerror("Attempt to divde by zero");
                                        else
                                            $$ = $1 / $3
                                     }
            | NUMBER
            ;
%%

char *progname = "mgl";
int lineno = 1;

#define DEFAULT_OUTFILE "screen.out"

char *usage = "%s: usage [infile] [outfile]\n";

{
main(int argc, char **argv)
	char *outfile;
	char *infile;
	extern FILE *yyin, *yyout;
    
	progname = argv[0];
    
	if(argc > 3)
	{
        	fprintf(stderr,usage, progname);
		exit(1);
	}
	if(argc > 1)
	{
		infile = argv[1];
		/* open for read */
		yyin = fopen(infile,"r");
		if(yyin == NULL) /* open failed */
		{
			fprintf(stderr,"%s: cannot open %s\n", 
				progname, infile);
			exit(1);
		}
	}

	if(argc > 2)
	{
		outfile = argv[2];
	}
	else
	{
      		outfile = DEFAULT_OUTFILE;
	}
    
	yyout = fopen(outfile,"w");
	if(yyout == NULL) /* open failed */
	{
      		fprintf(stderr,"%s: cannot open %s\n", 
                	progname, outfile);
		exit(1);
	}
    
	/* normal interaction on yyin and 
	   yyout from now on */
    
	yyparse();
    
	end_file(); /* write out any final information */
    
	/* now check EOF condition */
	if(!screen_done) /* in the middle of a screen */
	{
        	warning("Premature EOF",(char *)0);
		unlink(outfile); /* remove bad file */
		exit(1);
	}
	exit(0); /* no error */
}

warning(char *s, char *t) /* print warning message */
{
	fprintf(stderr, "%s: %s", progname, s);
	if (t)
		fprintf(stderr, " %s", t);
	fprintf(stderr, " line %d\n", lineno);
}