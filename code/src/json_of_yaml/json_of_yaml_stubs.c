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
extern ConversionResult json_of_yaml(const char* yaml_str);
extern void free_json_string(char* s);

value caml_json_of_yaml(value yaml_val) {
    CAMLparam1(yaml_val);
    CAMLlocal2(result, error_or_success);
    
    // Extract the OCaml string
    const char* yaml_str = String_val(yaml_val);
    
    // Call the Rust function
    ConversionResult rust_result = json_of_yaml(yaml_str);
    
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
    free_json_string(rust_result.data);
    
    CAMLreturn(error_or_success);
}
