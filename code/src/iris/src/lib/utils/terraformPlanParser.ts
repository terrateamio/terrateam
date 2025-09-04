/**
 * Terraform Plan Parser
 * Parses both JSON and text format Terraform plans into a structured format
 */

import type {
  ParsedPlan,
  ResourceNode,
  ChangeSet,
  ChangeType,
  TerraformJsonPlan,
  TerraformResourceChange
} from '../types/terraform';

/**
 * Main parser function - detects format and delegates to appropriate parser
 */
export function parseTerraformPlan(planOutput: string): ParsedPlan {
  if (!planOutput || planOutput.trim().length === 0) {
    return createEmptyPlan();
  }

  // Try to parse as JSON first
  try {
    const trimmed = planOutput.trim();
    if (trimmed.startsWith('{')) {
      const jsonPlan = JSON.parse(trimmed);
      return parseJsonPlan(jsonPlan);
    }
  } catch (e) {
    // Not JSON, fall through to text parsing
  }

  // Parse as text format
  return parseTextPlan(planOutput);
}

/**
 * Create an empty plan structure
 */
function createEmptyPlan(): ParsedPlan {
  return {
    resources: [],
    changes: {
      create: [],
      update: [],
      delete: [],
      replace: [],
      unchanged: [],
      total: 0
    }
  };
}

/**
 * Parse JSON format Terraform plan
 */
function parseJsonPlan(plan: TerraformJsonPlan): ParsedPlan {
  const resources: ResourceNode[] = [];

  // Process resource changes
  if (plan.resource_changes) {
    for (const change of plan.resource_changes) {
      const resource = convertResourceChange(change);
      if (resource) {
        resources.push(resource);
      }
    }
  }

  // Calculate change set
  const changes = calculateChangeSet(resources);

  return {
    resources,
    changes,
    outputs: plan.output_changes,
    plannedValues: plan.planned_values,
    priorState: plan.prior_state,
    configuration: plan.configuration
  };
}

/**
 * Convert a Terraform resource change to our ResourceNode format
 */
function convertResourceChange(change: TerraformResourceChange): ResourceNode | null {
  const changeType = mapActionsToChangeType(change.change.actions);
  
  if (changeType === 'no-change' && !includeUnchangedResources()) {
    return null;
  }

  return {
    id: change.address,
    type: change.type,
    name: change.name,
    provider: change.provider_name || 'unknown',
    changeType,
    before: (change.change.before || {}) as Record<string, unknown>,
    after: (change.change.after || {}) as Record<string, unknown>,
    module: change.module_address
  };
}

/**
 * Map Terraform actions to our change type
 */
function mapActionsToChangeType(actions: string[]): ChangeType {
  if (actions.includes('create')) return 'create';
  if (actions.includes('delete') && actions.includes('create')) return 'replace';
  if (actions.includes('delete')) return 'delete';
  if (actions.includes('update')) return 'update';
  if (actions.includes('read')) return 'update';
  return 'no-change';
}



/**
 * Parse text format Terraform plan
 */
function parseTextPlan(planText: string): ParsedPlan {
  const resources: ResourceNode[] = [];
  const lines = planText.split('\n');
  
  let currentResource: Partial<ResourceNode> | null = null;
  let inResourceBlock = false;
  let currentAttributes: Record<string, unknown> = {};

  for (let i = 0; i < lines.length; i++) {
    const line = lines[i];
    
    // Check for import comment (appears before "must be replaced" resources)
    // Pattern: "# (imported from "some/id")"
    const importMatch = line.match(/^\s*#\s*\(imported from/i);
    if (importMatch) {
      // Skip this line, the actual resource info will come next
      continue;
    }
    
    // Check for resource header 
    // Matches patterns like:
    // "# aws_instance.example will be created"
    // "# module.staging.aws_instance.example will be created"
    // "# module.staging_compute_instance.google_compute_instance.this[0] will be created"
    // "# module.foo["..."].kubernetes_deployment_v1.main must be replaced"
    
    const resourceMatch = line.match(/^\s*#\s+(.+)\s+(?:will be|must be)\s+(\w+)/);
    if (resourceMatch) {
      // Save previous resource if exists
      if (currentResource && currentResource.id) {
        resources.push({
          ...currentResource as ResourceNode,
          attributes: currentAttributes
        });
      }
      
      const [, fullResourceId, action] = resourceMatch;
      
      // Extract the actual resource type and name
      // Handle both direct resources and module resources
      let type = '';
      let name = '';
      
      if (fullResourceId.startsWith('module.')) {
        // Module resource: module.staging_compute_instance.google_compute_instance.this[0]
        // or: module.foo["..."].kubernetes_deployment_v1.main
        
        // First, handle bracketed modules like module.foo["key"]
        const bracketMatch = fullResourceId.match(/^module\.[^\.]+\[[^\]]+\]\.(.+)$/);
        if (bracketMatch) {
          // Extract everything after the bracketed module
          const resourcePart = bracketMatch[1];
          const parts = resourcePart.split('.');
          
          // The first part with underscore is likely the resource type
          for (let i = 0; i < parts.length - 1; i++) {
            if (parts[i].includes('_')) {
              type = parts[i];
              name = parts.slice(i + 1).join('.');
              break;
            }
          }
          // If no underscore found, use standard convention
          if (!type && parts.length >= 2) {
            type = parts[0];
            name = parts.slice(1).join('.');
          }
        } else {
          // Standard module path without brackets
          const parts = fullResourceId.split('.');
          // Find the resource type (should be the second-to-last or third-to-last part)
          // Look for known resource type patterns
          for (let i = 1; i < parts.length - 1; i++) {
            if (parts[i].includes('_')) {
              type = parts[i];
              name = parts.slice(i + 1).join('.');
              break;
            }
          }
          // If we couldn't determine the type, use the last two parts
          if (!type && parts.length >= 2) {
            type = parts[parts.length - 2];
            name = parts[parts.length - 1];
          }
        }
      } else {
        // Direct resource: aws_instance.example
        const parts = fullResourceId.split('.');
        type = parts[0];
        name = parts.slice(1).join('.');
      }
      
      currentResource = {
        id: fullResourceId,  // Use the full ID including array indices
        type: type,
        name: name,
        provider: extractProviderFromType(type),
        changeType: mapTextActionToChangeType(action),
        before: {},
        after: {}
      };
      currentAttributes = {};
      inResourceBlock = true;
      continue;
    }

    // Check for -/+ resource declaration (replacement)
    const replacementDeclMatch = line.match(/^\s*-\/\+\s+resource\s+"([\w_]+)"\s+"([\w_\-\.]+)"/);
    if (replacementDeclMatch) {
      const [, resourceType, resourceName] = replacementDeclMatch;
      
      // If we have a current resource from the header, update it
      if (currentResource) {
        currentResource.changeType = 'replace';
        if (!currentResource.type || currentResource.type === '') {
          currentResource.type = resourceType;
        }
        if (!currentResource.name || currentResource.name === '') {
          currentResource.name = resourceName;
        }
      } else {
        // Create a new resource for this replacement
        currentResource = {
          id: `${resourceType}.${resourceName}`,
          type: resourceType,
          name: resourceName,
          provider: extractProviderFromType(resourceType),
          changeType: 'replace',
          before: {},
          after: {}
        };
        currentAttributes = {};
        inResourceBlock = true;
      }
    }
    // Also check for regular resource declaration line (e.g., '+ resource "google_compute_instance" "this" {')
    else if (line.match(/^\s*[\+\-\~]\s+resource\s+"([\w_]+)"\s+"([\w_\-\.]+)"/)) {
      const resourceDeclMatch = line.match(/^\s*[\+\-\~]\s+resource\s+"([\w_]+)"\s+"([\w_\-\.]+)"/);
      if (resourceDeclMatch && currentResource) {
        const [, resourceType, resourceName] = resourceDeclMatch;
        // Update the current resource with more accurate info if needed
        if (!currentResource.type || currentResource.type === '') {
          currentResource.type = resourceType;
        }
        if (!currentResource.name || currentResource.name === '') {
          currentResource.name = resourceName;
        }
      }
    }

    // Check for resource replacement
    if (line.includes('must be replaced')) {
      if (currentResource) {
        currentResource.changeType = 'replace';
      }
    }

    // Parse resource attributes
    if (inResourceBlock && currentResource) {
      // Check for attribute changes (e.g., "+ attribute = value")
      const attrMatch = line.match(/^\s*([\+\-\~])\s+(\w+)\s*=\s*(.+)/);
      if (attrMatch) {
        const [, indicator, key] = attrMatch;
        let value = attrMatch[3];
        
        // Check if this is the start of a multi-line value (ends with { or [)
        let fullValue = value;
        if (value.trim().endsWith('{') || value.trim().endsWith('[')) {
          // This is a multi-line value, skip to the closing bracket
          // For now, we'll just indicate it's a complex object/array
          if (value.includes('->')) {
            // Handle patterns like "null -> {" or "{ -> null"
            const parts = value.split('->').map(p => p.trim());
            if (parts[0] === 'null' && parts[1] === '{') {
              fullValue = 'null -> <object>';
            } else if (parts[0] === '{' && parts[1] === 'null') {
              fullValue = '<object> -> null';
            } else if (parts[0] === 'null' && parts[1] === '[') {
              fullValue = 'null -> <array>';
            } else if (parts[0] === '[' && parts[1] === 'null') {
              fullValue = '<array> -> null';
            } else {
              fullValue = value.replace('{', '<object>').replace('[', '<array>');
            }
          } else {
            fullValue = value.replace('{', '<object>').replace('[', '<array>');
          }
          
          // Skip lines until we find the closing bracket
          let bracketCount = 1;
          let j = i + 1;
          while (j < lines.length && bracketCount > 0) {
            const nextLine = lines[j];
            // Count opening and closing brackets
            for (const char of nextLine) {
              if (char === '{' || char === '[') bracketCount++;
              if (char === '}' || char === ']') bracketCount--;
            }
            j++;
          }
          i = j - 1; // Skip to the line after the closing bracket
          value = fullValue;
        }
        
        // Check for special patterns first before using parseAttributeValue
        // For destroy: "old_value" -> null
        // For create: null -> "new_value" 
        // For update: "old_value" -> "new_value"
        // Also handle multi-line values that we've simplified to <object> or <array>
        const destroyMatch = value.match(/^"([^"]*?)"\s*->\s*null$/);
        const createMatch = value.match(/^null\s*->\s*"([^"]*?)"$/);
        const quotedChangeMatch = value.match(/^"([^"]*?)"\s*->\s*"([^"]*?)"$/);
        const simpleDestroyMatch = value.match(/^([^\s]+)\s*->\s*null$/);
        const simpleCreateMatch = value.match(/^null\s*->\s*(\S+)$/);
        const objectCreateMatch = value.match(/^null\s*->\s*<(object|array)>$/);
        const objectDestroyMatch = value.match(/^<(object|array)>\s*->\s*null$/);
        
        if (indicator === '+') {
          if (createMatch) {
            currentResource.after![key] = createMatch[1];
          } else if (objectCreateMatch) {
            currentResource.before![key] = null;
            currentResource.after![key] = `{...}`; // Simplified representation
          } else {
            currentResource.after![key] = parseAttributeValue(value);
          }
        } else if (indicator === '-') {
          if (destroyMatch) {
            // Extract the value being destroyed (without quotes)
            currentResource.before![key] = destroyMatch[1];
          } else if (objectDestroyMatch) {
            currentResource.before![key] = `{...}`; // Simplified representation
            currentResource.after![key] = null;
          } else if (simpleDestroyMatch && simpleDestroyMatch[1] !== 'null') {
            // Handle unquoted values like: false -> null
            currentResource.before![key] = parseAttributeValue(simpleDestroyMatch[1]);
          } else {
            currentResource.before![key] = parseAttributeValue(value);
          }
        } else if (indicator === '~') {
          // Changed attribute - try to parse old and new values
          if (destroyMatch) {
            // Resource being destroyed: "value" -> null
            currentResource.before![key] = destroyMatch[1];
            currentResource.after![key] = null;
          } else if (createMatch) {
            // Resource being created: null -> "value"
            currentResource.before![key] = null;
            currentResource.after![key] = createMatch[1];
          } else if (objectCreateMatch) {
            // Multi-line object/array being created
            currentResource.before![key] = null;
            currentResource.after![key] = `{...}`;
          } else if (objectDestroyMatch) {
            // Multi-line object/array being destroyed
            currentResource.before![key] = `{...}`;
            currentResource.after![key] = null;
          } else if (quotedChangeMatch) {
            // Resource being updated: "old" -> "new"
            currentResource.before![key] = quotedChangeMatch[1];
            currentResource.after![key] = quotedChangeMatch[2];
          } else if (simpleDestroyMatch && simpleDestroyMatch[1] !== 'null') {
            // Unquoted destroy: value -> null
            currentResource.before![key] = parseAttributeValue(simpleDestroyMatch[1]);
            currentResource.after![key] = null;
          } else if (simpleCreateMatch) {
            // Unquoted create: null -> value
            currentResource.before![key] = null;
            currentResource.after![key] = parseAttributeValue(simpleCreateMatch[1]);
          } else {
            // Try general unquoted change pattern: old -> new
            const unquotedChangeMatch = value.match(/^([^\s]+)\s*->\s*(.+)$/);
            if (unquotedChangeMatch) {
              currentResource.before![key] = parseAttributeValue(unquotedChangeMatch[1]);
              currentResource.after![key] = parseAttributeValue(unquotedChangeMatch[2]);
            } else {
              // Single value change, put it in after
              currentResource.after![key] = parseAttributeValue(value);
            }
          }
        }
        // Store the final value in attributes
        currentAttributes[key] = currentResource.after?.[key] || currentResource.before?.[key];
      }

      // Check for end of resource block (empty line or next resource starting)
      if (line.trim() === '' || line.startsWith('Plan:') || (line.startsWith('#') && line.includes('will be'))) {
        inResourceBlock = false;
      }
    }

    // Parse plan summary
    if (line.startsWith('Plan:')) {
      // Save last resource if exists
      if (currentResource && currentResource.id) {
        resources.push({
          ...currentResource as ResourceNode,
          attributes: currentAttributes
        });
        currentResource = null;
      }
    }
  }

  // Save last resource if not already saved
  if (currentResource && currentResource.id) {
    resources.push({
      ...currentResource as ResourceNode,
      attributes: currentAttributes
    });
  }

  // If no resources found, try alternative parsing approach
  if (resources.length === 0) {
    const fallbackResources = parseFallbackFormat(planText);
    resources.push(...fallbackResources);
  }

  // Calculate change set
  const changes = calculateChangeSet(resources);


  return {
    resources,
    changes
  };
}

/**
 * Fallback parser for alternative plan formats
 */
function parseFallbackFormat(planText: string): ResourceNode[] {
  const resources: ResourceNode[] = [];
  const lines = planText.split('\n');
  
  // Look for patterns like "resource "type" "name" {" or variations
  for (let i = 0; i < lines.length; i++) {
    const line = lines[i];
    
    // Check for -/+ resource declarations (replacements) first
    const replaceDeclMatch = line.match(/^\s*-\/\+\s+resource\s+"([\w_]+)"\s+"([\w_\-\.\[\]]+)"/);
    if (replaceDeclMatch) {
      const [, type, name] = replaceDeclMatch;
      
      const resource: ResourceNode = {
        id: `${type}.${name}`,
        type: type,
        name: name,
        provider: extractProviderFromType(type),
        changeType: 'replace',
        before: {},
        after: {},
        attributes: {}
      };
      
      // Try to extract some attributes from the following lines
      for (let j = i + 1; j < Math.min(i + 20, lines.length); j++) {
        const attrLine = lines[j];
        if (attrLine.trim() === '}') break;
        
        const attrMatch = attrLine.match(/^\s*[\+\-\~]?\s*(\w+)\s*=\s*(.+)/);
        if (attrMatch) {
          const [, key, value] = attrMatch;
          if (resource.attributes) {
            resource.attributes[key] = parseAttributeValue(value);
          }
          // For replacements, attributes go to both before and after
          resource.before[key] = parseAttributeValue(value);
          resource.after[key] = parseAttributeValue(value);
        }
      }
      
      resources.push(resource);
      continue;
    }
    
    // Check for regular resource declarations with + or -
    const resourceDeclMatch = line.match(/^\s*([\+\-\~])\s+resource\s+"([\w_]+)"\s+"([\w_\-\.\[\]]+)"/);
    if (resourceDeclMatch) {
      const [, indicator, type, name] = resourceDeclMatch;
      
      const changeType = indicator === '+' ? 'create' : 
                        indicator === '-' ? 'delete' : 
                        'update';
      
      const resource: ResourceNode = {
        id: `${type}.${name}`,
        type: type,
        name: name,
        provider: extractProviderFromType(type),
        changeType: changeType,
        before: {},
        after: {},
        attributes: {}
      };
      
      // Try to extract some attributes from the following lines
      for (let j = i + 1; j < Math.min(i + 20, lines.length); j++) {
        const attrLine = lines[j];
        if (attrLine.trim() === '}') break;
        
        const attrMatch = attrLine.match(/^\s*[\+\-\~]?\s*(\w+)\s*=\s*(.+)/);
        if (attrMatch) {
          const [, key, value] = attrMatch;
          if (resource.attributes) {
            resource.attributes[key] = parseAttributeValue(value);
          }
          if (changeType === 'create') {
            resource.after[key] = parseAttributeValue(value);
          }
        }
      }
      
      resources.push(resource);
    }
    
    // Also look for module resources in the format we saw
    // "# module.staging_compute_instance.google_compute_instance.this[0] will be created"
    if (line.includes('will be created') || line.includes('will be destroyed') || line.includes('will be updated')) {
      
      // More flexible regex that doesn't require starting with #
      const match = line.match(/(?:^|\s)([\w\.\[\]_-]+)\s+will be\s+(\w+)/);
      if (match) {
        const [, fullPath, action] = match;
        
        // Extract resource type and name from the path
        let type = '';
        let name = '';
        
        // Split and analyze the path
        const parts = fullPath.split('.');
        
        // Find the resource type (usually has underscore)
        for (const part of parts) {
          if (part.includes('_') && !part.startsWith('module')) {
            type = part;
            const typeIndex = parts.indexOf(part);
            name = parts.slice(typeIndex + 1).join('.');
            break;
          }
        }
        
        // If no type found, use last two parts
        if (!type && parts.length >= 2) {
          type = parts[parts.length - 2];
          name = parts[parts.length - 1];
        }
        
        if (type) {
          const resource: ResourceNode = {
            id: fullPath,  // Use the full path as ID to ensure uniqueness
            type: type,
            name: name,
            provider: extractProviderFromType(type),
            changeType: mapTextActionToChangeType(action),
            before: {},
            after: {},
            attributes: {}
          };
          
          resources.push(resource);
        }
      }
    }
  }
  
  return resources;
}

/**
 * Map text action to change type
 */
function mapTextActionToChangeType(action: string): ChangeType {
  switch (action.toLowerCase()) {
    case 'created':
      return 'create';
    case 'destroyed':
      return 'delete';
    case 'updated':
    case 'modified':
      return 'update';
    case 'replaced':
      return 'replace';
    default:
      return 'no-change';
  }
}

/**
 * Extract provider from resource type
 */
function extractProviderFromType(type: string): string {
  const parts = type.split('_');
  return parts[0] || 'unknown';
}

/**
 * Parse attribute value from text
 */
function parseAttributeValue(value: string): unknown {
  value = value.trim();
  
  // This function should NOT receive "value" -> null patterns anymore
  // Those are handled by the calling code
  
  // Remove quotes if present
  if ((value.startsWith('"') && value.endsWith('"')) || 
      (value.startsWith("'") && value.endsWith("'"))) {
    // Remove outer quotes
    return value.slice(1, -1);
  }
  
  // Parse booleans
  if (value === 'true') return true;
  if (value === 'false') return false;
  
  // Parse numbers
  if (/^\d+$/.test(value)) return parseInt(value, 10);
  if (/^\d+\.\d+$/.test(value)) return parseFloat(value);
  
  // Parse arrays/lists
  if (value.startsWith('[') && value.endsWith(']')) {
    try {
      return JSON.parse(value);
    } catch {
      return value;
    }
  }
  
  // Parse objects/maps
  if (value.startsWith('{') && value.endsWith('}')) {
    try {
      return JSON.parse(value);
    } catch {
      return value;
    }
  }
  
  return value;
}

/**
 * Calculate change set from resources
 */
function calculateChangeSet(resources: ResourceNode[]): ChangeSet {
  const changes: ChangeSet = {
    create: [],
    update: [],
    delete: [],
    replace: [],
    unchanged: [],
    total: resources.length
  };

  for (const resource of resources) {
    switch (resource.changeType) {
      case 'create':
        changes.create.push(resource);
        break;
      case 'update':
        changes.update.push(resource);
        break;
      case 'delete':
        changes.delete.push(resource);
        break;
      case 'replace':
        changes.replace.push(resource);
        break;
      case 'no-change':
        changes.unchanged.push(resource);
        break;
    }
  }

  return changes;
}

/**
 * Configuration function to control whether unchanged resources are included
 */
function includeUnchangedResources(): boolean {
  // This could be made configurable via options
  return false;
}

/**
 * Extract a summary of the plan for display
 */
export function getPlanSummary(plan: ParsedPlan): string {
  const { changes } = plan;
  const parts: string[] = [];
  
  if (changes.create.length > 0) {
    parts.push(`${changes.create.length} to add`);
  }
  if (changes.update.length > 0) {
    parts.push(`${changes.update.length} to change`);
  }
  if (changes.delete.length > 0) {
    parts.push(`${changes.delete.length} to destroy`);
  }
  if (changes.replace.length > 0) {
    parts.push(`${changes.replace.length} to replace`);
  }
  
  if (parts.length === 0) {
    return 'No changes';
  }
  
  return parts.join(', ');
}