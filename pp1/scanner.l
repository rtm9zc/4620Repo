/* File:  scanner.l
 * ----------------
 * Lex inupt file to generate the scanner for the compiler.
 */

%{

/* The text within this first region delimited by %{ and %} is assumed to
 * be C/C++ code and will be copied verbatim to the lex.yy.c file ahead
 * of the definitions of the yylex() function. Add other header file inclusions
 * or C++ variable declarations/prototypes that are needed by your code here.
 */

#include <string.h>
#include "scanner.h"
#include "utility.h" // for PrintDebug()
#include "errors.h"

/* Global variable: yylval
 * -----------------------
 * This global variable is how we get attribute information about the token
 * just scanned to the client. The scanner sets the global variable
 * appropriately and since it's global the client can just read it.  In the
 * future, this variable will be declared for us in the y.tab.c file
 * produced by Yacc, but for now, we declare it manually.
 */
YYSTYPE yylval;  // manually declared for pp1, later Yacc provides

/* Global variable: yylloc
 * -----------------------
 * This global variable is how we get position information about the token
 * just scanned to the client. (Operates similarly to yylval above)
 */
struct yyltype yylloc; // manually dclared for pp1, later Yacc provides

/* Macro: YY_USER_ACTION 
 * ---------------------
 * This flex built-in macro can be defined to provide an action which is
 * always executed prior to any matched rule's action. Basically, it is
 * a way of having a piece of code common to all actions factored out to
 * this routine.  We already defined it for you and left the empty
 * function DoBeforeEachAction ready for your use as needed. It will
 * be called once for each pattern scanned from the file, before
 * executing its action.
 */
static void DoBeforeEachAction(); 
static int procKwd(int token);
static char procOp();
static int procConstant(int token);
static char* procId();
#define YY_USER_ACTION DoBeforeEachAction();

%}

 /* The section before the first %% is the Definitions section of the lex
  * input file. Here is where you set options for the scanner, define lex
  * states, and can set up definitions to give names to regular expressions
  * as a simple substitution mechanism that allows for more readable
  * entries in the Rules section later. 
  */


%%             /* BEGIN RULES SECTION */
 /* All patterns and actions should be placed between the start and stop
  * %% markers which delimit the Rules section. 
  */ 
[ \t]+ {;}
[\n] {yylloc.first_column = yylloc.last_column = 0; yylloc.first_line++;}
void {TokenType theToken = T_Void; procKwd(theToken);}
string {TokenType theToken = T_String; procKwd(theToken);}
this {TokenType theToken = T_This; procKwd(theToken);}
while {TokenType theToken = T_While; procKwd(theToken);}
break {TokenType theToken = T_Break; procKwd(theToken);}
int {TokenType theToken = T_Int; procKwd(theToken);}
class {TokenType theToken = T_Class; procKwd(theToken);}
extends {TokenType theToken = T_Extends; procKwd(theToken);}
if {TokenType theToken = T_If; procKwd(theToken);}
New {TokenType theToken = T_New; procKwd(theToken);}
double {TokenType theToken = T_Double; procKwd(theToken);}
interface {TokenType theToken = T_Interface; procKwd(theToken);}
implements {TokenType theToken = T_Implements; procKwd(theToken);}
else {TokenType theToken = T_Else; procKwd(theToken);}
NewArray {TokenType theToken = T_NewArray; procKwd(theToken);}
bool {TokenType theToken = T_Bool; procKwd(theToken);}
null {TokenType theToken = T_Null; procKwd(theToken);}
for {TokenType theToken = T_For; procKwd(theToken);}
return {TokenType theToken = T_Return; procKwd(theToken);}
\<= {TokenType theToken = T_LessEqual; procKwd(theToken);}
\>= {TokenType theToken = T_GreaterEqual; procKwd(theToken);}
== {TokenType theToken = T_Equal; procKwd(theToken);}
!= {TokenType theToken = T_NotEqual; procKwd(theToken);}
&& {TokenType theToken = T_And; procKwd(theToken);}
\|\| {TokenType theToken = T_Or; procKwd(theToken);}
\+ {procOp();}
- {procOp();}
\* {procOp();}
\/ {procOp();}
\< {procOp();}
> {procOp();}
= {procOp();}
! {procOp();}
; {procOp();}
, {procOp();}
\. {procOp();}
\[ {procOp();}
] {procOp();}
\( {procOp();}
\) {procOp();}
\{ {procOp();}
\} {procOp();}
[0-9]+ {TokenType theToken = T_IntConstant; procConstant(theToken);}
(0)(x|X)[0-9a-fA-F]+ {TokenType theToken = T_IntConstant; procConstant(theToken);}
[0-9]+\.([0-9]*((e|E)(\+|-)?[0-9]+)?)? {TokenType theToken = T_DoubleConstant; procConstant(theToken);}
true|false {TokenType theToken = T_BoolConstant; procConstant(theToken);}
\"[^\n\"]*\n { ReportError::UntermString(&yylloc, yytext);
	  yylloc.first_column = yylloc.last_column = 0; 
	  yylloc.first_line++;}
\"[^\n\"]*\" {TokenType theToken = T_StringConstant; procConstant(theToken);}
[a-zA-Z][a-zA-Z0-9_]* {procId();}
. {ReportError::UnrecogChar(&yylloc, yytext[0]);}
%%
/* The closing %% above marks the end of the Rules section and the beginning
 * of the User Subroutines section. All text from here to the end of the
 * file is copied verbatim to the end of the generated lex.yy.c file.
 * This section is where you put definitions of helper functions.
 */

static int procConstant(int token){
    if(strcmp(gTokenNames[token-256], "T_StringConstant") == 0){
        yylval.stringConstant = yytext;
	printf("%-12s line %d cols %d-%d is %s (value = %s)\n", yytext, yylloc.first_line, yylloc.first_column, yylloc.last_column, gTokenNames[token-256], yylval.stringConstant);
	return token;
    }
    else if(strcmp(gTokenNames[token-256], "T_IntConstant") == 0){
        yylval.integerConstant = strtol(yytext, NULL, 0);
	printf("%-12s line %d cols %d-%d is %s (value = %d)\n", yytext, yylloc.first_line, yylloc.first_column, yylloc.last_column, gTokenNames[token-256], yylval.integerConstant);
	return token;
    }
    else if(strcmp(gTokenNames[token-256], "T_DoubleConstant") == 0){
        yylval.doubleConstant = atof(yytext);
	printf("%-12s line %d cols %d-%d is %s (value = %g)\n", yytext, yylloc.first_line, yylloc.first_column, yylloc.last_column, gTokenNames[token-256], yylval.doubleConstant);
	return token;
    }
    else{
        if (strcmp(yytext, "true") == 0){
            yylval.boolConstant = true;
        }
        else {
            yylval.boolConstant = false;
        }
	printf("%-12s line %d cols %d-%d is %s (value = %s)\n", yytext, yylloc.first_line, yylloc.first_column, yylloc.last_column, gTokenNames[token-256], yytext);
	return token;
    }
}

static int procKwd(int token){
    printf("%-12s line %d cols %d-%d is %s\n", yytext, yylloc.first_line, yylloc.first_column, yylloc.last_column, gTokenNames[token-256]);
    return token;
}

static char procOp(){
    printf("%-12s line %d cols %d-%d is '%s'\n", yytext, yylloc.first_line, yylloc.first_column, yylloc.last_column, yytext);
    return yytext[0];
}

static char* procId(){
    if(yyleng > MaxIdentLen){
        ReportError::LongIdentifier(&yylloc, yytext);
	strncpy(yylval.identifier, yytext, MaxIdentLen);
	printf("%-12s line %d cols %d-%d is %s (truncated to %s)\n", yytext, yylloc.first_line, yylloc.first_column, yylloc.last_column, "T_Identifier", yylval.identifier);
        return yytext;
    }
    printf("%-12s line %d cols %d-%d is %s\n", yytext, yylloc.first_line, yylloc.first_column, yylloc.last_column, "T_Identifier");
    strcpy(yylval.identifier, yytext);
    return yytext;
}
/* Function: InitScanner
 * ---------------------
 * This function will be called before any calls to yylex().  It is designed
 * to give you an opportunity to do anything that must be done to initialize
 * the scanner (set global variables, configure starting state, etc.). One
 * thing it already does for you is assign the value of the global variable
 * yy_flex_debug that controls whether flex prints debugging information
 * about each token and what rule was matched. If set to false, no information
 * is printed. Setting it to true will give you a running trail that might
 * be helpful when debugging your scanner. Please be sure the variable is
 * set to false when submitting your final version.
 */
void InitScanner()
{
    PrintDebug("lex", "Initializing scanner");
    yy_flex_debug = false;
    yylloc.first_column = yylloc.last_column= 0;
    yylloc.first_line = 1;
}


/* Function: DoBeforeEachAction()
 * ------------------------------
 * This function is installed as the YY_USER_ACTION. This is a place
 * to group code common to all actions.
 */
static void DoBeforeEachAction()
{
    yylloc.first_column = yylloc.last_column + 1;
    yylloc.last_column = yylloc.first_column + yyleng - 1;
}
