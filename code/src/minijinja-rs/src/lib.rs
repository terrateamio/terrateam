// lib.rs - Rust wrapper for MiniJinja with C interface

use minijinja::Environment;
use minijinja::UndefinedBehavior;
use serde_json::Value;
use std::ffi::{CStr, CString};
use std::os::raw::c_char;

#[repr(C)]
pub struct RenderResult {
    pub success: bool,
    pub data: *mut c_char,
}

#[no_mangle]
pub extern "C" fn minijinja_render_template(
    template_str: *const c_char,
    json_str: *const c_char,
) -> RenderResult {
    // Check for null pointers
    if template_str.is_null() || json_str.is_null() {
        let error_msg = CString::new("Null pointer provided").unwrap();
        return RenderResult {
            success: false,
            data: error_msg.into_raw(),
        };
    }

    // Convert C strings to Rust strings
    let template = match unsafe { CStr::from_ptr(template_str) }.to_str() {
        Ok(s) => s,
        Err(_) => {
            let error_msg = CString::new("Invalid UTF-8 in template string").unwrap();
            return RenderResult {
                success: false,
                data: error_msg.into_raw(),
            };
        }
    };

    let json = match unsafe { CStr::from_ptr(json_str) }.to_str() {
        Ok(s) => s,
        Err(_) => {
            let error_msg = CString::new("Invalid UTF-8 in JSON string").unwrap();
            return RenderResult {
                success: false,
                data: error_msg.into_raw(),
            };
        }
    };

    // Parse JSON
    let context: Value = match serde_json::from_str(json) {
        Ok(value) => value,
        Err(e) => {
            let error_msg = CString::new(format!("JSON parse error: {}", e)).unwrap();
            return RenderResult {
                success: false,
                data: error_msg.into_raw(),
            };
        }
    };

    // Create environment and add template
    let mut env = Environment::new();
    env.set_undefined_behavior(UndefinedBehavior::Strict);
    if let Err(e) = env.add_template("template", template) {
        let error_msg = CString::new(format!("Template parse error: {}", e)).unwrap();
        return RenderResult {
            success: false,
            data: error_msg.into_raw(),
        };
    }

    // Get template and render
    match env.get_template("template") {
        Ok(tmpl) => match tmpl.render(&context) {
            Ok(result) => {
                let data = CString::new(result).unwrap();
                return RenderResult {
                    success: true,
                    data: data.into_raw(),
                };
            }
            Err(e) => {
                let error_msg = CString::new(format!("Render error: {}", e)).unwrap();
                return RenderResult {
                    success: false,
                    data: error_msg.into_raw(),
                };
            }
        },
        Err(e) => {
            let error_msg = CString::new(format!("Template error: {}", e)).unwrap();
            return RenderResult {
                success: false,
                data: error_msg.into_raw(),
            };
        }
    }
}

#[no_mangle]
pub unsafe extern "C" fn minijinja_free_string(ptr: *mut c_char) {
    if !ptr.is_null() {
        let _ = CString::from_raw(ptr);
    }
}
