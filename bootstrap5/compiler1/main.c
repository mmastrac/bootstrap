int compile_file(char* in, char* out) {
    int token;
    char buffer[256];

    printf("Compiling file %s to %s\n", in, out);

    compiler_init(in, out);

    compile_translation_unit();

    return 0;
}

char* compute_output_file(char* in, char* out_dir) {
    char* out;
    char* ext;
    char* last_dot;
    char* last_slash;
    int len;

    last_slash = strrchr(in, '/');

    out = malloc((strlen(last_slash) + strlen(out_dir)) + 1);
    strcpy(out, out_dir);
    strcat(out, last_slash);

    out[strlen(out) - 1] = 's';
    return out;
}

int main(int argc, int* argv) {
    char* out;
    char* in;
    int i;
    int len;

    if (argc < 2) {
        printf("Usage: %s <input file> <input file> ... <output dir>\n", argv[0]);
        return 1;
    }

    out = argv[argc - 1];

    for (i = 1; i < (argc - 1); i = i + 1) {
        in = argv[i];
        len = strlen(in);
        if ((in[len - 2] != '.') || (in[len - 1] != 'c')) {
            printf("Error: %s is not a C file\n", in);
            return 1;
        }
        if (compile_file(in, compute_output_file(in, out)) != 0) {
            printf("Error compiling file %s\n", in);
            return 1;
        }

        // Reset the heap for each file
        _reset_crt();
    }
}
