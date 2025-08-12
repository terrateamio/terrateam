#!/usr/bin/env python3
"""
OpenAPI Path Extractor

Given an OpenAPI schema in JSON (v2 or v3) and a list of paths, extracts those paths
along with all their dependencies (schemas, parameters, responses, etc.)
to produce a new OpenAPI schema file.

Supports both OpenAPI v2 (Swagger) and v3 specifications.
"""

import json
import sys
import re
from typing import Dict, List, Set, Any, Optional
from pathlib import Path


class OpenAPIExtractor:
    def __init__(self, schema: Dict[str, Any]):
        self.schema = schema
        self.extracted_refs = set()
        self.visited_refs = set()
        self.version = self._detect_version()

    def _detect_version(self) -> str:
        """Detect if this is OpenAPI v2 or v3."""
        if "swagger" in self.schema:
            return "2.0"
        elif "openapi" in self.schema:
            return "3.0"
        else:
            raise ValueError("Unable to detect OpenAPI version. Missing 'swagger' or 'openapi' field.")

    def _infer_entity_from_path(self, path: str) -> str:
        """
        Infer entity name from API path using the first meaningful segment.

        Examples:
        - /api/v3/user -> user
        - /projects/{id}/tasks -> projects
        - /organizations/{org_id}/users/{user_id} -> organizations
        """
        # Remove leading/trailing slashes and split into segments
        segments = [s for s in path.strip('/').split('/') if s]

        # Filter out common API prefixes and find first meaningful segment
        for segment in segments:
            # Skip API versioning segments
            if re.match(r'^(api|v\d+)$', segment, re.IGNORECASE):
                continue
            # Skip parameter segments (enclosed in braces)
            if segment.startswith('{') and segment.endswith('}'):
                continue
            # This is our entity - the first meaningful path segment
            entity = segment.lower()

            return entity

        return "api"  # fallback if no meaningful segments found

    def _infer_entity_from_tags(self, tags: List[str]) -> Optional[str]:
        """Infer entity from operation tags."""
        if not tags:
            return None

        # Use the first tag, normalized
        entity = tags[0].strip()

        # Handle multi-word tags - take the last word or convert to snake_case
        if ' ' in entity:
            words = entity.split()
            # Take the last word as it's usually the main entity
            entity = words[-1]

        entity = entity.lower()

        return entity

    def _rewrite_operation_id(self, path: str, method: str, operation: Dict[str, Any]) -> Dict[str, Any]:
        """
        Rewrite operationId to <entity>/<operation> format.
        """
        if 'operationId' not in operation:
            # Skip operations without operationId
            return operation

        original_operation_id = operation['operationId']

        # Check if operationId is already in the correct format (entity/operation)
        if '/' in original_operation_id and len(original_operation_id.split('/')) == 2:
            # Already in correct format, leave unchanged
            return operation

        # Infer entity from path first, then fallback to tags
        entity = self._infer_entity_from_path(path)

        # Use tags as fallback if path inference gives generic result
        if entity == "api" and 'tags' in operation and operation['tags']:
            tag_entity = self._infer_entity_from_tags(operation['tags'])
            if tag_entity:
                entity = tag_entity

        # Create new operationId
        new_operation_id = f"{entity}/{original_operation_id}"

        # Create a copy of the operation and update the operationId
        updated_operation = operation.copy()
        updated_operation['operationId'] = new_operation_id

        return updated_operation

    def _rewrite_path_operation_ids(self, path: str, path_obj: Dict[str, Any]) -> Dict[str, Any]:
        """
        Rewrite operationIds for all HTTP methods in a path object.
        """
        updated_path = path_obj.copy()

        # Common HTTP methods to check
        http_methods = ['get', 'post', 'put', 'patch', 'delete', 'head', 'options', 'trace']

        for method in http_methods:
            if method in updated_path:
                updated_path[method] = self._rewrite_operation_id(path, method, updated_path[method])

        return updated_path

    def extract_paths(self, paths_to_extract: List[str]) -> Dict[str, Any]:
        """Extract specified paths and their dependencies."""
        if self.version == "2.0":
            return self._extract_paths_v2(paths_to_extract)
        else:
            return self._extract_paths_v3(paths_to_extract)

    def extract_paths_by_prefix(self, prefix: str) -> Dict[str, Any]:
        """Extract all paths that start with the given prefix and their dependencies."""
        matching_paths = self._find_paths_by_prefix(prefix)
        return self.extract_paths(matching_paths)

    def extract_paths_by_prefixes(self, prefixes: List[str]) -> Dict[str, Any]:
        """Extract all paths that start with any of the given prefixes and their dependencies."""
        matching_paths = self._find_paths_by_prefixes(prefixes)
        return self.extract_paths(matching_paths)

    def _find_paths_by_prefix(self, prefix: str) -> List[str]:
        """Find all paths in the schema that start with the given prefix."""
        schema_paths = self.schema.get("paths", {})
        matching_paths = []

        for path in schema_paths.keys():
            if path.startswith(prefix):
                matching_paths.append(path)

        return matching_paths

    def _find_paths_by_prefixes(self, prefixes: List[str]) -> List[str]:
        """Find all paths in the schema that start with any of the given prefixes."""
        schema_paths = self.schema.get("paths", {})
        matching_paths = []

        for path in schema_paths.keys():
            for prefix in prefixes:
                if path.startswith(prefix):
                    matching_paths.append(path)
                    break  # Don't add the same path multiple times

        return matching_paths

    def _extract_paths_v2(self, paths_to_extract: List[str]) -> Dict[str, Any]:
        """Extract paths for OpenAPI v2 (Swagger)."""
        extracted_schema = {
            "openapi": "3.0.0",  # Convert to OpenAPI v3 format
            "info": self.schema.get("info", {"title": "Extracted API", "version": "1.0.0"}),
            "paths": {},
            "components": {
                "schemas": {},
                "parameters": {},
                "responses": {}
            }
        }

        # Convert v2-specific metadata to v3 format
        if "host" in self.schema:
            schemes = self.schema.get("schemes", ["https"])
            base_path = self.schema.get("basePath", "")
            server_url = f"{schemes[0]}://{self.schema['host']}{base_path}"
            extracted_schema["servers"] = [{"url": server_url}]

        for key in ["security", "tags", "externalDocs"]:
            if key in self.schema:
                extracted_schema[key] = self.schema[key]

        if "securityDefinitions" in self.schema:
            extracted_schema["components"]["securitySchemes"] = self.schema["securityDefinitions"]

        # Extract specified paths and transform references
        for path in paths_to_extract:
            if path in self.schema.get("paths", {}):
                path_obj = self.schema["paths"][path]
                # Collect dependencies from the original path object first
                self._collect_dependencies(path_obj)
                # Transform references in the path object
                transformed_path = self._transform_definitions_to_components(path_obj)
                # Normalize parameters to OpenAPI v3 format
                transformed_path = self._normalize_parameters_in_object(transformed_path)
                # Rewrite operationIds for all HTTP methods in this path
                transformed_path = self._rewrite_path_operation_ids(path, transformed_path)
                extracted_schema["paths"][path] = transformed_path

        # Add collected definitions as schemas, parameters, and responses
        # First collect all referenced definitions to ensure we get nested dependencies
        definitions_to_process = set()
        for ref in self.extracted_refs:
            ref_parts = ref.split("/")
            if len(ref_parts) >= 3 and ref_parts[1] == "definitions":
                definitions_to_process.add(ref_parts[2])

        # Process definitions and collect nested dependencies
        processed_definitions = set()
        while definitions_to_process - processed_definitions:
            for def_name in list(definitions_to_process - processed_definitions):
                if def_name in self.schema.get("definitions", {}):
                    schema_obj = self.schema["definitions"][def_name]
                    # Collect dependencies from this definition
                    self._collect_dependencies(schema_obj)
                    # Add any new definitions found
                    for ref in self.extracted_refs:
                        ref_parts = ref.split("/")
                        if len(ref_parts) >= 3 and ref_parts[1] == "definitions":
                            definitions_to_process.add(ref_parts[2])
                processed_definitions.add(def_name)

        # Now add all collected definitions, parameters, and responses
        for ref in self.extracted_refs:
            ref_parts = ref.split("/")
            if len(ref_parts) >= 3:
                if ref_parts[1] == "definitions":
                    ref_name = ref_parts[2]
                    if ref_name in self.schema.get("definitions", {}):
                        schema_obj = self.schema["definitions"][ref_name]
                        # Transform any nested references in the schema
                        transformed_schema = self._transform_definitions_to_components(schema_obj)
                        extracted_schema["components"]["schemas"][ref_name] = transformed_schema
                elif ref_parts[1] in ["parameters", "responses"]:
                    ref_type = ref_parts[1]
                    ref_name = ref_parts[2]
                    if ref_name in self.schema.get(ref_type, {}):
                        component_obj = self.schema[ref_type][ref_name]
                        # Transform any nested references
                        transformed_component = self._transform_definitions_to_components(component_obj)
                        # Normalize parameters in referenced components
                        if ref_type == "parameters":
                            transformed_component = self._normalize_parameter(transformed_component)
                        else:
                            transformed_component = self._normalize_parameters_in_object(transformed_component)
                        extracted_schema["components"][ref_type][ref_name] = transformed_component

        # Clean up empty sections
        for section in ["schemas", "parameters", "responses", "securitySchemes"]:
            if section in extracted_schema["components"] and not extracted_schema["components"][section]:
                del extracted_schema["components"][section]

        if not extracted_schema["components"]:
            del extracted_schema["components"]

        return extracted_schema

    def _extract_paths_v3(self, paths_to_extract: List[str]) -> Dict[str, Any]:
        """Extract paths for OpenAPI v3."""
        extracted_schema = {
            "openapi": self.schema.get("openapi", "3.0.0"),
            "info": self.schema.get("info", {"title": "Extracted API", "version": "1.0.0"}),
            "paths": {},
            "components": {}
        }

        # Copy v3-specific metadata
        for key in ["servers", "security", "tags", "externalDocs"]:
            if key in self.schema:
                extracted_schema[key] = self.schema[key]

        # Extract specified paths
        for path in paths_to_extract:
            if path in self.schema.get("paths", {}):
                path_obj = self.schema["paths"][path]
                # Normalize parameters to OpenAPI v3 format
                normalized_path = self._normalize_parameters_in_object(path_obj)
                # Rewrite operationIds for all HTTP methods in this path
                transformed_path = self._rewrite_path_operation_ids(path, normalized_path)
                extracted_schema["paths"][path] = transformed_path
                self._collect_dependencies(transformed_path)

        # Add collected components
        components_sections = ["schemas", "responses", "parameters", "examples", "requestBodies", "headers", "securitySchemes", "links", "callbacks"]
        for ref in self.extracted_refs:
            ref_parts = ref.split("/")
            if len(ref_parts) >= 4 and ref_parts[1] == "components":
                component_type = ref_parts[2]
                component_name = ref_parts[3]
                if component_type in components_sections:
                    if component_type not in extracted_schema["components"]:
                        extracted_schema["components"][component_type] = {}
                    if component_name in self.schema.get("components", {}).get(component_type, {}):
                        component_obj = self.schema["components"][component_type][component_name]
                        # Normalize parameters in v3 components
                        if component_type == "parameters":
                            component_obj = self._normalize_parameter(component_obj)
                        else:
                            component_obj = self._normalize_parameters_in_object(component_obj)
                        extracted_schema["components"][component_type][component_name] = component_obj

        # Copy global security schemes if they exist
        if "components" in self.schema and "securitySchemes" in self.schema["components"]:
            if "securitySchemes" not in extracted_schema["components"]:
                extracted_schema["components"]["securitySchemes"] = {}
            extracted_schema["components"]["securitySchemes"].update(self.schema["components"]["securitySchemes"])

        # Clean up empty components
        if not extracted_schema["components"]:
            del extracted_schema["components"]

        return extracted_schema

    def _collect_dependencies(self, obj: Any):
        """Recursively collect all $ref dependencies."""
        if isinstance(obj, dict):
            if "$ref" in obj:
                ref = obj["$ref"]
                if ref not in self.visited_refs:
                    self.visited_refs.add(ref)
                    # Store the original reference for dependency resolution
                    self.extracted_refs.add(ref)

                    # Follow the reference to collect its dependencies
                    ref_obj = self._resolve_ref(ref)
                    if ref_obj:
                        self._collect_dependencies(ref_obj)
            else:
                for value in obj.values():
                    self._collect_dependencies(value)
        elif isinstance(obj, list):
            for item in obj:
                self._collect_dependencies(item)

    def _resolve_ref(self, ref: str) -> Optional[Any]:
        """Resolve a $ref to its actual object."""
        if not ref.startswith("#/"):
            return None

        parts = ref[2:].split("/")
        obj = self.schema

        try:
            for part in parts:
                obj = obj[part]
            return obj
        except (KeyError, TypeError):
            return None

    def _normalize_parameter(self, param: Dict[str, Any]) -> Dict[str, Any]:
        """
        Normalize parameter to OpenAPI v3 format by wrapping schema fields under 'schema' object.

        If a parameter contains schema-level fields like 'type', 'format', etc. directly at the top level,
        wrap them under a 'schema' object as required by OpenAPI v3.
        """
        if not isinstance(param, dict):
            return param

        # If 'schema' already exists, leave it untouched
        if 'schema' in param:
            return param

        # Schema-level fields that should be moved under 'schema'
        schema_fields = {
            'type', 'format', 'items', 'enum', 'minimum', 'maximum', 'exclusiveMinimum', 
            'exclusiveMaximum', 'minLength', 'maxLength', 'pattern', 'minItems', 'maxItems',
            'uniqueItems', 'multipleOf', 'default', 'example', 'nullable', 'readOnly',
            'writeOnly', 'xml', 'additionalProperties', 'properties', 'allOf', 'oneOf', 
            'anyOf', 'not', '$ref'
        }

        # Check if any schema fields exist at the top level
        found_schema_fields = {}
        remaining_fields = {}

        for key, value in param.items():
            if key in schema_fields:
                found_schema_fields[key] = value
            else:
                remaining_fields[key] = value

        # If schema fields were found, wrap them under 'schema'
        if found_schema_fields:
            remaining_fields['schema'] = found_schema_fields
            return remaining_fields

        return param

    def _normalize_parameters_in_object(self, obj: Any) -> Any:
        """Recursively normalize parameters in an object."""
        if isinstance(obj, dict):
            # Handle parameters at the current level
            if 'parameters' in obj and isinstance(obj['parameters'], list):
                normalized_obj = obj.copy()
                normalized_obj['parameters'] = [
                    self._normalize_parameter(param) for param in obj['parameters']
                ]
                # Continue normalizing other parts of the object
                for key, value in normalized_obj.items():
                    if key != 'parameters':
                        normalized_obj[key] = self._normalize_parameters_in_object(value)
                return normalized_obj
            else:
                return {key: self._normalize_parameters_in_object(value) for key, value in obj.items()}
        elif isinstance(obj, list):
            return [self._normalize_parameters_in_object(item) for item in obj]
        else:
            return obj

    def _transform_definitions_to_components(self, obj: Any) -> Any:
        """Transform $ref references from #/definitions/* to #/components/schemas/*."""
        if isinstance(obj, dict):
            if "$ref" in obj:
                ref = obj["$ref"]
                if ref.startswith("#/definitions/"):
                    # Transform #/definitions/SomeName to #/components/schemas/SomeName
                    obj["$ref"] = ref.replace("#/definitions/", "#/components/schemas/")
                return {key: self._transform_definitions_to_components(value) for key, value in obj.items()}
            else:
                return {key: self._transform_definitions_to_components(value) for key, value in obj.items()}
        elif isinstance(obj, list):
            return [self._transform_definitions_to_components(item) for item in obj]
        else:
            return obj


def extract_openapi_paths(schema_file: str, paths: List[str] = None, prefixes: List[str] = None, output_file: str = None):
    """
    Extract specific paths from an OpenAPI schema file.

    Args:
        schema_file: Path to the input OpenAPI JSON schema file
        paths: List of paths to extract (e.g., ["/users", "/users/{id}"])
        prefixes: List of prefixes to match paths against (e.g., ["/api/v4/projects/", "/api/v4/users/"])
        output_file: Path to the output JSON file (if None, outputs to stdout)

    Raises:
        FileNotFoundError: If the input schema file doesn't exist
        json.JSONDecodeError: If the input file is not valid JSON
        ValueError: If the schema format is invalid or neither paths nor prefixes provided
    """
    try:
        # Load the schema
        with open(schema_file, 'r', encoding='utf-8') as f:
            schema = json.load(f)
    except FileNotFoundError:
        raise FileNotFoundError(f"Schema file not found: {schema_file}")
    except json.JSONDecodeError as e:
        raise json.JSONDecodeError(f"Invalid JSON in schema file: {e}", e.doc, e.pos)

    # Validate basic schema structure
    if not isinstance(schema, dict):
        raise ValueError("Schema must be a JSON object")

    if "paths" not in schema:
        raise ValueError("Schema must contain a 'paths' section")

    # Validate that either paths or prefixes is provided
    args_provided = sum(bool(x) for x in [paths, prefixes])
    if args_provided == 0:
        raise ValueError("Either 'paths' or 'prefixes' must be provided")

    if args_provided > 1:
        raise ValueError("Cannot use multiple extraction modes simultaneously (paths, prefixes)")

    # Extract paths
    try:
        extractor = OpenAPIExtractor(schema)
        if prefixes:
            extracted_schema = extractor.extract_paths_by_prefixes(prefixes)
            # Get the actual paths that were matched for reporting
            paths = extractor._find_paths_by_prefixes(prefixes)
        else:
            extracted_schema = extractor.extract_paths(paths)
    except Exception as e:
        raise ValueError(f"Error processing schema: {e}")

    # Validate output paths
    missing_paths = [path for path in paths if path not in schema.get("paths", {})]
    if missing_paths:
        print(f"Warning: The following paths were not found in the schema: {missing_paths}", file=sys.stderr)

    # Save the result
    if output_file:
        try:
            with open(output_file, 'w', encoding='utf-8') as f:
                json.dump(extracted_schema, f, indent=2, ensure_ascii=False)
        except Exception as e:
            raise ValueError(f"Error writing output file: {e}")

        found_paths = len([path for path in paths if path in schema.get("paths", {})])
        print(f"Extracted {found_paths}/{len(paths)} paths to {output_file}", file=sys.stderr)
        print(f"OpenAPI version: {extractor.version}", file=sys.stderr)
        print(f"Dependencies found: {len(extractor.extracted_refs)} references", file=sys.stderr)
    else:
        # Output to stdout
        json.dump(extracted_schema, sys.stdout, indent=2, ensure_ascii=False)

        # Stats to stderr
        found_paths = len([path for path in paths if path in schema.get("paths", {})])
        print(f"Extracted {found_paths}/{len(paths)} paths", file=sys.stderr)
        print(f"OpenAPI version: {extractor.version}", file=sys.stderr)
        print(f"Dependencies found: {len(extractor.extracted_refs)} references", file=sys.stderr)


def main():
    """Command-line interface for OpenAPI path extraction."""
    import argparse

    parser = argparse.ArgumentParser(
        description="Extract specific paths from OpenAPI v2/v3 schema files",
        epilog="""
Examples:
  %(prog)s api.json --paths /users /users/{id} --output users_api.json
  %(prog)s swagger.json --paths /pets > pets_only.json
  %(prog)s openapi.json --paths /health /metrics /status
  %(prog)s api.json --prefixes /api/v4/projects/ /api/v4/users/ --output extracted.json
  %(prog)s api.json --prefixes /api/v4/projects/ --output projects_api.json
        """,
        formatter_class=argparse.RawDescriptionHelpFormatter
    )

    parser.add_argument("schema_file",
                        help="Input OpenAPI JSON schema file (v2 or v3)")
    parser.add_argument("--paths", nargs="+",
                        help="API paths to extract (e.g., /users /users/{id})")
    parser.add_argument("--prefixes", nargs="+",
                        help="Extract all paths starting with any of these prefixes (e.g., /api/v4/projects/ /api/v4/users/)")
    parser.add_argument("--output", "-o",
                        help="Output JSON file (default: stdout)")
    parser.add_argument("--validate", action="store_true",
                        help="Validate input schema before processing")
    parser.add_argument("--verbose", "-v", action="store_true",
                        help="Enable verbose output")

    args = parser.parse_args()

    try:
        # Validate input file exists
        if not Path(args.schema_file).exists():
            print(f"Error: Input file '{args.schema_file}' does not exist", file=sys.stderr)
            sys.exit(1)

        # Validate that either paths or prefixes is provided
        args_provided = sum(bool(x) for x in [args.paths, args.prefixes])
        if args_provided == 0:
            print("Error: Either --paths or --prefixes must be provided", file=sys.stderr)
            sys.exit(1)

        if args_provided > 1:
            print("Error: Cannot use multiple extraction modes simultaneously (--paths, --prefixes)", file=sys.stderr)
            sys.exit(1)

        # Validate paths format if paths are provided
        if args.paths:
            for path in args.paths:
                if not path.startswith('/'):
                    print(f"Warning: Path '{path}' should start with '/'", file=sys.stderr)

        # Validate prefixes format if prefixes are provided
        if args.prefixes:
            for prefix in args.prefixes:
                if not prefix.startswith('/'):
                    print(f"Warning: Prefix '{prefix}' should start with '/'", file=sys.stderr)

        if args.verbose:
            print(f"Processing schema: {args.schema_file}", file=sys.stderr)
            if args.paths:
                print(f"Extracting paths: {args.paths}", file=sys.stderr)
            elif args.prefixes:
                print(f"Extracting paths with prefixes: {args.prefixes}", file=sys.stderr)
            if args.output:
                print(f"Output file: {args.output}", file=sys.stderr)
            else:
                print("Output: stdout", file=sys.stderr)

        extract_openapi_paths(args.schema_file, args.paths, args.prefixes, args.output)

        if args.verbose:
            print("Extraction completed successfully!", file=sys.stderr)

    except (FileNotFoundError, json.JSONDecodeError, ValueError) as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)
    except KeyboardInterrupt:
        print("\nOperation cancelled by user", file=sys.stderr)
        sys.exit(1)
    except Exception as e:
        print(f"Unexpected error: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
