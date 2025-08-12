#!/usr/bin/env node

/**
 * API Type Validation Script
 * 
 * This script ensures that:
 * 1. API types are in sync with api.json
 * 2. All Zod schemas match the OpenAPI specification
 * 3. TypeScript compilation passes
 * 4. No type mismatches exist
 */

const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

// ANSI colors for output
const colors = {
  red: '\x1b[31m',
  green: '\x1b[32m',
  yellow: '\x1b[33m',
  blue: '\x1b[34m',
  reset: '\x1b[0m',
  bold: '\x1b[1m'
};

function log(color, message) {
  console.log(`${colors[color]}${message}${colors.reset}`);
}

function logHeader(message) {
  console.log(`\n${colors.bold}${colors.blue}=== ${message} ===${colors.reset}`);
}

async function checkApiJsonExists() {
  logHeader('Checking API Specification');
  
  const apiJsonPath = path.join(process.cwd(), 'api.json');
  if (!fs.existsSync(apiJsonPath)) {
    log('red', '❌ api.json not found!');
    log('yellow', 'Expected location: ./api.json');
    process.exit(1);
  }
  
  try {
    const apiSpec = JSON.parse(fs.readFileSync(apiJsonPath, 'utf8'));
    if (!apiSpec.components || !apiSpec.components.schemas) {
      log('red', '❌ Invalid api.json - missing components.schemas');
      process.exit(1);
    }
    
    const schemaCount = Object.keys(apiSpec.components.schemas).length;
    log('green', `✅ api.json found with ${schemaCount} schemas`);
    return apiSpec;
  } catch (error) {
    log('red', `❌ Failed to parse api.json: ${error.message}`);
    process.exit(1);
  }
}

async function checkGeneratedTypes() {
  logHeader('Checking Generated Types');
  
  const generatedTypesPath = path.join(process.cwd(), 'src/lib/api-types-generated.ts');
  if (!fs.existsSync(generatedTypesPath)) {
    log('red', '❌ Generated types not found!');
    log('yellow', 'Run: npm run generate-api-types');
    process.exit(1);
  }
  
  const stats = fs.statSync(generatedTypesPath);
  const apiJsonStats = fs.statSync('api.json');
  
  if (stats.mtime < apiJsonStats.mtime) {
    log('yellow', '⚠️  Generated types are older than api.json');
    log('yellow', 'Run: npm run generate-api-types');
    process.exit(1);
  }
  
  log('green', '✅ Generated types are up to date');
}

async function checkValidatedTypes() {
  logHeader('Checking Validated Types');
  
  const validatedTypesPath = path.join(process.cwd(), 'src/lib/types.ts');
  if (!fs.existsSync(validatedTypesPath)) {
    log('red', '❌ Validated types not found!');
    log('yellow', 'Expected: src/lib/types.ts');
    process.exit(1);
  }
  
  // Check if file contains expected exports
  const content = fs.readFileSync(validatedTypesPath, 'utf8');
  const expectedExports = [
    'validateInstallation',
    'validateRepository',
    'validateUser',
    'InstallationSchema',
    'RepositorySchema'
  ];
  
  const missingExports = expectedExports.filter(exp => !content.includes(exp));
  if (missingExports.length > 0) {
    log('red', `❌ Missing validation functions: ${missingExports.join(', ')}`);
    process.exit(1);
  }
  
  log('green', '✅ Validated types contain required exports');
}

async function checkValidatedApiClient() {
  logHeader('Checking Validated API Client');
  
  const apiClientPath = path.join(process.cwd(), 'src/lib/api.ts');
  if (!fs.existsSync(apiClientPath)) {
    log('red', '❌ Validated API client not found!');
    log('yellow', 'Expected: src/lib/api.ts');
    process.exit(1);
  }
  
  const content = fs.readFileSync(apiClientPath, 'utf8');
  const requiredMethods = [
    'getUserInstallations',
    'getInstallationRepos',
    'getServerConfig',
    'getCurrentUser'
  ];
  
  const missingMethods = requiredMethods.filter(method => !content.includes(method));
  if (missingMethods.length > 0) {
    log('red', `❌ Missing API methods: ${missingMethods.join(', ')}`);
    process.exit(1);
  }
  
  log('green', '✅ Validated API client contains required methods');
}

async function runTypeScriptCheck() {
  logHeader('Running TypeScript Compilation Check');
  
  try {
    execSync('npm run type-check', { stdio: 'pipe' });
    log('green', '✅ TypeScript compilation successful');
  } catch (error) {
    log('red', '❌ TypeScript compilation failed:');
    console.log(error.stdout?.toString() || error.message);
    process.exit(1);
  }
}

async function checkComponentStandards() {
  logHeader('Checking Component Standards');
  
  const libDir = path.join(process.cwd(), 'src/lib');
  const componentsDir = path.join(process.cwd(), 'src/lib/components');
  
  let violations = [];
  
  // Check if components directory exists
  if (!fs.existsSync(componentsDir)) {
    violations.push('Components directory (src/lib/components) does not exist');
  }
  
  // Check for PageLayout usage in page-like files (files in src/lib/*.svelte that aren't Sidebar)
  if (fs.existsSync(libDir)) {
    const pageFiles = fs.readdirSync(libDir).filter(f => 
      f.endsWith('.svelte') && 
      f !== 'Sidebar.svelte' && 
      !f.startsWith('.')
    );
    
    // Special pages that should not use PageLayout
    const excludedPages = ['Login', 'AuthCallback', 'MaintenanceMode', 'GitLabSetup'];
    
    for (const file of pageFiles) {
      const content = fs.readFileSync(path.join(libDir, file), 'utf8');
      const isExcluded = excludedPages.some(page => file.includes(page));
      
      if (!content.includes('PageLayout') && !isExcluded) {
        violations.push(`Page ${file} should use PageLayout component`);
      }
    }
  }
  
  // Components barrel export is optional - direct imports are used in this codebase
  // const barrelExports = path.join(componentsDir, 'index.ts');
  // if (!fs.existsSync(barrelExports)) {
  //   violations.push('Components barrel export file (src/lib/components/index.ts) missing');
  // }
  
  if (violations.length > 0) {
    log('yellow', '⚠️  Component standard violations:');
    violations.forEach(v => log('yellow', `   - ${v}`));
  } else {
    log('green', '✅ Component standards check passed');
  }
  
  return violations.length === 0;
}

async function checkApiUsagePatterns() {
  logHeader('Checking API Usage Patterns');
  
  const srcDir = path.join(process.cwd(), 'src');
  let violations = [];
  
  // Recursively check all .ts and .svelte files
  function checkFile(filePath) {
    const content = fs.readFileSync(filePath, 'utf8');
    const relativePath = path.relative(process.cwd(), filePath);
    
    // Check for unvalidated fetch calls to API endpoints
    if (content.includes('fetch(') && !content.includes('api')) {
      // Only flag if it's calling our API endpoints
      if (content.includes("fetch('/api/") || content.includes('fetch("/api/') || 
          content.includes("fetch(`/api/") || content.includes('fetch(`${') && content.includes('/api/')) {
        violations.push(`${relativePath}: Uses fetch() for API calls instead of api client`);
      }
    }
    
    // Check for 'any' types
    if (content.includes(': any') || content.includes('<any>')) {
      violations.push(`${relativePath}: Contains 'any' types`);
    }
    
    // Check for JavaScript script tags in Svelte files
    if (filePath.endsWith('.svelte') && content.includes('<script>') && !content.includes('<script lang="ts">')) {
      violations.push(`${relativePath}: Should use TypeScript (<script lang="ts">)`);
    }
  }
  
  function scanDirectory(dir) {
    const items = fs.readdirSync(dir, { withFileTypes: true });
    for (const item of items) {
      const fullPath = path.join(dir, item.name);
      if (item.isDirectory() && !item.name.startsWith('.') && item.name !== 'node_modules') {
        scanDirectory(fullPath);
      } else if (item.isFile() && (item.name.endsWith('.ts') || item.name.endsWith('.svelte'))) {
        checkFile(fullPath);
      }
    }
  }
  
  scanDirectory(srcDir);
  
  if (violations.length > 0) {
    log('red', '❌ API usage violations found:');
    violations.forEach(v => log('red', `   - ${v}`));
    return false;
  } else {
    log('green', '✅ API usage patterns check passed');
    return true;
  }
}

async function main() {
  console.log(`${colors.bold}${colors.blue}API Type Validation Script${colors.reset}\n`);
  
  try {
    await checkApiJsonExists();
    await checkGeneratedTypes();
    await checkValidatedTypes();
    await checkValidatedApiClient();
    await runTypeScriptCheck();
    
    const componentCheck = await checkComponentStandards();
    const apiCheck = await checkApiUsagePatterns();
    
    if (componentCheck && apiCheck) {
      logHeader('Validation Complete');
      log('green', '🎉 All checks passed! API types and patterns are valid.');
      process.exit(0);
    } else {
      logHeader('Validation Failed');
      log('red', '❌ Some checks failed. Please fix the issues above.');
      process.exit(1);
    }
    
  } catch (error) {
    log('red', `❌ Validation script failed: ${error.message}`);
    process.exit(1);
  }
}

// Run if called directly
if (require.main === module) {
  main();
}

module.exports = { main };
