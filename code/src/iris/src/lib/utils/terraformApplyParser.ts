/**
 * Terraform Apply Output Parser
 * Parses Terraform apply outputs to extract resource changes
 */

import type {
  ParsedPlan,
  ResourceNode,
  ChangeType,
} from '../types/terraform';

/**
 * Parse Terraform apply output to extract resource changes
 */
export function parseTerraformApply(applyOutput: string): ParsedPlan {
  if (!applyOutput || applyOutput.trim().length === 0) {
    return createEmptyPlan();
  }

  const resources: ResourceNode[] = [];
  const lines = applyOutput.split('\n');
  
  let currentResource: Partial<ResourceNode> | null = null;
  let currentAttributes: Record<string, unknown> = {};
  let inResourceBlock = false;
  let captureMode: 'none' | 'creating' | 'modifying' | 'destroying' | 'reading' | 'refreshing' = 'none';

  for (let i = 0; i < lines.length; i++) {
    const line = lines[i];
    const trimmedLine = line.trim();
    
    // Check for resource operation headers
    // Examples:
    // "google_compute_instance.this[0]: Creating..."
    // "aws_instance.example: Modifying... [id=i-1234567890abcdef0]"
    // "module.vpc.aws_subnet.private[0]: Destroying... [id=subnet-12345]"
    // "data.aws_ami.ubuntu: Reading..."
    // "aws_instance.example: Creation complete after 42s [id=i-1234567890abcdef0]"
    // "aws_instance.example: Modifications complete after 10s [id=i-1234567890abcdef0]"
    // "aws_instance.example: Destruction complete after 5s"
    
    // Check for resource operation start
    const operationStartMatch = line.match(/^([^:]+):\s+(Creating|Modifying|Destroying|Reading|Refreshing)\.{3}/);
    if (operationStartMatch) {
      // Save previous resource if exists
      if (currentResource && currentResource.id) {
        resources.push({
          ...currentResource as ResourceNode,
          attributes: currentAttributes
        });
      }
      
      const [, resourceId, operation] = operationStartMatch;
      const changeType = mapOperationToChangeType(operation);
      
      // Extract type and name from resource ID
      const { type, name } = parseResourceId(resourceId.trim());
      
      currentResource = {
        id: resourceId.trim(),
        type,
        name,
        provider: extractProviderFromType(type),
        changeType,
        before: {},
        after: {},
      };
      currentAttributes = {};
      inResourceBlock = true;
      // Map operation to captureMode
      const lowerOp = operation.toLowerCase();
      switch (lowerOp) {
        case 'creating':
        case 'modifying':
        case 'destroying':
        case 'reading':
        case 'refreshing':
          captureMode = lowerOp;
          break;
        default:
          captureMode = 'none';
          break;
      }
      
      // For destroying operations, we'll put any captured info in 'before'
      if (captureMode === 'destroying') {
        // Extract ID if present in the same line
        const idMatch = line.match(/\[id=([^\]]+)\]/);
        if (idMatch) {
          currentResource.before!['id'] = idMatch[1];
          currentAttributes['id'] = idMatch[1];
        }
      }
      continue;
    }
    
    // Check for resource operation completion
    const completionMatch = line.match(/^([^:]+):\s+(Creation|Modifications?|Destruction|Read)\s+complete/);
    if (completionMatch) {
      const [, resourceId] = completionMatch;
      
      // If we have a current resource and it matches, update it
      if (currentResource && currentResource.id === resourceId.trim()) {
        // Extract any ID from the completion message
        const idMatch = line.match(/\[id=([^\]]+)\]/);
        if (idMatch) {
          currentAttributes['id'] = idMatch[1];
          // For destroyed resources, the ID goes in 'before', not 'after'
          if (currentResource.changeType === 'delete') {
            currentResource.before!['id'] = idMatch[1];
          } else {
            currentResource.after!['id'] = idMatch[1];
          }
        }
        
        // For destroyed resources, provide a meaningful message if no attributes were captured
        if (currentResource.changeType === 'delete' && Object.keys(currentResource.before!).length === 0) {
          currentResource.before = {
            _status: 'Resource was destroyed',
            _message: 'Details of the destroyed resource are not available in the apply output'
          };
          if (idMatch) {
            currentResource.before['id'] = idMatch[1];
          }
        }
        
        // Save the resource
        resources.push({
          ...currentResource as ResourceNode,
          attributes: currentAttributes
        });
        
        currentResource = null;
        currentAttributes = {};
        inResourceBlock = false;
        captureMode = 'none';
      } else if (!currentResource) {
        // Sometimes we see completion without a start (for quick operations)
        const [, resourceId, operationType] = completionMatch;
        const changeType = operationType.startsWith('Creation') ? 'create' :
                          operationType.startsWith('Modif') ? 'update' :
                          operationType.startsWith('Destruction') ? 'delete' : 'no-change';
        
        const { type, name } = parseResourceId(resourceId.trim());
        
        // Extract ID if present
        const idMatch = line.match(/\[id=([^\]]+)\]/);
        const attributes: Record<string, unknown> = {};
        let after: Record<string, unknown> = {};
        let before: Record<string, unknown> = {};
        
        if (idMatch) {
          attributes['id'] = idMatch[1];
          if (changeType === 'delete') {
            before['id'] = idMatch[1];
            before['_status'] = 'Resource was destroyed';
          } else {
            after['id'] = idMatch[1];
          }
        } else if (changeType === 'delete') {
          before = {
            _status: 'Resource was destroyed',
            _message: 'Details of the destroyed resource are not available in the apply output'
          };
        }
        
        resources.push({
          id: resourceId.trim(),
          type,
          name,
          provider: extractProviderFromType(type),
          changeType,
          before,
          after,
          attributes
        });
      }
      continue;
    }
    
    // Check for "Still creating/modifying/destroying..." messages
    if (line.match(/^([^:]+):\s+Still\s+(creating|modifying|destroying)\.{3}/)) {
      // These are progress messages, we can skip them
      continue;
    }
    
    // Parse resource attributes during creation/modification/destruction
    if (inResourceBlock && currentResource) {
      // Look for attribute lines (usually indented with + or ~ or -)
      const attrMatch = trimmedLine.match(/^([\+\~\-])\s+(\w+)\s*[:=]\s*(.+)/);
      if (attrMatch) {
        let [, indicator, key, value] = attrMatch;
        
        // Check if this is the start of a multi-line value (ends with { or [)
        if (value.trim().endsWith('{') || value.trim().endsWith('[')) {
          // This is a multi-line value, skip to the closing bracket
          // For now, we'll just indicate it's a complex object/array
          if (value.includes('->')) {
            // Handle patterns like "null -> {" or "{ -> null"
            const parts = value.split('->').map(p => p.trim());
            if (parts[0] === 'null' && parts[1] === '{') {
              value = 'null -> <object>';
            } else if (parts[0] === '{' && parts[1] === 'null') {
              value = '<object> -> null';
            } else if (parts[0] === 'null' && parts[1] === '[') {
              value = 'null -> <array>';
            } else if (parts[0] === '[' && parts[1] === 'null') {
              value = '<array> -> null';
            } else {
              value = value.replace('{', '<object>').replace('[', '<array>');
            }
          } else {
            value = value.replace('{', '<object>').replace('[', '<array>');
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
        }
        
        // Check for special patterns first
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
            currentAttributes[key] = createMatch[1];
          } else if (objectCreateMatch) {
            currentResource.before![key] = null;
            currentResource.after![key] = `{...}`;
            currentAttributes[key] = `{...}`;
          } else {
            const cleanValue = parseAttributeValue(value);
            currentResource.after![key] = cleanValue;
            currentAttributes[key] = cleanValue;
          }
        } else if (indicator === '-') {
          if (destroyMatch) {
            currentResource.before![key] = destroyMatch[1];
            currentAttributes[key] = destroyMatch[1];
          } else if (objectDestroyMatch) {
            currentResource.before![key] = `{...}`;
            currentResource.after![key] = null;
            currentAttributes[key] = `{...}`;
          } else if (simpleDestroyMatch && simpleDestroyMatch[1] !== 'null') {
            currentResource.before![key] = parseAttributeValue(simpleDestroyMatch[1]);
            currentAttributes[key] = parseAttributeValue(simpleDestroyMatch[1]);
          } else {
            const cleanValue = parseAttributeValue(value);
            currentResource.before![key] = cleanValue;
            currentAttributes[key] = cleanValue;
          }
        } else if (indicator === '~') {
          // For modifications, we might see old -> new format
          if (destroyMatch) {
            currentResource.before![key] = destroyMatch[1];
            currentResource.after![key] = null;
          } else if (createMatch) {
            currentResource.before![key] = null;
            currentResource.after![key] = createMatch[1];
          } else if (objectCreateMatch) {
            currentResource.before![key] = null;
            currentResource.after![key] = `{...}`;
          } else if (objectDestroyMatch) {
            currentResource.before![key] = `{...}`;
            currentResource.after![key] = null;
          } else if (quotedChangeMatch) {
            currentResource.before![key] = quotedChangeMatch[1];
            currentResource.after![key] = quotedChangeMatch[2];
          } else if (simpleDestroyMatch && simpleDestroyMatch[1] !== 'null') {
            currentResource.before![key] = parseAttributeValue(simpleDestroyMatch[1]);
            currentResource.after![key] = null;
          } else if (simpleCreateMatch) {
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
          // Store the final value in attributes
          currentAttributes[key] = currentResource.after?.[key] || currentResource.before?.[key];
        }
      }
      
      // Also look for simple attribute format without indicators
      const simpleAttrMatch = trimmedLine.match(/^(\w+)\s*[:=]\s*(.+)/);
      if (simpleAttrMatch && !attrMatch && currentResource) {
        const [, key, value] = simpleAttrMatch;
        const cleanValue = parseAttributeValue(value);
        currentAttributes[key] = cleanValue;
        
        if (captureMode === 'creating') {
          currentResource.after![key] = cleanValue;
        } else if (captureMode === 'modifying') {
          currentResource.after![key] = cleanValue;
        } else if (captureMode === 'destroying') {
          // For destroying, attributes go in 'before'
          currentResource.before![key] = cleanValue;
        } else if (captureMode === 'reading' || captureMode === 'refreshing') {
          // For reading/refreshing operations, we typically don't capture state changes
          // but we can store in attributes for reference
        }
        // Note: if captureMode is 'none', we don't modify resource state
      }
    }
    
    // Check for apply summary
    if (line.startsWith('Apply complete!') || line.includes('Resources:')) {
      // Save last resource if exists
      if (currentResource && currentResource.id) {
        resources.push({
          ...currentResource as ResourceNode,
          attributes: currentAttributes
        });
        currentResource = null;
      }
      
      // Parse the summary if present
      // Example: "Apply complete! Resources: 3 added, 1 changed, 2 destroyed."
      const summaryMatch = line.match(/(\d+)\s+added|(\d+)\s+changed|(\d+)\s+destroyed/g);
      if (summaryMatch) {
        // We could use this to validate our parsing
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
  
  // Calculate change set
  const changes = calculateChangeSet(resources);
  
  return {
    resources,
    changes
  };
}

/**
 * Parse resource ID to extract type and name
 */
function parseResourceId(resourceId: string): { type: string; name: string } {
  // Handle module resources: module.vpc.aws_subnet.private[0]
  // Handle data resources: data.aws_ami.ubuntu
  // Handle regular resources: aws_instance.example
  
  let cleanId = resourceId;
  
  // Remove "data." prefix if present
  if (cleanId.startsWith('data.')) {
    cleanId = cleanId.substring(5);
  }
  
  // Remove "module." prefix and module name if present
  if (cleanId.startsWith('module.')) {
    const parts = cleanId.split('.');
    // Skip "module" and the module name, keep the rest
    cleanId = parts.slice(2).join('.');
  }
  
  // Now we should have something like: aws_instance.example or aws_instance.example[0]
  const parts = cleanId.split('.');
  
  if (parts.length >= 2) {
    // First part is the resource type
    const type = parts[0];
    // Rest is the name (including any array indices)
    const name = parts.slice(1).join('.');
    return { type, name };
  }
  
  // Fallback: treat the whole thing as the type
  return { type: cleanId, name: '' };
}

/**
 * Map operation text to change type
 */
function mapOperationToChangeType(operation: string): ChangeType {
  switch (operation.toLowerCase()) {
    case 'creating':
      return 'create';
    case 'modifying':
    case 'refreshing':
      return 'update';
    case 'destroying':
      return 'delete';
    case 'reading':
      return 'no-change';
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
  
  // Remove "known after apply" and similar placeholders
  if (value.includes('known after apply')) {
    return '<computed>';
  }
  
  return value;
}

/**
 * Calculate change set from resources
 */
function calculateChangeSet(resources: ResourceNode[]) {
  const changes = {
    create: [] as ResourceNode[],
    update: [] as ResourceNode[],
    delete: [] as ResourceNode[],
    replace: [] as ResourceNode[],
    unchanged: [] as ResourceNode[],
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
 * Get a summary of the apply results
 */
export function getApplySummary(plan: ParsedPlan): string {
  const { changes } = plan;
  const parts: string[] = [];
  
  if (changes.create.length > 0) {
    parts.push(`${changes.create.length} added`);
  }
  if (changes.update.length > 0) {
    parts.push(`${changes.update.length} changed`);
  }
  if (changes.delete.length > 0) {
    parts.push(`${changes.delete.length} destroyed`);
  }
  if (changes.replace.length > 0) {
    parts.push(`${changes.replace.length} replaced`);
  }
  
  if (parts.length === 0) {
    return 'No changes applied';
  }
  
  return parts.join(', ');
}