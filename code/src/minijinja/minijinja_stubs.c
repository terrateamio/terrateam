#include <caml/mlvalues.h>
#include <caml/memory.h>
#include <caml/alloc.h>
#include <caml/fail.h>
#include <caml/callback.h>
#include <stdio.h>
#include <string.h>

/* External declarations for Rust functions */
typedef struct {
    int success;
    char* message;
} TemplateResult;

extern TemplateResult minijinja_render_template(const char* template_str, const char* json_str);
extern void minijinja_free_string(char* ptr);
extern const char* minijinja_version(void);

/* OCaml result type: ('a, 'b) result = Ok of 'a | Error of 'b */
static value make_ok(value v) {
    CAMLparam1(v);
    CAMLlocal1(result);
    result = caml_alloc(1, 0); /* Ok constructor (tag 0) */
    Store_field(result, 0, v);
    CAMLreturn(result);
}

static value make_error(value v) {
    CAMLparam1(v);
    CAMLlocal1(result);
    result = caml_alloc(1, 1); /* Error constructor (tag 1) */
    Store_field(result, 0, v);
    CAMLreturn(result);
}

/* Convert C string to OCaml string and free the C string */
static value string_of_c_string_and_free(char* c_str) {
    CAMLparam0();
    CAMLlocal1(ocaml_str);
    
    if (c_str == NULL) {
        ocaml_str = caml_copy_string("");
    } else {
        ocaml_str = caml_copy_string(c_str);
        minijinja_free_string(c_str);
    }
    
    CAMLreturn(ocaml_str);
}

/* Main template rendering function */
/* OCaml signature: string -> string -> (string, string) result */
value caml_minijinja_render_template(value template_val, value json_val) {
    CAMLparam2(template_val, json_val);
    CAMLlocal2(result, message);
    
    const char* template_str = String_val(template_val);
    const char* json_str = String_val(json_val);
    
    /* Call the Rust function */
    TemplateResult rust_result = minijinja_render_template(template_str, json_str);
    
    /* Convert the message to OCaml string and free the C string */
    message = string_of_c_string_and_free(rust_result.message);
    
    /* Return appropriate result based on success flag */
    if (rust_result.success) {
        result = make_ok(message);
    } else {
        result = make_error(message);
    }
    
    CAMLreturn(result);
}
