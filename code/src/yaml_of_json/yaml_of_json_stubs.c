#include <caml/mlvalues.h>
#include <caml/memory.h>
#include <caml/alloc.h>
#include <caml/fail.h>
#include <string.h>
#include <stdlib.h>
#include <stdbool.h>

// Rust result structure
typedef struct {
    bool success;
    char* data;
} ConversionResult;

// External declarations for Rust functions
extern ConversionResult yaml_of_json(const char* json_str);
extern void free_yaml_string(char* s);

value caml_yaml_of_json(value json_val) {
    CAMLparam1(json_val);
    CAMLlocal2(result, error_or_success);
    
    // Extract the OCaml string
    const char* json_str = String_val(json_val);
    
    // Call the Rust function
    ConversionResult rust_result = yaml_of_json(json_str);
    
    if (rust_result.success) {
        // Success case: return Ok(json_string)
        error_or_success = caml_alloc(1, 0); // Ok constructor
        Store_field(error_or_success, 0, caml_copy_string(rust_result.data));
    } else {
        // Error case: return Error(error_message)
        error_or_success = caml_alloc(1, 1); // Error constructor
        Store_field(error_or_success, 0, caml_copy_string(rust_result.data));
    }
    
    // Free the C string returned by Rust
    free_yaml_string(rust_result.data);
    
    CAMLreturn(error_or_success);
}
