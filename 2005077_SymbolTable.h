#include <iostream>
#include <cstdio>
using namespace std;

class SymbolInfo;
class LinkedList
{
public:
    SymbolInfo *head;
    SymbolInfo *tail;
    int length;

    LinkedList();
    ~LinkedList();
    void insert(SymbolInfo *s);
    void clear();
    int getLength();
};

class SymbolInfo
{
    string name;
    string type; // For functions return type is saved here..
    int flag;    // 0 for variable, 1 for array, 2 for function,
                 // 3 for ParseTree Memeber. Some parse tree members also need to be identified as
                 // variable, array or function. For that purpose this flag is used.
public:
    SymbolInfo *next;

    LinkedList *params;
    bool isDefined;
    bool isDeclared;

    string dType; // Some symbols like factor, expression requires a extra data type.
                  // This is used for that purpose.
    bool isZero;  // For expressions, factors etc that evaluates to zero

    bool error; // For error recovery. Default value for it is false

    SymbolInfo *children; // For the parse Tree childrens
    string leftPart;      // Parse Tree: Defines the left part of the production rule used
    string rightPart;     // Parse Tree: Defines the right part of the production rule used
    int startLine;        // The starting line
    int endLine;          // The ending line
    bool isLeaf;          // To know if it is leaf or not
    int depth;            // For printing the spaces in the parse Tree

    int arraySize; // For array
    SymbolInfo(string name = "", string type = "", SymbolInfo *next = NULL);
    SymbolInfo(string name, string type, int flag);
    ~SymbolInfo();
    static SymbolInfo *getVariableSymbol(string name, string type);
    static SymbolInfo *getArrayTypeSymbol(string name, string type, int arraySize);
    int getFlag();
    void setFlag(int flag);
    string getName();
    void setName(string name);
    string getType();
    void setType(string type);
    SymbolInfo *getNext();
    void setNext(SymbolInfo *next);
};

class ScopeTable
{
private:
    unsigned long long hash(const string &str);
    void deleteRecur(SymbolInfo *node);

    int totalBuckets;
    string id;
    SymbolInfo **table;

    int childNum; // This is used to track the scopeTables childs so that we can
                  // create the id;
public:
    ScopeTable *parentScope;

    ScopeTable(string id, int totalBuckets, ScopeTable *parentScope = NULL);
    ~ScopeTable();
    void childAdded();
    int getChildNum();
    string getId();
    int getTotalBuckets();
    SymbolInfo *lookUp(string name, bool print = false);
    bool insert(string name, string type, int flag, SymbolInfo *data = NULL);
    bool insert(SymbolInfo *sym);
    bool Delete(string name, bool print = false);
    void print();
    void printInFile(FILE *file);
};

class SymbolTable
{
    ScopeTable *cur;
    int totalBuckets;

    void deleteRecur(ScopeTable *table);

public:
    SymbolTable(int totalBuckets, bool print = false);
    ~SymbolTable();
    void enterScope(bool print = false);
    void exitScope(bool print = false);
    // Extra data are passed via a SymbolInfo pointer
    bool insert(string name, string type, int flag, SymbolInfo *data = NULL);
    bool insert(SymbolInfo *sym);
    bool remove(string name, bool print = false);
    SymbolInfo *lookUp(string name, bool print = false);
    void printCurScopeTable();
    void printAllScopeTable();
    void printCurScopeTableInFile(FILE *file);
    void printAllScopeTableInFile(FILE *file);
};