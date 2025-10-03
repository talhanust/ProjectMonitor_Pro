export * from '../../shared/types/mmr.types';

export interface ParserOptions {
  strictMode?: boolean;
  allowPartialData?: boolean;
  formatVersion?: 'v1' | 'v2' | 'auto';
  annexuresToParse?: string[];
  validateData?: boolean;
}

export interface CellLocation {
  sheet: string;
  row: number;
  column: string;
  value: any;
}

export interface FormatPattern {
  identifier: string | RegExp;
  location: CellLocation;
  variations?: CellLocation[];
}
