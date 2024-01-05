#include <iostream>
#include <cstdio>
using namespace std;

class SymbolInfo
{
    string name;
    string type;

public:
    SymbolInfo *next;

    string leftPart;  // Parse Tree: Defines the left part of the production rule used
    string rightPart; // Parse Tree: Defines the right part of the production rule used
    int startLine;    // The starting line
    int endline;      // The ending line
    bool isLeaf;      // To know if it is leaf or not
    int depth;        // For printing the spaces in the parse Tree

    SymbolInfo(string name = "", string type = "", SymbolInfo *next = NULL)
    {
        this->name = name;
        this->type = type;
        this->next = next;
    }

    string getName()
    {
        return name;
    }

    void setName(string name)
    {
        this->name = name;
    }

    string getType()
    {
        return type;
    }

    void setType(string type)
    {
        this->type = type;
    }

    SymbolInfo *getNext()
    {
        return next;
    }

    void setNext(SymbolInfo *next)
    {
        this->next = next;
    }
};

class ScopeTable
{
private:
    unsigned long long hash(const string &str)
    {
        // Using sdbm hash
        unsigned long long hash = 0;
        for (char c : str)
        {
            hash = c + (hash << 6) + (hash << 16) - hash;
        }
        return hash % totalBuckets;
    }

    void deleteRecur(SymbolInfo *node)
    {
        if (node == NULL)
            return;

        deleteRecur(node->getNext());
        delete (node);
    }

    int totalBuckets;
    string id;
    SymbolInfo **table;

    int childNum; // This is used to track the scopeTables childs so that we can
                  // create the id;
public:
    ScopeTable *parentScope;

    ScopeTable(string id, int totalBuckets, ScopeTable *parentScope = NULL)
    {
        this->id = id;
        this->totalBuckets = totalBuckets;
        table = new SymbolInfo *[totalBuckets];
        for (int i = 0; i < totalBuckets; i++)
        {
            table[i] = NULL;
        }
        this->parentScope = parentScope;
        childNum = 0;
    }

    ~ScopeTable()
    {
        // cout << "\tScopeTable# " << id << " deleted" << endl;
        for (int i = 0; i < totalBuckets; i++)
        {
            deleteRecur(table[i]);
        }

        delete[] table;
    }

    void childAdded()
    {
        childNum++;
    }

    int getChildNum()
    {
        return childNum;
    }
    string getId()
    {
        return id;
    }

    // void setId(string id){
    //     this->id = id;
    // }

    int getTotalBuckets()
    {
        return totalBuckets;
    }

    SymbolInfo *lookUp(string name, bool print = false)
    {
        int index = hash(name); // %totalBuckets is being done inside the hash function
        SymbolInfo *tmp = table[index];
        int i = 1;
        while (tmp)
        {
            if (tmp->getName() == name)
            {
                if (print)
                {
                    cout << "\t\'" << name << "\' found at position <" << index + 1 << ", "
                         << i << "> of ScopeTable# " << id << endl;
                }
                return tmp;
            }

            tmp = tmp->getNext();
            i++;
        }

        return NULL;
    }

    bool insert(string name, string type, bool print = false)
    {
        int index = hash(name); // %totalBuckets is being done inside the hash function

        int i = 1;
        if (table[index] == NULL)
        {
            table[index] = new SymbolInfo(name, type);
            if (print)
            {
                cout << "\tInserted  at position <" << index + 1 << ", "
                     << i << "> of ScopeTable# " << id << endl;
            }
            return true;
        }

        SymbolInfo *tmp = table[index];
        while (true)
        {
            if (tmp->getName() == name)
            {
                if (print)
                {
                    cout << "\t\'" << name << "\' already exists in the current ScopeTable# " << id << endl;
                }
                return false;
            }
            if (tmp->getNext() == NULL)
            {
                tmp->setNext(new SymbolInfo(name, type));
                if (print)
                {
                    cout << "\tInserted  at position <" << index + 1 << ", "
                         << ++i << "> of ScopeTable# " << id << endl;
                }
                return true;
            }
            tmp = tmp->getNext();
            i++;
        }
    }

    bool Delete(string name, bool print = false)
    {
        int index = hash(name); // %totalBuckets is being done inside the hash function
        if (table[index] == NULL)
        {
            if (print)
            {
                cout << "\tNot found in the current ScopeTable# " << id << endl;
            }
            return false;
        }

        int i = 1;
        if (table[index]->getName() == name)
        {
            SymbolInfo *tmp = table[index];
            table[index] = tmp->getNext();
            delete tmp;
            if (print)
            {
                cout << "\tDeleted \'" << name << "\' from position <" << index + 1 << ", "
                     << i << "> of ScopeTable# " << id << endl;
            }
            return true;
        }

        SymbolInfo *parent = table[index];

        while (SymbolInfo *child = parent->getNext())
        {
            if (child->getName() == name)
            {
                parent->setNext(child->getNext());
                delete child;
                cout << "\tDeleted \'" << name << "\' from position <" << index + 1 << ", "
                     << ++i << "> of ScopeTable# " << id << endl;
                return true;
            }
            parent = child;
            i++;
        }

        if (print)
        {
            cout << "\tNot found in the current ScopeTable# " << id << endl;
        }
        return false;
    }

    void print()
    {
        cout << "\tScopeTable# " << id << endl;
        for (int i = 0; i < totalBuckets; i++)
        {
            cout << "\t" << i + 1;

            SymbolInfo *tmp = table[i];
            while (tmp)
            {
                cout << " --> (" << tmp->getName() << "," << tmp->getType() << ")";
                tmp = tmp->getNext();
            }
            cout << endl;
        }
    }

    void printInFile(FILE *file)
    {
        fprintf(file, "\tScopeTable# %s\n", id.c_str());
        for (int i = 0; i < totalBuckets; i++)
        {
            fprintf(file, "\t%d", i + 1);

            SymbolInfo *tmp = table[i];
            while (tmp)
            {
                fprintf(file, " --> (%s,%s)", tmp->getName().c_str(), tmp->getType().c_str());
                tmp = tmp->getNext();
            }
            fprintf(file, "\n");
        }
    }
};

class SymbolTable
{
    ScopeTable *cur;
    int totalBuckets;

    void deleteRecur(ScopeTable *table)
    {
        if (table == NULL)
        {
            return;
        }

        deleteRecur(table->parentScope);
        delete table;
    }

public:
    SymbolTable(int totalBuckets, bool print = false)
    {
        this->totalBuckets = totalBuckets;
        cur = new ScopeTable("1", totalBuckets);
        if (print)
        {
            cout << "\tScopeTable# 1 created" << endl;
        }
    }

    ~SymbolTable()
    {
        ScopeTable *tmp = cur;
        while (tmp != NULL)
        {
            ScopeTable *tmp1 = tmp->parentScope;
            delete tmp;
            tmp = tmp1;
        }
    }

    void enterScope(bool print = false)
    {
        cur->childAdded();
        string id = cur->getId() + "." + to_string(cur->getChildNum());
        cur = new ScopeTable(id, totalBuckets, cur);

        if (print)
        {
            cout << "\tScopeTable# " << id << " created" << endl;
        }
    }

    void exitScope(bool print = false)
    {
        if (cur->parentScope == NULL)
        {
            if (print)
            {
                cout << "\tScopeTable# 1 cannot be deleted" << endl;
            }
            return;
        }

        // if (print)
        // {
        //     cout << "\tScopeTable# " << cur->getId() << " deleted" << endl;
        // }

        ScopeTable *tmp = cur;
        cur = cur->parentScope;
        delete (tmp);
    }

    bool insert(string name, string type, bool print = false)
    {
        return cur->insert(name, type, print);
    }

    bool remove(string name, bool print = false)
    {
        return cur->Delete(name, print);
    }

    SymbolInfo *lookUp(string name, bool print = false)
    {
        ScopeTable *tmp = cur;
        while (tmp)
        {
            SymbolInfo *symbol = tmp->lookUp(name, print);
            if (symbol != NULL)
            {
                return symbol;
            }
            tmp = tmp->parentScope;
        }

        if (print)
        {
            cout << "\t\'" << name << "\' not found in any of the ScopeTables" << endl;
        }
        return NULL;
    }

    void printCurScopeTable()
    {
        cur->print();
    }

    void printAllScopeTable()
    {
        ScopeTable *tmp = cur;
        while (tmp)
        {
            tmp->print();
            tmp = tmp->parentScope;
        }
    }

    void printCurScopeTableInFile(FILE *file)
    {
        cur->printInFile(file);
    }

    void printAllScopeTableInFile(FILE *file)
    {
        ScopeTable *tmp = cur;
        while (tmp)
        {
            tmp->printInFile(file);
            tmp = tmp->parentScope;
        }
    }
};