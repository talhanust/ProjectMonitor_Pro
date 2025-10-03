import ExcelJS from 'exceljs';
import * as fs from 'fs';
import * as path from 'path';

async function analyzeMMRStructure(filePath: string) {
  console.log(`\n📊 Analyzing: ${path.basename(filePath)}`);
  console.log('='.repeat(50));
  
  const workbook = new ExcelJS.Workbook();
  
  try {
    await workbook.xlsx.readFile(filePath);
    
    console.log(`📋 Sheets found: ${workbook.worksheets.length}`);
    
    workbook.worksheets.forEach((worksheet, index) => {
      console.log(`\n📄 Sheet ${index + 1}: "${worksheet.name}"`);
      console.log(`   Rows: ${worksheet.rowCount}, Columns: ${worksheet.columnCount}`);
      
      // Analyze first 10 rows to understand structure
      console.log('   First few cells:');
      for (let row = 1; row <= Math.min(10, worksheet.rowCount); row++) {
        const rowData: string[] = [];
        for (let col = 1; col <= Math.min(5, worksheet.columnCount); col++) {
          const cell = worksheet.getCell(row, col);
          if (cell.value) {
            rowData.push(`${cell.address}: ${String(cell.value).substring(0, 20)}`);
          }
        }
        if (rowData.length > 0) {
          console.log(`   Row ${row}: ${rowData.join(' | ')}`);
        }
      }
      
      // Look for key patterns
      const patterns = [
        'project', 'month', 'budget', 'expenditure', 'progress',
        'annexure', 'summary', 'manpower', 'equipment', 'material'
      ];
      
      console.log('\n   Key patterns found:');
      patterns.forEach(pattern => {
        let found = false;
        worksheet.eachRow((row, rowNumber) => {
          row.eachCell((cell, colNumber) => {
            if (!found && cell.value && String(cell.value).toLowerCase().includes(pattern)) {
              console.log(`   ✓ "${pattern}" found at ${cell.address}`);
              found = true;
            }
          });
        });
      });
    });
    
  } catch (error) {
    console.error(`Error analyzing file: ${error}`);
  }
}

// Analyze all MMR files
async function analyzeAll() {
  const mmrFiles = [
    '/workspaces/ProjectMonitor_Pro/PRJ006 MMR July 25  10th Avenue.xlsx',
    '/workspaces/ProjectMonitor_Pro/MMR ADA Nullah PkgI Jul 2025 Final.xlsx',
    '/workspaces/ProjectMonitor_Pro/01. MMR BCP July 2025 Final.xlsx'
  ];
  
  for (const file of mmrFiles) {
    if (fs.existsSync(file)) {
      await analyzeMMRStructure(file);
    } else {
      console.log(`File not found: ${file}`);
    }
  }
}

analyzeAll().catch(console.error);
