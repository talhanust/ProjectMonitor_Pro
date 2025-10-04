import { Worksheet } from 'exceljs';
import { FormatAdapter } from '../utils/formatAdapter';
import {
  AnnexureSummary,
  AnnexureA,
  AnnexureB,
  AnnexureC,
  ParseError,
  ParseWarning,
} from '../models/mmr.model';
import { PARSER_CONFIG } from '../config/parserConfig';

export class AnnexureHandlers {
  private errors: ParseError[] = [];
  private warnings: ParseWarning[] = [];

  parseSummary(worksheet: Worksheet): AnnexureSummary | null {
    try {
      const adapter = new FormatAdapter(worksheet);

      // Find key fields
      const projectNameCell = adapter.findCell(PARSER_CONFIG.cellPatterns.projectName);
      const projectCodeCell = adapter.findCell(PARSER_CONFIG.cellPatterns.projectCode);
      const reportPeriodCell = adapter.findCell(PARSER_CONFIG.cellPatterns.reportPeriod);

      if (!projectNameCell) {
        this.errors.push({
          annexure: 'Summary',
          message: 'Project name not found',
          severity: 'error',
        });
        return null;
      }

      return {
        projectName: adapter.findRelativeValue(projectNameCell) || '',
        projectCode: adapter.findRelativeValue(projectCodeCell) || '',
        reportingPeriod: adapter.findRelativeValue(reportPeriodCell) || '',
        preparedBy: '',
        checkedBy: '',
        approvedBy: '',
      };
    } catch (error: any) {
      this.errors.push({
        annexure: 'Summary',
        message: `Parse error: ${error.message}`,
        severity: 'critical',
      });
      return null;
    }
  }

  parseAnnexureA(worksheet: Worksheet): AnnexureA | null {
    try {
      const adapter = new FormatAdapter(worksheet);

      // Extract project details
      const nameCell = adapter.findCell(/project\s*name/i);
      const locationCell = adapter.findCell(/location/i);
      const clientCell = adapter.findCell(/client|employer/i);
      const contractValueCell = adapter.findCell(/contract.*value|value.*contract/i);
      const startDateCell = adapter.findCell(/start.*date|commencement/i);
      const endDateCell = adapter.findCell(/end.*date|completion.*date/i);

      // Find milestones table
      const milestonesHeader = adapter.findCell(/milestones|key.*dates/i);
      let milestones: any[] = [];

      if (milestonesHeader) {
        milestones = adapter.extractTable(milestonesHeader.row, [
          'description',
          'planned',
          'actual',
          'status',
        ]);
      }

      return {
        projectDetails: {
          name: adapter.findRelativeValue(nameCell!) || '',
          location: adapter.findRelativeValue(locationCell!) || '',
          client: adapter.findRelativeValue(clientCell!) || '',
          contractValue: this.parseNumber(adapter.findRelativeValue(contractValueCell!)),
          startDate: this.parseDate(adapter.findRelativeValue(startDateCell!)),
          endDate: this.parseDate(adapter.findRelativeValue(endDateCell!)),
        },
        milestones: milestones.map((m, index) => ({
          id: `M${index + 1}`,
          description: m.description || '',
          plannedDate: this.parseDate(m.planned),
          actualDate: m.actual ? this.parseDate(m.actual) : undefined,
          status: this.parseStatus(m.status),
          remarks: m.remarks,
        })),
      };
    } catch (error: any) {
      this.errors.push({
        annexure: 'Annexure A',
        message: `Parse error: ${error.message}`,
        severity: 'critical',
      });
      return null;
    }
  }

  parseAnnexureB(worksheet: Worksheet): AnnexureB | null {
    try {
      const adapter = new FormatAdapter(worksheet);

      // Find physical progress table
      const headerCell = adapter.findCell(/physical.*progress|activity|work.*item/i);

      if (!headerCell) {
        this.warnings.push({
          annexure: 'Annexure B',
          message: 'Physical progress table not found',
          suggestion: 'Check if the annexure contains physical progress data',
        });
        return null;
      }

      const activities = adapter.extractTable(headerCell.row, [
        'description',
        'unit',
        'planned',
        'actual',
        'progress',
      ]);

      return {
        activities: activities.map((a, index) => ({
          id: `A${index + 1}`,
          description: a.description || '',
          unit: a.unit || '',
          plannedQty: this.parseNumber(a.planned),
          actualQty: this.parseNumber(a.actual),
          progress: this.parsePercentage(a.progress),
          variance: this.calculateVariance(a.actual, a.planned),
        })),
      };
    } catch (error: any) {
      this.errors.push({
        annexure: 'Annexure B',
        message: `Parse error: ${error.message}`,
        severity: 'error',
      });
      return null;
    }
  }

  parseAnnexureC(worksheet: Worksheet): AnnexureC | null {
    try {
      const adapter = new FormatAdapter(worksheet);

      // Find financial progress table
      const headerCell = adapter.findCell(/financial.*progress|budget|expenditure/i);

      if (!headerCell) {
        this.warnings.push({
          annexure: 'Annexure C',
          message: 'Financial progress table not found',
          suggestion: 'Check if the annexure contains financial data',
        });
        return null;
      }

      const items = adapter.extractTable(headerCell.row, [
        'category',
        'budgeted',
        'actual',
        'committed',
        'variance',
      ]);

      return {
        budgetItems: items.map((item) => ({
          category: item.category || '',
          budgeted: this.parseNumber(item.budgeted),
          actual: this.parseNumber(item.actual),
          committed: this.parseNumber(item.committed) || 0,
          variance:
            this.parseNumber(item.variance) || this.calculateVariance(item.actual, item.budgeted),
          variancePercent: this.calculateVariancePercent(item.actual, item.budgeted),
        })),
      };
    } catch (error: any) {
      this.errors.push({
        annexure: 'Annexure C',
        message: `Parse error: ${error.message}`,
        severity: 'error',
      });
      return null;
    }
  }

  // Helper methods
  private parseNumber(value: any): number {
    if (!value) return 0;
    const cleaned = String(value).replace(/[^\d.-]/g, '');
    return parseFloat(cleaned) || 0;
  }

  private parsePercentage(value: any): number {
    if (!value) return 0;
    const num = this.parseNumber(value);
    return num > 1 ? num : num * 100;
  }

  private parseDate(value: any): Date {
    if (!value) return new Date();

    // Try different date formats
    const date = new Date(value);
    if (!isNaN(date.getTime())) return date;

    // Handle Excel date serial number
    if (typeof value === 'number') {
      return new Date((value - 25569) * 86400 * 1000);
    }

    return new Date();
  }

  private parseStatus(value: any): 'Completed' | 'In Progress' | 'Pending' | 'Delayed' {
    const status = String(value).toLowerCase();
    if (status.includes('complete')) return 'Completed';
    if (status.includes('progress')) return 'In Progress';
    if (status.includes('delay')) return 'Delayed';
    return 'Pending';
  }

  private calculateVariance(actual: any, planned: any): number {
    const a = this.parseNumber(actual);
    const p = this.parseNumber(planned);
    return a - p;
  }

  private calculateVariancePercent(actual: any, planned: any): number {
    const a = this.parseNumber(actual);
    const p = this.parseNumber(planned);
    if (p === 0) return 0;
    return ((a - p) / p) * 100;
  }

  getErrors(): ParseError[] {
    return this.errors;
  }

  getWarnings(): ParseWarning[] {
    return this.warnings;
  }
}
