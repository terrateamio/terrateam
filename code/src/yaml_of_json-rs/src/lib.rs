use serde_json;
use serde_yaml;
use std::ffi::{CStr, CString};
use std::os::raw::c_char;

#[repr(C)]
pub struct ConversionResult {
    pub success: bool,
    pub data: *mut c_char,
}

#[no_mangle]
pub unsafe extern "C" fn yaml_of_json(json_str: *const c_char) -> ConversionResult {
    // Check for null pointer
    if json_str.is_null() {
        let error_msg = CString::new("Input string is null").unwrap();
        return ConversionResult {
            success: false,
            data: error_msg.into_raw(),
        };
    }

    // Convert C string to Rust string
    let c_str = match CStr::from_ptr(json_str).to_str() {
        Ok(s) => s,
        Err(e) => {
            let error_msg = CString::new(format!("Invalid UTF-8 string: {}", e)).unwrap();
            return ConversionResult {
                success: false,
                data: error_msg.into_raw(),
            };
        }
    };

    // Parse YAML
    let json_value: serde_json::Value = match serde_json::from_str(c_str) {
        Ok(v) => v,
        Err(e) => {
            let error_msg = CString::new(format!("JSON parsing error: {}", e)).unwrap();
            return ConversionResult {
                success: false,
                data: error_msg.into_raw(),
            };
        }
    };

    // Convert to JSON
    let yaml_string = match serde_yaml::to_string(&json_value) {
        Ok(s) => s,
        Err(e) => {
            let error_msg = CString::new(format!("YAML serialization error: {}", e)).unwrap();
            return ConversionResult {
                success: false,
                data: error_msg.into_raw(),
            };
        }
    };

    // Convert back to C string
    match CString::new(yaml_string) {
        Ok(c_string) => ConversionResult {
            success: true,
            data: c_string.into_raw(),
        },
        Err(e) => {
            let error_msg = CString::new(format!("String conversion error: {}", e)).unwrap();
            ConversionResult {
                success: false,
                data: error_msg.into_raw(),
            }
        }
    }
}

#[no_mangle]
pub unsafe extern "C" fn free_yaml_string(s: *mut c_char) {
    if !s.is_null() {
        let _ = CString::from_raw(s);
    }
}
