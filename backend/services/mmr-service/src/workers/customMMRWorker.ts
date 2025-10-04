// backend/services/mmr-service/src/workers/customMMRWorker.ts
// Custom MMR Worker for Project-based MMR Files (Annexure format)

import { Job } from 'bull';
import * as XLSX from 'xlsx';
import { logger } from '../../../shared/logger';

interface SheetPattern {
  identifiers: string[];
  requiredFields: string[];
  tolerance?: number;
}

interface ExtractedMMRData {
  projectInfo: any;
  monthlyProgress: any;
  financialSummary: any;
  scheduleStatus: any;
  annexures: any[];
  rawSheets: any[];
}

class CustomMMRWorker {
  private readonly sheetPatterns = {
    summary: {
      identifiers: ['summary', 'executive summary', 'project summary', 'mcrp'],
      requiredFields: ['project name', 'month', 'progress', 'work done', 'expenditure'],
      tolerance: 0.15,
    },
    progress: {
      identifiers: ['anx b', 'anx-b', 'annexure b', 'progress', 'work done'],
      requiredFields: ['planned', 'achieved', 'vetted', 'running'],
    },
    financial: {
      identifiers: ['anx c', 'anx-c', 'financial', 'expenditure', 'cost'],
      requiredFields: ['direct cost', 'overhead', 'total', 'expenditure'],
    },
    schedule: {
      identifiers: ['anx a', 'anx-a', 'schedule', 'time'],
      requiredFields: ['planned', 'actual', 'delay', 'completion'],
    },
    materials: {
      identifiers: ['anx d', 'anx-d', 'steel', 'cement', 'material'],
      requiredFields: ['quantity', 'consumption', 'rate'],
    },
    manpower: {
      identifiers: ['anx e', 'anx-e', 'manpower', 'labor', 'staff'],
      requiredFields: ['skilled', 'unskilled', 'total'],
    },
    equipment: {
      identifiers: ['anx f', 'anx-f', 'equipment', 'machinery', 'plant'],
      requiredFields: ['equipment', 'hours', 'idle'],
    },
    safety: {
      identifiers: ['anx g', 'anx-g', 'safety', 'accident'],
      requiredFields: ['incidents', 'lost time', 'safety'],
    },
    quality: {
      identifiers: ['anx h', 'anx-h', 'quality', 'test'],
      requiredFields: ['tests', 'passed', 'failed'],
    },
  };

  async processProjectMMR(buffer: Buffer, job: Job): Promise<ExtractedMMRData> {
    await job.progress(10);

    const workbook = XLSX.read(buffer, {
      cellStyles: true,
      cellFormulas: true,
      cellDates: true,
    });

    await job.progress(20);

    const extractedData: ExtractedMMRData = {
      projectInfo: {},
      monthlyProgress: {},
      financialSummary: {},
      scheduleStatus: {},
      annexures: [],
      rawSheets: [],
    };

    // Process each sheet
    for (const sheetName of workbook.SheetNames) {
      const worksheet = workbook.Sheets[sheetName];
      const sheetData = this.extractSheetData(worksheet, sheetName);

      // Classify sheet type
      const sheetType = this.classifySheet(sheetName, sheetData);

      extractedData.rawSheets.push({
        name: sheetName,
        type: sheetType,
        data: sheetData.rows,
        headers: sheetData.headers,
        rowCount: sheetData.rows.length,
      });

      // Extract specific data based on sheet type
      if (sheetType === 'summary') {
        extractedData.projectInfo = this.extractProjectInfo(sheetData);
      } else if (sheetType === 'progress') {
        extractedData.monthlyProgress = this.extractProgressData(sheetData);
      } else if (sheetType === 'financial') {
        extractedData.financialSummary = this.extractFinancialData(sheetData);
      } else if (sheetType === 'schedule') {
        extractedData.scheduleStatus = this.extractScheduleData(sheetData);
      }

      // Add to annexures list
      extractedData.annexures.push({
        name: sheetName,
        type: sheetType,
        summary: this.createAnnexureSummary(sheetData),
      });
    }

    await job.progress(80);
    return extractedData;
  }

  private extractSheetData(worksheet: XLSX.WorkSheet, sheetName: string): any {
    const jsonData = XLSX.utils.sheet_to_json(worksheet, {
      header: 1,
      defval: '',
      blankrows: false,
      raw: false, // Get formatted values
    });

    if (jsonData.length === 0) {
      return { headers: [], rows: [], sheetName };
    }

    // Find header row (usually first non-empty row)
    let headerRow = 0;
    for (let i = 0; i < Math.min(10, jsonData.length); i++) {
      const row = jsonData[i] as any[];
      const nonEmptyCells = row.filter((cell) => cell && String(cell).trim()).length;
      if (nonEmptyCells >= 2) {
        headerRow = i;
        break;
      }
    }

    const headers = (jsonData[headerRow] as any[]).map((h) => String(h).trim());
    const dataRows = jsonData.slice(headerRow + 1);

    const structuredData = dataRows.map((row: any) => {
      const record: any = {};
      headers.forEach((header, index) => {
        if (header) {
          record[header] = row[index] || '';
        }
      });
      return record;
    });

    return {
      sheetName,
      headers,
      rows: structuredData,
      rawData: jsonData,
    };
  }

  private classifySheet(sheetName: string, sheetData: any): string {
    const normalizedName = sheetName.toLowerCase().trim();

    // Check against patterns
    for (const [type, pattern] of Object.entries(this.sheetPatterns)) {
      if (pattern.identifiers.some((id) => normalizedName.includes(id))) {
        return type;
      }
    }

    // Check by content
    const headerText = sheetData.headers.join(' ').toLowerCase();

    if (headerText.includes('project') && headerText.includes('name')) {
      return 'summary';
    }
    if (headerText.includes('progress') || headerText.includes('completion')) {
      return 'progress';
    }
    if (headerText.includes('cost') || headerText.includes('expenditure')) {
      return 'financial';
    }

    return 'other';
  }

  private extractProjectInfo(sheetData: any): any {
    const projectInfo: any = {
      projectName: '',
      month: '',
      contractor: '',
      engineer: '',
      location: '',
    };

    // Search for project info in first few rows
    for (const row of sheetData.rows.slice(0, 20)) {
      const rowText = JSON.stringify(row).toLowerCase();

      if (rowText.includes('project') && !projectInfo.projectName) {
        projectInfo.projectName = this.findValueInRow(row, ['project', 'name']);
      }
      if (rowText.includes('month') && !projectInfo.month) {
        projectInfo.month = this.findValueInRow(row, ['month', 'period']);
      }
      if (rowText.includes('contractor') && !projectInfo.contractor) {
        projectInfo.contractor = this.findValueInRow(row, ['contractor']);
      }
      if (rowText.includes('engineer') && !projectInfo.engineer) {
        projectInfo.engineer = this.findValueInRow(row, ['engineer', 'consultant']);
      }
    }

    return projectInfo;
  }

  private extractProgressData(sheetData: any): any {
    return {
      plannedProgress: this.findNumericValue(sheetData.rows, ['planned', 'target']),
      actualProgress: this.findNumericValue(sheetData.rows, ['actual', 'achieved']),
      vettedWork: this.findNumericValue(sheetData.rows, ['vetted', 'approved']),
      runningTotal: this.findNumericValue(sheetData.rows, ['running', 'cumulative']),
    };
  }

  private extractFinancialData(sheetData: any): any {
    return {
      directCost: this.findNumericValue(sheetData.rows, ['direct cost', 'direct']),
      overhead: this.findNumericValue(sheetData.rows, ['overhead', 'indirect']),
      totalExpenditure: this.findNumericValue(sheetData.rows, ['total', 'expenditure']),
      receivables: this.findNumericValue(sheetData.rows, ['receivable', 'due']),
    };
  }

  private extractScheduleData(sheetData: any): any {
    return {
      plannedCompletion: this.findValueInRow(sheetData.rows[0], ['planned', 'schedule']),
      actualCompletion: this.findValueInRow(sheetData.rows[0], ['actual', 'current']),
      delay: this.findNumericValue(sheetData.rows, ['delay', 'behind']),
    };
  }

  private createAnnexureSummary(sheetData: any): any {
    const totalRows = sheetData.rows.length;
    const nonEmptyRows = sheetData.rows.filter((row: any) =>
      Object.values(row).some((val) => val && String(val).trim()),
    ).length;

    return {
      totalRows,
      dataRows: nonEmptyRows,
      columns: sheetData.headers.length,
      hasData: nonEmptyRows > 0,
    };
  }

  private findValueInRow(row: any, keywords: string[]): string {
    if (!row) return '';

    for (const [key, value] of Object.entries(row)) {
      const keyLower = String(key).toLowerCase();
      if (keywords.some((kw) => keyLower.includes(kw)) && value) {
        return String(value).trim();
      }
    }

    return '';
  }

  private findNumericValue(rows: any[], keywords: string[]): number | null {
    for (const row of rows) {
      for (const [key, value] of Object.entries(row)) {
        const keyLower = String(key).toLowerCase();
        if (keywords.some((kw) => keyLower.includes(kw))) {
          const numValue = this.parseNumericValue(value);
          if (numValue !== null) return numValue;
        }
      }
    }
    return null;
  }

  private parseNumericValue(value: any): number | null {
    if (typeof value === 'number') return value;
    if (!value) return null;

    const str = String(value).trim();
    // Remove currency symbols, commas, percentages
    const cleaned = str.replace(/[Rs.,\s%]/g, '');
    const num = parseFloat(cleaned);

    return isNaN(num) ? null : num;
  }

  // Fuzzy matching for flexible field detection
  private fuzzyMatch(text: string, pattern: string, threshold: number = 0.85): boolean {
    const t = text.toLowerCase().trim();
    const p = pattern.toLowerCase().trim();

    if (t.includes(p) || p.includes(t)) return true;

    // Simple Levenshtein distance check
    const distance = this.levenshteinDistance(t, p);
    const maxLength = Math.max(t.length, p.length);
    const similarity = 1 - distance / maxLength;

    return similarity >= threshold;
  }

  private levenshteinDistance(str1: string, str2: string): number {
    const matrix: number[][] = [];

    for (let i = 0; i <= str2.length; i++) {
      matrix[i] = [i];
    }

    for (let j = 0; j <= str1.length; j++) {
      matrix[0][j] = j;
    }

    for (let i = 1; i <= str2.length; i++) {
      for (let j = 1; j <= str1.length; j++) {
        if (str2.charAt(i - 1) === str1.charAt(j - 1)) {
          matrix[i][j] = matrix[i - 1][j - 1];
        } else {
          matrix[i][j] = Math.min(
            matrix[i - 1][j - 1] + 1,
            matrix[i][j - 1] + 1,
            matrix[i - 1][j] + 1,
          );
        }
      }
    }

    return matrix[str2.length][str1.length];
  }
}

export default new CustomMMRWorker();
