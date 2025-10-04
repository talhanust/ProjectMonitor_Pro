export const PARSER_CONFIG = {
  // Common header patterns to identify annexures
  annexureIdentifiers: {
    summary: /summary|executive\s*summary/i,
    annexureA: /annexure\s*-?\s*a|project\s*overview/i,
    annexureB: /annexure\s*-?\s*b|physical\s*progress/i,
    annexureC: /annexure\s*-?\s*c|financial\s*progress/i,
    annexureD: /annexure\s*-?\s*d|manpower/i,
    annexureE: /annexure\s*-?\s*e|equipment/i,
    annexureF: /annexure\s*-?\s*f|materials/i,
  },

  // Common cell patterns for data extraction
  cellPatterns: {
    projectName: /project\s*name|name\s*of\s*project/i,
    projectCode: /project\s*code|code/i,
    reportPeriod: /report.*period|month|period/i,
    totalBudget: /total.*budget|budget.*total/i,
    expenditure: /actual.*expend|expend.*actual/i,
    physicalProgress: /physical.*progress/i,
    financialProgress: /financial.*progress/i,
  },

  // Format variations tolerance
  variations: {
    maxRowOffset: 5, // Search within 5 rows of expected position
    maxColOffset: 3, // Search within 3 columns of expected position
    similarityThreshold: 0.85, // 85% string similarity for fuzzy matching
  },

  // Data validation rules
  validation: {
    percentageRange: { min: 0, max: 100 },
    dateFormats: ['MM/DD/YYYY', 'DD/MM/YYYY', 'YYYY-MM-DD'],
    currencyFormats: ['₹', 'INR', 'Rs.'],
  },

  // Confidence scoring weights
  confidenceWeights: {
    headerMatch: 0.3,
    dataComplete: 0.4,
    validationPass: 0.3,
  },
};
