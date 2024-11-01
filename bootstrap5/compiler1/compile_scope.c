#define NULL 0

int* global_scope;

// BUG: This is a buggy construct - we can't get a function address,
// and this array init doesn't properly mangle identifiers.
int ht_funcs[] = { __lex_hash_table_test_key_hash, __lex_hash_table_test_key_cmp };

int* scope_create() {
    return ht_init(ht_funcs[0], ht_funcs[1]);
}

void scope_add(int* scope, char* name, int* type) {
    ht_insert(scope, name, type);
}

int* scope_lookup(int* scope, char* name) {
    int* type;
    type = ht_lookup(scope, name);
    return type;
}
