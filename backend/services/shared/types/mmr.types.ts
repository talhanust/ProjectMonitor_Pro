export interface MMRData {
  id?: string;
  projectId: string;
  month: string;
  year: number;
  reportDate: Date;
  
  // Summary Data
  summary: {
    totalBudget: number;
    actualExpenditure: number;
    physicalProgress: number;
    financialProgress: number;
    variance: number;
  };
  
  // Annexures
  annexures: {
    summary?: AnnexureSummary;
    annexureA?: AnnexureA; // Project Overview
    annexureB?: AnnexureB; // Physical Progress
    annexureC?: AnnexureC; // Financial Progress
    annexureD?: AnnexureD; // Manpower
    annexureE?: AnnexureE; // Equipment
    annexureF?: AnnexureF; // Materials
    // ... Add more annexures as needed
  };
  
  // Metadata
  metadata: {
    fileName: string;
    uploadedAt: Date;
    parsedAt: Date;
    parseConfidence: number; // 0-100
    formatVersion?: string;
    errors?: ParseError[];
    warnings?: ParseWarning[];
  };
}

export interface AnnexureSummary {
  projectName: string;
  projectCode: string;
  reportingPeriod: string;
  preparedBy: string;
  checkedBy: string;
  approvedBy: string;
}

export interface AnnexureA {
  projectDetails: {
    name: string;
    location: string;
    client: string;
    contractValue: number;
    startDate: Date;
    endDate: Date;
    revisedEndDate?: Date;
  };
  milestones: Array<{
    id: string;
    description: string;
    plannedDate: Date;
    actualDate?: Date;
    status: 'Completed' | 'In Progress' | 'Pending' | 'Delayed';
    remarks?: string;
  }>;
}

export interface AnnexureB {
  activities: Array<{
    id: string;
    description: string;
    unit: string;
    plannedQty: number;
    actualQty: number;
    progress: number;
    variance: number;
  }>;
}

export interface AnnexureC {
  budgetItems: Array<{
    category: string;
    budgeted: number;
    actual: number;
    committed: number;
    variance: number;
    variancePercent: number;
  }>;
}

export interface AnnexureD {
  manpower: Array<{
    category: string;
    planned: number;
    actual: number;
    variance: number;
    remarks?: string;
  }>;
}

export interface AnnexureE {
  equipment: Array<{
    type: string;
    planned: number;
    deployed: number;
    operational: number;
    breakdown: number;
    utilization: number;
  }>;
}

export interface AnnexureF {
  materials: Array<{
    item: string;
    unit: string;
    planned: number;
    procured: number;
    consumed: number;
    stock: number;
    remarks?: string;
  }>;
}

export interface ParseError {
  annexure: string;
  cell?: string;
  message: string;
  severity: 'error' | 'critical';
}

export interface ParseWarning {
  annexure: string;
  cell?: string;
  message: string;
  suggestion?: string;
}

export interface ParseResult {
  success: boolean;
  data?: MMRData;
  errors: ParseError[];
  warnings: ParseWarning[];
  confidence: number;
}
