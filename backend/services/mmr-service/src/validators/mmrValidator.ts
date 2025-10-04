import { MMRData, ParseError, ParseWarning } from '../models/mmr.model';
import { PARSER_CONFIG } from '../config/parserConfig';
import Joi from 'joi';

export class MMRValidator {
  private errors: ParseError[] = [];
  private warnings: ParseWarning[] = [];

  // Joi schemas for validation
  private readonly summarySchema = Joi.object({
    totalBudget: Joi.number().positive().required(),
    actualExpenditure: Joi.number().min(0).required(),
    physicalProgress: Joi.number().min(0).max(100).required(),
    financialProgress: Joi.number().min(0).max(100).required(),
    variance: Joi.number().required(),
  });

  private readonly projectDetailsSchema = Joi.object({
    name: Joi.string().required(),
    location: Joi.string().required(),
    client: Joi.string().required(),
    contractValue: Joi.number().positive().required(),
    startDate: Joi.date().required(),
    endDate: Joi.date().greater(Joi.ref('startDate')).required(),
  });

  validate(data: MMRData): { valid: boolean; errors: ParseError[]; warnings: ParseWarning[] } {
    this.errors = [];
    this.warnings = [];

    // Validate summary data
    this.validateSummary(data.summary);

    // Validate annexures
    if (data.annexures.annexureA) {
      this.validateAnnexureA(data.annexures.annexureA);
    }

    if (data.annexures.annexureB) {
      this.validateAnnexureB(data.annexures.annexureB);
    }

    if (data.annexures.annexureC) {
      this.validateAnnexureC(data.annexures.annexureC);
    }

    // Cross-validation checks
    this.performCrossValidation(data);

    return {
      valid: this.errors.filter((e) => e.severity === 'critical').length === 0,
      errors: this.errors,
      warnings: this.warnings,
    };
  }

  private validateSummary(summary: any): void {
    const { error } = this.summarySchema.validate(summary);

    if (error) {
      error.details.forEach((detail) => {
        this.errors.push({
          annexure: 'Summary',
          message: detail.message,
          severity: 'error',
        });
      });
    }

    // Additional business rules
    if (summary.physicalProgress > summary.financialProgress + 20) {
      this.warnings.push({
        annexure: 'Summary',
        message: 'Physical progress significantly ahead of financial progress',
        suggestion: 'Verify if this is expected or if there are pending payments',
      });
    }
  }

  private validateAnnexureA(annexureA: any): void {
    const { error } = this.projectDetailsSchema.validate(annexureA.projectDetails);

    if (error) {
      error.details.forEach((detail) => {
        this.errors.push({
          annexure: 'Annexure A',
          message: detail.message,
          severity: 'error',
        });
      });
    }

    // Validate milestones
    annexureA.milestones?.forEach((milestone: any, index: number) => {
      if (milestone.actualDate && milestone.plannedDate) {
        const delay =
          new Date(milestone.actualDate).getTime() - new Date(milestone.plannedDate).getTime();

        if (delay > 30 * 24 * 60 * 60 * 1000) {
          // More than 30 days delay
          this.warnings.push({
            annexure: 'Annexure A',
            message: `Milestone ${index + 1} delayed by more than 30 days`,
            suggestion: 'Update project schedule or provide justification',
          });
        }
      }
    });
  }

  private validateAnnexureB(annexureB: any): void {
    annexureB.activities?.forEach((activity: any, index: number) => {
      // Check for negative values
      if (activity.plannedQty < 0 || activity.actualQty < 0) {
        this.errors.push({
          annexure: 'Annexure B',
          message: `Activity ${index + 1} has negative quantities`,
          severity: 'error',
        });
      }

      // Check progress calculation
      if (activity.plannedQty > 0) {
        const calculatedProgress = (activity.actualQty / activity.plannedQty) * 100;
        if (Math.abs(calculatedProgress - activity.progress) > 5) {
          this.warnings.push({
            annexure: 'Annexure B',
            message: `Activity ${index + 1} progress calculation mismatch`,
            suggestion: 'Verify progress calculation',
          });
        }
      }
    });
  }

  private validateAnnexureC(annexureC: any): void {
    let totalBudget = 0;
    let totalActual = 0;

    annexureC.budgetItems?.forEach((item: any) => {
      totalBudget += item.budgeted;
      totalActual += item.actual;

      // Check variance calculation
      const expectedVariance = item.actual - item.budgeted;
      if (Math.abs(expectedVariance - item.variance) > 0.01) {
        this.warnings.push({
          annexure: 'Annexure C',
          message: `Variance calculation error for ${item.category}`,
          suggestion: 'Recalculate variance',
        });
      }

      // Check for budget overruns
      if (item.actual > item.budgeted * 1.1) {
        // More than 10% overrun
        this.warnings.push({
          annexure: 'Annexure C',
          message: `Budget overrun for ${item.category}`,
          suggestion: 'Review budget allocation',
        });
      }
    });
  }

  private performCrossValidation(data: MMRData): void {
    // Cross-check summary with detailed annexures
    if (data.annexures.annexureC) {
      const totalFromAnnexure =
        data.annexures.annexureC.budgetItems?.reduce(
          (sum: number, item: any) => sum + item.actual,
          0,
        ) || 0;

      if (Math.abs(totalFromAnnexure - data.summary.actualExpenditure) > 100) {
        this.warnings.push({
          annexure: 'Cross-validation',
          message: 'Summary expenditure does not match Annexure C total',
          suggestion: 'Reconcile summary with detailed annexures',
        });
      }
    }

    // Check date consistency
    if (data.annexures.annexureA?.projectDetails) {
      const projectEndDate = new Date(data.annexures.annexureA.projectDetails.endDate);
      const currentDate = new Date();

      if (projectEndDate < currentDate && data.summary.physicalProgress < 100) {
        this.warnings.push({
          annexure: 'Cross-validation',
          message: 'Project past end date but not complete',
          suggestion: 'Update project schedule or completion status',
        });
      }
    }
  }
}
