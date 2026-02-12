all: lex yacc
	g++ lex.yy.c y.tab.c -ll -o deadcodeelimination

yacc: termproject.y
	yacc -d deadcodeelimination.y

lex: termproject.l
	lex deadcodeelimination.l
clean: 
	rm lex.yy.c y.tab.c  y.tab.h  deadcodeelimination
