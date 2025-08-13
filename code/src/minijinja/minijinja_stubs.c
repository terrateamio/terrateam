#include <caml/mlvalues.h>
#include <caml/memory.h>
#include <caml/alloc.h>
#include <caml/fail.h>
#include <caml/callback.h>
#include <stdio.h>
#include <string.h>
#include <stdbool.h>

/* External declarations for Rust functions */
typedef struct {
    bool success;
    char* data;
} RenderResult;


extern RenderResult minijinja_render_template(const char* template_str, const char* json_str);
extern void minijinja_free_string(char* ptr);

/* Main template rendering function */
/* OCaml signature: string -> string -> (string, string) result */
value caml_minijinja_render_template(value template_val, value json_val) {
    CAMLparam2(template_val, json_val);
    CAMLlocal2(result, message);
    
    const char* template_str = String_val(template_val);
    const char* json_str = String_val(json_val);
    
    /* Call the Rust function */
    RenderResult rust_result = minijinja_render_template(template_str, json_str);

    if (rust_result.success) {
      result = caml_alloc(1, 0); // Ok constructor
      Store_field(result, 0, caml_copy_string(rust_result.data));
    } else {
      result = caml_alloc(1, 1); // Error constructor
      Store_field(result, 0, caml_copy_string(rust_result.data));
    }

    minijinja_free_string(rust_result.data);
    
    CAMLreturn(result);
}
