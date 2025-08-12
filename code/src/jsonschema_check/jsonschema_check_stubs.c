/* jsonschema_stubs.c - C stubs for OCaml using traditional C interface */

#include <caml/mlvalues.h>
#include <caml/memory.h>
#include <caml/alloc.h>
#include <caml/custom.h>
#include <caml/fail.h>
#include <string.h>
#include <stdio.h>

// Forward declarations of our Rust functions
typedef struct ValidationError {
    char* message;
    char* instance_path;
} ValidationError;

typedef struct ValidationErrorList {
    ValidationError* errors;
    size_t count;
} ValidationErrorList;

extern ValidationErrorList* validate_json_schema(const char* schema_str, const char* json_str);
extern void free_validation_error_list(ValidationErrorList* ptr);

// Helper function to create OCaml validation_error record
// Assumes the OCaml record type is: { message : string; instance_path : string }
value create_validation_error_record(const ValidationError* error) {
    CAMLparam0();
    CAMLlocal3(record, message_val, instance_path_val);
    
    // Create OCaml strings
    message_val = caml_copy_string(error->message ? error->message : "");
    instance_path_val = caml_copy_string(error->instance_path ? error->instance_path : "");
    
    // Create the record with 2 fields
    record = caml_alloc(2, 0);
    Store_field(record, 0, message_val);      // message field
    Store_field(record, 1, instance_path_val); // instance_path field
    
    CAMLreturn(record);
}

// Helper function to create OCaml list from ValidationError array
value create_validation_error_list(const ValidationError* errors, size_t count) {
    CAMLparam0();
    CAMLlocal3(list, cons, error_record);
    
    list = Val_emptylist; // Start with empty list []
    
    // Build list in reverse order (OCaml lists are built from tail to head)
    for (int i = (int)count - 1; i >= 0; i--) {
        error_record = create_validation_error_record(&errors[i]);
        
        // Create cons cell (::)
        cons = caml_alloc(2, 0);
        Store_field(cons, 0, error_record); // Head
        Store_field(cons, 1, list);         // Tail
        list = cons;
    }
    
    CAMLreturn(list);
}

// OCaml stub for validate_json_schema
// Returns: Ok () | Error (validation_error list)
value caml_validate_json_schema(value schema_val, value json_val) {
    CAMLparam2(schema_val, json_val);
    CAMLlocal2(result, error_list);
    
    const char* schema_str = String_val(schema_val);
    const char* json_str = String_val(json_val);
    
    ValidationErrorList* errors = validate_json_schema(schema_str, json_str);
    
    if (errors == NULL) {
        // Success - return Ok ()
        result = caml_alloc(1, 0); // Ok constructor (tag 0)
        Store_field(result, 0, Val_unit);
    } else {
        // Error - return Error (error_list)
        error_list = create_validation_error_list(errors->errors, errors->count);
        result = caml_alloc(1, 1); // Error constructor (tag 1)
        Store_field(result, 0, error_list);
        
        // Free the C structure
        free_validation_error_list(errors);
    }
    
    CAMLreturn(result);
}
