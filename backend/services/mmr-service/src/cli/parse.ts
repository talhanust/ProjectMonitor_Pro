import { ExcelProcessor } from '../processors/excelProcessor';
import { MMRValidator } from '../validators/mmrValidator';
import * as fs from 'fs';
import * as path from 'path';

async function parseMMRFile(filePath: string) {
  console.log(`\nParsing MMR file: ${filePath}\n`);
  
  const processor = new ExcelProcessor();
  const validator = new MMRValidator();
  
  // Parse the file
  const result = await processor.parseFile(filePath);
  
  if (result.success && result.data) {
    console.log('✅ File parsed successfully');
    console.log(`📊 Confidence: ${result.confidence}%\n`);
    
    // Display summary
    console.log('📋 Summary:');
    console.log(`  Project: ${result.data.annexures.summary?.projectName || 'Unknown'}`);
    console.log(`  Period: ${result.data.month} ${result.data.year}`);
    console.log(`  Physical Progress: ${result.data.summary.physicalProgress}%`);
    console.log(`  Financial Progress: ${result.data.summary.financialProgress}%\n`);
    
    // Validate
    const validation = validator.validate(result.data);
    
    if (validation.valid) {
      console.log('✅ Validation passed');
    } else {
      console.log('⚠️ Validation issues found');
    }
    
    // Display errors
    if (result.errors.length > 0) {
      console.log('\n❌ Errors:');
      result.errors.forEach(error => {
        console.log(`  - [${error.annexure}] ${error.message}`);
      });
    }
    
    // Display warnings
    if (result.warnings.length > 0) {
      console.log('\n⚠️ Warnings:');
      result.warnings.forEach(warning => {
        console.log(`  - [${warning.annexure}] ${warning.message}`);
        if (warning.suggestion) {
          console.log(`    💡 ${warning.suggestion}`);
        }
      });
    }
    
    // Save parsed data
    const outputPath = filePath.replace('.xlsx', '_parsed.json');
    fs.writeFileSync(outputPath, JSON.stringify(result.data, null, 2));
    console.log(`\n💾 Parsed data saved to: ${outputPath}`);
    
  } else {
    console.log('❌ Failed to parse file');
    
    result.errors.forEach(error => {
      console.log(`  - [${error.annexure}] ${error.message}`);
    });
  }
}

// Main execution
const filePath = process.argv[2];

if (!filePath) {
  console.log('Usage: npm run parse:test <path-to-excel-file>');
  console.log('Example: npm run parse:test tests/fixtures/sample-mmr.xlsx');
  process.exit(1);
}

if (!fs.existsSync(filePath)) {
  console.log(`Error: File not found - ${filePath}`);
  process.exit(1);
}

parseMMRFile(filePath).catch(console.error);
