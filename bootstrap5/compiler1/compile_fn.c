#define NULL 0

int* function_scope;
int function_locals_size;

void compile_function(int* base_type, char* name) {
    int i;
    int arg_count;
    int* arg_type;
    int size;
    char* arg_name;
    int* locals;

    function_scope = scope_create();

    compiler_out(":%s\n", name);
    compiler_out("\tpush @sp\n");
    compiler_out("\tmov @fp, @sp\n");

    int arg_count = type_get_field_size(base_type);
    for (i = 0; i < arg_count; i = i + 1) {
        arg_type = type_get_subtype_type(base_type, i);
        arg_name = type_get_subtype_name(base_type, i);
        size = type_size(arg_type);
        if (size > 4) {
            compiler_fatal("Function argument %s too big: %d", arg_name, size);
        }
        compiler_out("\t# arg %s\n", arg_name);
        compiler_out("\t#define L_%s %d\n", arg_name, i * 4);
        compiler_out("\tpush r%d\n", i);

        scope_add(function_scope, arg_name, arg_type);
    }

    function_locals_size = arg_count * 4;

    // Parse function body
    compile_block();

    compiler_out(".__exit\n");
    compiler_out("\tmov @sp, @fp\n");
    compiler_out("\tpop @fp\n");
    compiler_out("\tret\n");

    function_scope = NULL;
    function_locals_size = 0;
}
