// lib.rs - Rust wrapper for MiniJinja with C interface

use minijinja::Environment;
use serde_json::Value;
use std::ffi::{CStr, CString};
use std::os::raw::c_char;

/// Result structure for template rendering
#[repr(C)]
pub struct TemplateResult {
    pub success: bool,
    pub message: *mut c_char,
}

impl TemplateResult {
    fn success(result: String) -> Self {
        let c_string = CString::new(result).unwrap_or_else(|_| CString::new("").unwrap());
        Self {
            success: true,
            message: c_string.into_raw(),
        }
    }

    fn error(error: String) -> Self {
        let c_string =
            CString::new(error).unwrap_or_else(|_| CString::new("Error occurred").unwrap());
        Self {
            success: false,
            message: c_string.into_raw(),
        }
    }
}

#[no_mangle]
pub extern "C" fn minijinja_render_template(
    template_str: *const c_char,
    json_str: *const c_char,
) -> TemplateResult {
    // Check for null pointers
    if template_str.is_null() || json_str.is_null() {
        return TemplateResult::error("Null pointer provided".to_string());
    }

    // Convert C strings to Rust strings
    let template = match unsafe { CStr::from_ptr(template_str) }.to_str() {
        Ok(s) => s,
        Err(_) => return TemplateResult::error("Invalid UTF-8 in template string".to_string()),
    };

    let json = match unsafe { CStr::from_ptr(json_str) }.to_str() {
        Ok(s) => s,
        Err(_) => return TemplateResult::error("Invalid UTF-8 in JSON string".to_string()),
    };

    // Parse JSON
    let context: Value = match serde_json::from_str(json) {
        Ok(value) => value,
        Err(e) => return TemplateResult::error(format!("JSON parse error: {}", e)),
    };

    // Create environment and add template
    let mut env = Environment::new();
    if let Err(e) = env.add_template("template", template) {
        return TemplateResult::error(format!("Template parse error: {}", e));
    }

    // Get template and render
    match env.get_template("template") {
        Ok(tmpl) => match tmpl.render(&context) {
            Ok(result) => TemplateResult::success(result),
            Err(e) => TemplateResult::error(format!("Render error: {}", e)),
        },
        Err(e) => TemplateResult::error(format!("Template error: {}", e)),
    }
}

/// Free a string allocated by this library
///
/// # Arguments
/// * `ptr` - Pointer to the string to free
///
/// # Safety
/// The pointer must have been allocated by this library
#[no_mangle]
pub unsafe extern "C" fn minijinja_free_string(ptr: *mut c_char) {
    if !ptr.is_null() {
        let _ = CString::from_raw(ptr);
    }
}
