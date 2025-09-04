use std::ffi::{CStr, CString};
use std::os::raw::c_char;
use std::ptr;

/// C-compatible error structure
#[repr(C)]
pub struct ValidationError {
    pub message: *mut c_char,
    pub instance_path: *mut c_char,
}

/// C-compatible array of validation errors
#[repr(C)]
pub struct ValidationErrorList {
    pub errors: *mut ValidationError,
    pub count: usize,
}

/// Validates a JSON document against a JSON schema.
///
/// # Arguments
/// * `schema_str` - C string containing the JSON schema
/// * `json_str` - C string containing the JSON document to validate
///
/// # Returns
/// * NULL on success
/// * A pointer to ValidationErrorList struct on failure (caller must free with free_validation_error_list)
///
/// # Safety
/// This function is unsafe because it deals with raw C strings.
/// The caller must ensure that both input strings are valid, null-terminated C strings.
#[no_mangle]
pub unsafe extern "C" fn validate_json_schema(
    schema_str: *const c_char,
    json_str: *const c_char,
) -> *mut ValidationErrorList {
    // Check for null pointers
    if schema_str.is_null() || json_str.is_null() {
        return create_validation_error_list(&[("Invalid input: null pointer provided", "")]);
    }

    // Convert C strings to Rust strings
    let schema_cstr = match CStr::from_ptr(schema_str).to_str() {
        Ok(s) => s,
        Err(_) => return create_validation_error_list(&[("Invalid UTF-8 in schema string", "")]),
    };

    let json_cstr = match CStr::from_ptr(json_str).to_str() {
        Ok(s) => s,
        Err(_) => return create_validation_error_list(&[("Invalid UTF-8 in JSON string", "")]),
    };

    // Parse the schema
    let schema_value = match serde_json::from_str::<serde_json::Value>(schema_cstr) {
        Ok(v) => v,
        Err(e) => {
            return create_validation_error_list(&[(&format!("Failed to parse schema: {}", e), "")])
        }
    };

    // Parse the JSON document
    let json_value = match serde_json::from_str::<serde_json::Value>(json_cstr) {
        Ok(v) => v,
        Err(e) => {
            return create_validation_error_list(&[(&format!("Failed to parse JSON: {}", e), "")])
        }
    };

    // Compile the schema
    let compiled_schema = match jsonschema::JSONSchema::compile(&schema_value) {
        Ok(schema) => schema,
        Err(e) => {
            return create_validation_error_list(&[(
                &format!("Failed to compile schema: {}", e),
                "",
            )])
        }
    };

    // Validate the JSON document
    if compiled_schema.is_valid(&json_value) {
        ptr::null_mut() // Success
    } else {
        // Collect all validation errors
        let validation_result = compiled_schema.validate(&json_value);
        match validation_result {
            Ok(_) => ptr::null_mut(), // This shouldn't happen if is_valid returned false
            Err(errors) => {
                let error_tuples: Vec<(String, String)> = errors
                    .map(|e| {
                        let message = format!("{}", e);
                        let instance_path = e.instance_path.to_string();
                        (message, instance_path)
                    })
                    .collect();

                // Convert to string references for create_validation_error_list
                let error_refs: Vec<(&str, &str)> = error_tuples
                    .iter()
                    .map(|(msg, path)| (msg.as_str(), path.as_str()))
                    .collect();

                create_validation_error_list(&error_refs)
            }
        }
    }
}

/// Creates a ValidationErrorList from a slice of (message, instance_path) tuples.
/// Returns a pointer that must be freed with free_validation_error_list.
fn create_validation_error_list(errors: &[(&str, &str)]) -> *mut ValidationErrorList {
    if errors.is_empty() {
        return ptr::null_mut();
    }

    // Allocate array of ValidationError structs
    let mut error_array: Vec<ValidationError> = Vec::with_capacity(errors.len());

    for (message, instance_path) in errors {
        let message_cstring = match CString::new(*message) {
            Ok(s) => s,
            Err(_) => CString::new("Error message contains invalid characters").unwrap(),
        };

        let instance_path_cstring = match CString::new(*instance_path) {
            Ok(s) => s,
            Err(_) => CString::new("").unwrap(),
        };

        error_array.push(ValidationError {
            message: message_cstring.into_raw(),
            instance_path: instance_path_cstring.into_raw(),
        });
    }

    // Convert Vec to raw pointer
    let errors_ptr = error_array.as_mut_ptr();
    let count = error_array.len();
    std::mem::forget(error_array); // Prevent Vec from being dropped

    let error_list = ValidationErrorList {
        errors: errors_ptr,
        count,
    };

    Box::into_raw(Box::new(error_list))
}

/// Frees a ValidationErrorList struct that was allocated by this library.
///
/// # Arguments
/// * `ptr` - Pointer to the ValidationErrorList to free (must have been returned by validate_json_schema)
///
/// # Safety
/// This function is unsafe because it deals with raw pointers.
/// The caller must ensure that the pointer was allocated by this library and hasn't been freed already.
#[no_mangle]
pub unsafe extern "C" fn free_validation_error_list(ptr: *mut ValidationErrorList) {
    if !ptr.is_null() {
        let error_list = Box::from_raw(ptr);

        if !error_list.errors.is_null() && error_list.count > 0 {
            // Reconstruct the Vec to properly drop all elements
            let errors_vec =
                Vec::from_raw_parts(error_list.errors, error_list.count, error_list.count);

            // Free each individual error's strings
            for error in errors_vec {
                if !error.message.is_null() {
                    drop(CString::from_raw(error.message));
                }
                if !error.instance_path.is_null() {
                    drop(CString::from_raw(error.instance_path));
                }
            }
        }
    }
}
