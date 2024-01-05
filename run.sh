#!/bin/bash
if [ $# -ne 1 ]
  then
    echo "No arguments supplied"
    exit 1
fi

mkdir -p ./bin
echo 'Created the bin directory'
cp -f 2005077_SymbolTable.h ./bin
echo 'Copied the header file'

yacc -d 2005077_Parser.y -o ./bin/parser.cpp
mv -f y.tab.h ./bin/y.tab.h
echo 'Generated the parser.cpp file.'

g++ -w -c -o ./bin/parser.o ./bin/parser.cpp
echo 'Generated the parser object file.'

flex -o ./bin/scanner.cpp Scanner.l
echo 'Generated the scanner.cpp file.'
g++ -w -c -o ./bin/scanner.o ./bin/scanner.cpp
echo 'Generated the scanner object file.'

g++ ./bin/parser.o ./bin/scanner.o -lfl -o ./bin/compiler
echo 'compiler generated'

mkdir -p output
./bin/compiler $1