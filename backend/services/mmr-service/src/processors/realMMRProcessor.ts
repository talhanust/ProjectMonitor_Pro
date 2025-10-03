import ExcelJS from 'exceljs';
import { MMRData, ParseResult } from '../models/mmr.model';

export class RealMMRProcessor {
  private workbook: ExcelJS.Workbook;
  
  constructor() {
    this.workbook = new ExcelJS.Workbook();
  }
  
  async parseFile(filePath: string | Buffer): Promise<ParseResult> {
    try {
      if (typeof filePath === 'string') {
        await this.workbook.xlsx.readFile(filePath);
      } else {
        await this.workbook.xlsx.load(filePath);
      }
      
      // Extract project info from filename if available
      const fileName = typeof filePath === 'string' ? filePath : 'unknown';
      const projectInfo = this.extractProjectFromFileName(fileName);
      
      // Parse based on common MMR structures
      const data = await this.extractData(projectInfo);
      
      return {
        success: true,
        data,
        errors: [],
        warnings: [],
        confidence: this.calculateConfidence(data)
      };
    } catch (error: any) {
      return {
        success: false,
        errors: [{
          annexure: 'General',
          message: error.message,
          severity: 'critical'
        }],
        warnings: [],
        confidence: 0
      };
    }
  }
  
  private extractProjectFromFileName(fileName: string): any {
    const baseName = fileName.split('/').pop() || fileName;
    
    // Extract project code (PRJ006, ADA Nullah, BCP, etc.)
    let projectCode = 'UNKNOWN';
    if (baseName.includes('PRJ')) {
      projectCode = baseName.match(/PRJ\d+/)?.[0] || 'UNKNOWN';
    } else if (baseName.includes('ADA')) {
      projectCode = 'ADA-NULLAH';
    } else if (baseName.includes('BCP')) {
      projectCode = 'BCP';
    }
    
    // Extract month and year
    const monthMatch = baseName.match(/(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)/i);
    const yearMatch = baseName.match(/20\d{2}/);
    
    return {
      projectCode,
      month: monthMatch?.[0] || 'Unknown',
      year: yearMatch ? parseInt(yearMatch[0]) : new Date().getFullYear()
    };
  }
  
  private async extractData(projectInfo: any): Promise<MMRData> {
    const data: any = {
      projectId: projectInfo.projectCode,
      month: projectInfo.month,
      year: projectInfo.year,
      reportDate: new Date(),
      summary: {},
      annexures: {},
      metadata: {
        fileName: '',
        uploadedAt: new Date(),
        parsedAt: new Date(),
        parseConfidence: 0,
        errors: [],
        warnings: []
      }
    };
    
    // Process each worksheet
    this.workbook.worksheets.forEach(worksheet => {
      const sheetName = worksheet.name.toLowerCase();
      
      // Identify sheet type and extract data
      if (sheetName.includes('summary') || sheetName.includes('executive')) {
        data.summary = this.extractSummaryData(worksheet);
      } else if (sheetName.includes('manpower') || sheetName.includes('labour')) {
        data.annexures.manpower = this.extractManpowerData(worksheet);
      } else if (sheetName.includes('equipment') || sheetName.includes('machinery')) {
        data.annexures.equipment = this.extractEquipmentData(worksheet);
      } else if (sheetName.includes('material')) {
        data.annexures.materials = this.extractMaterialData(worksheet);
      } else if (sheetName.includes('progress')) {
        data.annexures.progress = this.extractProgressData(worksheet);
      }
      // Add more sheet type handlers as needed
    });
    
    return data as MMRData;
  }
  
  private extractSummaryData(worksheet: ExcelJS.Worksheet): any {
    const summary: any = {
      totalBudget: 0,
      actualExpenditure: 0,
      physicalProgress: 0,
      financialProgress: 0,
      variance: 0
    };
    
    // Search for key metrics in common locations
    worksheet.eachRow((row, rowNumber) => {
      row.eachCell((cell, colNumber) => {
        const cellValue = String(cell.value || '').toLowerCase();
        
        if (cellValue.includes('total budget') || cellValue.includes('contract value')) {
          const valueCell = worksheet.getCell(rowNumber, colNumber + 1);
          summary.totalBudget = this.parseNumber(valueCell.value);
        }
        
        if (cellValue.includes('expenditure') || cellValue.includes('actual cost')) {
          const valueCell = worksheet.getCell(rowNumber, colNumber + 1);
          summary.actualExpenditure = this.parseNumber(valueCell.value);
        }
        
        if (cellValue.includes('physical') && cellValue.includes('progress')) {
          const valueCell = worksheet.getCell(rowNumber, colNumber + 1);
          summary.physicalProgress = this.parsePercentage(valueCell.value);
        }
        
        if (cellValue.includes('financial') && cellValue.includes('progress')) {
          const valueCell = worksheet.getCell(rowNumber, colNumber + 1);
          summary.financialProgress = this.parsePercentage(valueCell.value);
        }
      });
    });
    
    summary.variance = summary.actualExpenditure - summary.totalBudget;
    
    return summary;
  }
  
  private extractManpowerData(worksheet: ExcelJS.Worksheet): any {
    const manpower: any[] = [];
    let headerRow = 0;
    
    // Find header row
    worksheet.eachRow((row, rowNumber) => {
      if (headerRow === 0) {
        let hasHeaders = false;
        row.eachCell(cell => {
          const value = String(cell.value || '').toLowerCase();
          if (value.includes('category') || value.includes('designation') || 
              value.includes('planned') || value.includes('actual')) {
            hasHeaders = true;
          }
        });
        if (hasHeaders) headerRow = rowNumber;
      }
    });
    
    // Extract data rows
    if (headerRow > 0) {
      for (let i = headerRow + 1; i <= worksheet.rowCount; i++) {
        const row = worksheet.getRow(i);
        const category = row.getCell(1).value;
        
        if (category && String(category).trim() !== '') {
          manpower.push({
            category: String(category),
            planned: this.parseNumber(row.getCell(2).value),
            actual: this.parseNumber(row.getCell(3).value),
            variance: this.parseNumber(row.getCell(4).value) || 0
          });
        }
      }
    }
    
    return manpower;
  }
  
  private extractEquipmentData(worksheet: ExcelJS.Worksheet): any {
    // Similar pattern to manpower extraction
    return [];
  }
  
  private extractMaterialData(worksheet: ExcelJS.Worksheet): any {
    // Similar pattern to manpower extraction
    return [];
  }
  
  private extractProgressData(worksheet: ExcelJS.Worksheet): any {
    // Extract progress data
    return {};
  }
  
  private parseNumber(value: any): number {
    if (!value) return 0;
    const cleaned = String(value).replace(/[^\d.-]/g, '');
    return parseFloat(cleaned) || 0;
  }
  
  private parsePercentage(value: any): number {
    const num = this.parseNumber(value);
    return num > 1 ? num : num * 100;
  }
  
  private calculateConfidence(data: any): number {
    let score = 0;
    let checks = 0;
    
    // Check if key data exists
    if (data.projectId !== 'UNKNOWN') { score += 20; }
    checks += 20;
    
    if (data.summary?.totalBudget > 0) { score += 20; }
    checks += 20;
    
    if (data.summary?.physicalProgress > 0) { score += 20; }
    checks += 20;
    
    if (Object.keys(data.annexures || {}).length > 0) { score += 20; }
    checks += 20;
    
    if (data.month !== 'Unknown') { score += 20; }
    checks += 20;
    
    return Math.round((score / checks) * 100);
  }
}
