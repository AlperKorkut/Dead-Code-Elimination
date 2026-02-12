%{

#include <stdio.h>
#include <iostream>
#include <string>
#include <vector>
#include <algorithm>
#include <cstring>
#include <set>
#include <cctype>

using namespace std;
#include "y.tab.h"
extern FILE *yyin;
extern int yylex();
void yyerror(const char* s);
extern int line_number;

struct Operand {
		bool isVariable;
		string variable;
		int number;
};

struct Statement {
		string destination;
		Operand first_source;
		string op;
		Operand second_source;
};

static vector<Statement> all_statements;
static set<string> live_variables;

bool isLive(const string& variable) {
		return live_variables.find(variable) != live_variables.end();
}



%}

%union
{
int number;
char* str;
}

%token <str> VARIABLE COMMA OPERATOR
%token <number> NUMBER
%token EQUALSIGN SEMICOLON CURVYOPEN CURVYCLOSE
%type <number> signednumber

%%

program: statements livevariables
		;

statements: statements statement |
			statement
			;

statement: VARIABLE EQUALSIGN signednumber OPERATOR signednumber SEMICOLON
			{
				Statement new_statement;
				new_statement.destination = string($1);
				new_statement.first_source = Operand{false, "", $3};
				new_statement.op = string($4);
				new_statement.second_source = Operand{false, "", $5};
				all_statements.push_back(new_statement);
			}
			|
			VARIABLE EQUALSIGN signednumber OPERATOR VARIABLE SEMICOLON
			{
				Statement new_statement;
				new_statement.destination = string($1);
				new_statement.first_source = Operand{false, "", $3};
				new_statement.op = string($4);
				new_statement.second_source = Operand{true, $5, 0};
				all_statements.push_back(new_statement);
			}
			|
			VARIABLE EQUALSIGN VARIABLE OPERATOR signednumber SEMICOLON
			{
				Statement new_statement;
				new_statement.destination = string($1);
				new_statement.first_source = Operand{true, $3, 0};
				new_statement.op = string($4);
				new_statement.second_source = Operand{false, "", $5};
				all_statements.push_back(new_statement);
			}
			|
			VARIABLE EQUALSIGN VARIABLE OPERATOR VARIABLE SEMICOLON
			{
				Statement new_statement;
				new_statement.destination = string($1);
				new_statement.first_source = Operand{true, $3, 0};
				new_statement.op = string($4);
				new_statement.second_source = Operand{true, $5, 0};
				all_statements.push_back(new_statement);
			}
			|
			VARIABLE EQUALSIGN signednumber SEMICOLON
			{
				Statement new_statement;
				new_statement.destination = string($1);
				new_statement.first_source = Operand{false, "", $3};
				new_statement.op = "";
				new_statement.second_source = Operand{false, "", 0};
				all_statements.push_back(new_statement);
			}
			|
			VARIABLE EQUALSIGN VARIABLE SEMICOLON
			{
				Statement new_statement;
				new_statement.destination = string($1);
				new_statement.first_source = Operand{true, $3, 0};
				new_statement.op = "";
				new_statement.second_source = Operand{false, "", 0};
				all_statements.push_back(new_statement);
			}
			;
			
signednumber: '+' NUMBER
				{
				$$ = $2;
				}
				|
				'-' NUMBER
				{
				$$ = 0 - $2;
				}
				|
				NUMBER
				{
				$$ = $1;
				}
				;

variables: VARIABLE
			{
			live_variables.insert($1);
			}
			|
			VARIABLE COMMA variables
			{
			live_variables.insert($1);
			}
			;
				
livevariables:	CURVYOPEN variables CURVYCLOSE
				;
				
%%

vector<Statement> deadcode_elimination(vector<Statement>& all_statements){
		reverse(all_statements.begin(), all_statements.end());
		vector<Statement> kept_statements;
		for(Statement statement: all_statements) {
			if(isLive(statement.destination)) {
				live_variables.erase(statement.destination);
				if(statement.first_source.isVariable) {
					live_variables.insert(statement.first_source.variable);
				}
				if(!statement.op.empty() && statement.second_source.isVariable) {
					live_variables.insert(statement.second_source.variable);
				}
				kept_statements.push_back(statement);
			}
		}
		
		return kept_statements;
}

void yyerror(char const* s){
	cout<<"error: "<<s << " " << line_number <<endl;
}

int yywrap(){
	return 1;
}

int main(int argc, char *argv[])
{
    yyin=fopen(argv[1],"r");
    yyparse();
    fclose(yyin);
	
	vector<Statement> output = deadcode_elimination(all_statements);
	reverse(output.begin(), output.end());
	
	for(Statement statement: output) {
		if(statement.op.empty()) {
			if(statement.first_source.isVariable) {
				cout << statement.destination << " = " << statement.first_source.variable << ";" << endl;
			}
			else {
				cout << statement.destination << " = " << statement.first_source.number << ";" << endl;
			}
		}
		else {
			if(statement.first_source.isVariable) {
				if(statement.second_source.isVariable) {
					cout << statement.destination << " = " << statement.first_source.variable << " " << statement.op << " " << statement.second_source.variable << ";" << endl;
				}
				else {
					cout << statement.destination << " = " << statement.first_source.variable << " " << statement.op << " " << statement.second_source.number << ";" << endl;
				}
			}
			else {
				if(statement.second_source.isVariable) {
					cout << statement.destination << " = " << statement.first_source.number << " " << statement.op << " " << statement.second_source.variable << ";" << endl;
				}
				else {
					cout << statement.destination << " = " << statement.first_source.number << " " << statement.op << " " << statement.second_source.number << ";" << endl;
				}
			}
		}
	}
	
    return 0;
}