import ExcelJS from 'exceljs';
import { AnnexureHandlers } from './annexureHandlers';
import { MMRData, ParseResult, ParseError, ParseWarning } from '../models/mmr.model';
import { PARSER_CONFIG } from '../config/parserConfig';
import { ParserOptions } from '../models/mmr.model';

export class ExcelProcessor {
  private workbook: ExcelJS.Workbook;
  private handlers: AnnexureHandlers;
  private errors: ParseError[] = [];
  private warnings: ParseWarning[] = [];
  private confidence = 100;
  
  constructor() {
    this.workbook = new ExcelJS.Workbook();
    this.handlers = new AnnexureHandlers();
  }
  
  async parseFile(
    filePath: string | Buffer,
    options: ParserOptions = {}
  ): Promise<ParseResult> {
    try {
      // Load workbook
      if (typeof filePath === 'string') {
        await this.workbook.xlsx.readFile(filePath);
      } else {
        await this.workbook.xlsx.load(filePath);
      }
      
      // Identify and parse annexures
      const mmrData = await this.extractMMRData(options);
      
      // Calculate confidence score
      this.calculateConfidence();
      
      return {
        success: this.errors.filter(e => e.severity === 'critical').length === 0,
        data: mmrData,
        errors: this.errors,
        warnings: this.warnings,
        confidence: this.confidence
      };
    } catch (error: any) {
      this.errors.push({
        annexure: 'General',
        message: `Failed to parse file: ${error.message}`,
        severity: 'critical'
      });
      
      return {
        success: false,
        errors: this.errors,
        warnings: this.warnings,
        confidence: 0
      };
    }
  }
  
  private async extractMMRData(options: ParserOptions): Promise<MMRData | undefined> {
    const annexures: any = {};
    let summaryData: any = null;
    
    // Process each worksheet
    this.workbook.worksheets.forEach(worksheet => {
      const sheetName = worksheet.name.toLowerCase();
      
      // Identify annexure type
      if (this.matchesPattern(sheetName, PARSER_CONFIG.annexureIdentifiers.summary)) {
        const summary = this.handlers.parseSummary(worksheet);
        if (summary) {
          annexures.summary = summary;
          summaryData = this.extractSummaryMetrics(worksheet);
        }
      } else if (this.matchesPattern(sheetName, PARSER_CONFIG.annexureIdentifiers.annexureA)) {
        annexures.annexureA = this.handlers.parseAnnexureA(worksheet);
      } else if (this.matchesPattern(sheetName, PARSER_CONFIG.annexureIdentifiers.annexureB)) {
        annexures.annexureB = this.handlers.parseAnnexureB(worksheet);
      } else if (this.matchesPattern(sheetName, PARSER_CONFIG.annexureIdentifiers.annexureC)) {
        annexures.annexureC = this.handlers.parseAnnexureC(worksheet);
      }
      // Add more annexure types as needed
    });
    
    // Collect errors and warnings from handlers
    this.errors.push(...this.handlers.getErrors());
    this.warnings.push(...this.handlers.getWarnings());
    
    if (Object.keys(annexures).length === 0) {
      this.errors.push({
        annexure: 'General',
        message: 'No valid annexures found in the file',
        severity: 'critical'
      });
      return undefined;
    }
    
    return {
      projectId: annexures.summary?.projectCode || 'UNKNOWN',
      month: this.extractMonth(annexures.summary?.reportingPeriod),
      year: this.extractYear(annexures.summary?.reportingPeriod),
      reportDate: new Date(),
      
      summary: summaryData || {
        totalBudget: 0,
        actualExpenditure: 0,
        physicalProgress: 0,
        financialProgress: 0,
        variance: 0
      },
      
      annexures,
      
      metadata: {
        fileName: '',
        uploadedAt: new Date(),
        parsedAt: new Date(),
        parseConfidence: this.confidence,
        errors: this.errors,
        warnings: this.warnings
      }
    };
  }
  
  private extractSummaryMetrics(worksheet: ExcelJS.Worksheet): any {
    // Extract key metrics from summary sheet
    // This is a simplified version - expand based on actual MMR format
    return {
      totalBudget: 0,
      actualExpenditure: 0,
      physicalProgress: 0,
      financialProgress: 0,
      variance: 0
    };
  }
  
  private matchesPattern(text: string, pattern: RegExp): boolean {
    return pattern.test(text);
  }
  
  private extractMonth(period: string): string {
    const months = ['January', 'February', 'March', 'April', 'May', 'June',
                   'July', 'August', 'September', 'October', 'November', 'December'];
    
    for (const month of months) {
      if (period && period.toLowerCase().includes(month.toLowerCase())) {
        return month;
      }
    }
    
    return 'Unknown';
  }
  
  private extractYear(period: string): number {
    const yearMatch = period ? period.match(/20\d{2}/) : null;
    if (yearMatch) {
      return parseInt(yearMatch[0]);
    }
    return new Date().getFullYear();
  }
  
  private calculateConfidence(): void {
    let totalWeight = 0;
    let weightedScore = 0;
    
    // Check header matches
    const headerMatchScore = this.workbook.worksheets.length > 0 ? 0.8 : 0;
    weightedScore += headerMatchScore * PARSER_CONFIG.confidenceWeights.headerMatch;
    totalWeight += PARSER_CONFIG.confidenceWeights.headerMatch;
    
    // Check data completeness
    const criticalErrors = this.errors.filter(e => e.severity === 'critical').length;
    const dataCompleteScore = Math.max(0, 1 - (criticalErrors * 0.2));
    weightedScore += dataCompleteScore * PARSER_CONFIG.confidenceWeights.dataComplete;
    totalWeight += PARSER_CONFIG.confidenceWeights.dataComplete;
    
    // Check validation pass rate
    const totalValidations = this.errors.length + this.warnings.length;
    const validationScore = totalValidations > 0 ? 
      Math.max(0, 1 - (this.errors.length / totalValidations)) : 1;
    weightedScore += validationScore * PARSER_CONFIG.confidenceWeights.validationPass;
    totalWeight += PARSER_CONFIG.confidenceWeights.validationPass;
    
    this.confidence = Math.round((weightedScore / totalWeight) * 100);
  }
}
