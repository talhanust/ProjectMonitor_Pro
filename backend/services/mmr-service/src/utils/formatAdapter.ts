import { Worksheet, Cell } from 'exceljs';
import { PARSER_CONFIG } from '../config/parserConfig';

export class FormatAdapter {
  private worksheet: Worksheet;

  constructor(worksheet: Worksheet) {
    this.worksheet = worksheet;
  }

  /**
   * Find a cell containing specific pattern with tolerance for position variations
   */
  findCell(
    pattern: RegExp | string,
    searchArea?: {
      startRow?: number;
      endRow?: number;
      startCol?: number;
      endCol?: number;
    },
  ): Cell | null {
    const area = {
      startRow: searchArea?.startRow || 1,
      endRow: searchArea?.endRow || Math.min(50, this.worksheet.rowCount),
      startCol: searchArea?.startCol || 1,
      endCol: searchArea?.endCol || Math.min(20, this.worksheet.columnCount),
    };

    for (let row = area.startRow; row <= area.endRow; row++) {
      for (let col = area.startCol; col <= area.endCol; col++) {
        const cell = this.worksheet.getCell(row, col);
        if (this.matchesPattern(cell.value, pattern)) {
          return cell;
        }
      }
    }

    return null;
  }

  /**
   * Find value cell relative to a label cell
   */
  findRelativeValue(labelCell: Cell, direction: 'right' | 'below' | 'auto' = 'auto'): any {
    if (!labelCell) return null;

    const row = labelCell.row;
    const col = typeof labelCell.col === 'number' ? labelCell.col : 1;

    if (direction === 'right' || direction === 'auto') {
      // Check cells to the right
      for (let offset = 1; offset <= PARSER_CONFIG.variations.maxColOffset; offset++) {
        const cell = this.worksheet.getCell(row, col + offset);
        if (this.hasValue(cell)) {
          return cell.value;
        }
      }
    }

    if (direction === 'below' || direction === 'auto') {
      // Check cells below
      for (let offset = 1; offset <= PARSER_CONFIG.variations.maxRowOffset; offset++) {
        const cell = this.worksheet.getCell(row + offset, col);
        if (this.hasValue(cell)) {
          return cell.value;
        }
      }
    }

    return null;
  }

  /**
   * Extract table data starting from a header row
   */
  extractTable(headerRow: number, headerPatterns: string[]): any[] {
    const headers: { [key: string]: number } = {};
    const data: any[] = [];

    // Identify column positions by headers
    for (let col = 1; col <= this.worksheet.columnCount; col++) {
      const cell = this.worksheet.getCell(headerRow, col);
      const headerText = this.normalizeText(cell.value);

      for (const pattern of headerPatterns) {
        if (this.matchesPattern(headerText, pattern)) {
          headers[pattern] = col;
        }
      }
    }

    // Extract data rows
    for (let row = headerRow + 1; row <= this.worksheet.rowCount; row++) {
      const firstCell = this.worksheet.getCell(row, 1);

      // Stop if we hit an empty row or another section
      if (!this.hasValue(firstCell)) break;

      const rowData: any = {};
      for (const [key, col] of Object.entries(headers)) {
        rowData[key] = this.worksheet.getCell(row, col).value;
      }

      data.push(rowData);
    }

    return data;
  }

  private matchesPattern(value: any, pattern: RegExp | string): boolean {
    if (!value) return false;

    const text = this.normalizeText(value);

    if (pattern instanceof RegExp) {
      return pattern.test(text);
    } else {
      return text.includes(pattern.toLowerCase());
    }
  }

  private normalizeText(value: any): string {
    if (!value) return '';
    return String(value).toLowerCase().trim().replace(/\s+/g, ' ');
  }

  private hasValue(cell: Cell): boolean {
    return cell && cell.value !== null && cell.value !== undefined && cell.value !== '';
  }

  /**
   * Calculate similarity between two strings
   */
  calculateSimilarity(str1: string, str2: string): number {
    const s1 = this.normalizeText(str1);
    const s2 = this.normalizeText(str2);

    if (s1 === s2) return 1;

    const longer = s1.length > s2.length ? s1 : s2;
    const shorter = s1.length > s2.length ? s2 : s1;

    if (longer.length === 0) return 0;

    const editDistance = this.levenshteinDistance(longer, shorter);
    return (longer.length - editDistance) / longer.length;
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
