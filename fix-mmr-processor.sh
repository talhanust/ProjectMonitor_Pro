#!/bin/bash

cd backend/services/mmr-service

echo "Fixing MMR processor syntax error..."

# Fix the excelProcessor.ts file by replacing the problematic extractYear method
cat > temp-fix.ts << 'FIX'
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
FIX

# Remove the broken part and append the fixed version
head -n 145 src/processors/excelProcessor.ts > temp-processor.ts
cat temp-fix.ts >> temp-processor.ts
mv temp-processor.ts src/processors/excelProcessor.ts
rm temp-fix.ts

echo "✅ Fixed syntax error in excelProcessor.ts"
echo ""
echo "Now testing the parser with sample MMR..."
npm run parse:test tests/fixtures/sample-mmr.xlsx

cd ../../..
