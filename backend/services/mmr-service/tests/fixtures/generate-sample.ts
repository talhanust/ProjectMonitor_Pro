import ExcelJS from 'exceljs';

async function generateSampleMMR() {
  const workbook = new ExcelJS.Workbook();
  
  // Summary Sheet
  const summarySheet = workbook.addWorksheet('Summary');
  summarySheet.getCell('A1').value = 'Project Name';
  summarySheet.getCell('B1').value = 'Highway Construction Project';
  summarySheet.getCell('A2').value = 'Project Code';
  summarySheet.getCell('B2').value = 'HC-2024-001';
  summarySheet.getCell('A3').value = 'Reporting Period';
  summarySheet.getCell('B3').value = 'December 2024';
  summarySheet.getCell('A5').value = 'Total Budget';
  summarySheet.getCell('B5').value = 50000000;
  summarySheet.getCell('A6').value = 'Actual Expenditure';
  summarySheet.getCell('B6').value = 35000000;
  summarySheet.getCell('A7').value = 'Physical Progress';
  summarySheet.getCell('B7').value = 65;
  summarySheet.getCell('A8').value = 'Financial Progress';
  summarySheet.getCell('B8').value = 70;
  
  // Annexure A - Project Overview
  const annexureA = workbook.addWorksheet('Annexure-A');
  annexureA.getCell('A1').value = 'PROJECT OVERVIEW';
  annexureA.getCell('A3').value = 'Project Name';
  annexureA.getCell('B3').value = 'Highway Construction Project';
  annexureA.getCell('A4').value = 'Location';
  annexureA.getCell('B4').value = 'State Highway 45';
  annexureA.getCell('A5').value = 'Client';
  annexureA.getCell('B5').value = 'State PWD';
  annexureA.getCell('A6').value = 'Contract Value';
  annexureA.getCell('B6').value = 50000000;
  annexureA.getCell('A7').value = 'Start Date';
  annexureA.getCell('B7').value = new Date('2024-01-01');
  annexureA.getCell('A8').value = 'End Date';
  annexureA.getCell('B8').value = new Date('2025-12-31');
  
  // Milestones table
  annexureA.getCell('A10').value = 'MILESTONES';
  annexureA.getCell('A11').value = 'Description';
  annexureA.getCell('B11').value = 'Planned Date';
  annexureA.getCell('C11').value = 'Actual Date';
  annexureA.getCell('D11').value = 'Status';
  
  annexureA.getCell('A12').value = 'Site Mobilization';
  annexureA.getCell('B12').value = new Date('2024-01-15');
  annexureA.getCell('C12').value = new Date('2024-01-20');
  annexureA.getCell('D12').value = 'Completed';
  
  // Annexure B - Physical Progress
  const annexureB = workbook.addWorksheet('Annexure-B');
  annexureB.getCell('A1').value = 'PHYSICAL PROGRESS';
  annexureB.getCell('A3').value = 'Activity Description';
  annexureB.getCell('B3').value = 'Unit';
  annexureB.getCell('C3').value = 'Planned Qty';
  annexureB.getCell('D3').value = 'Actual Qty';
  annexureB.getCell('E3').value = 'Progress %';
  
  annexureB.getCell('A4').value = 'Earthwork';
  annexureB.getCell('B4').value = 'CUM';
  annexureB.getCell('C4').value = 100000;
  annexureB.getCell('D4').value = 65000;
  annexureB.getCell('E4').value = 65;
  
  // Save file
  await workbook.xlsx.writeFile('tests/fixtures/sample-mmr.xlsx');
  console.log('Sample MMR file generated: tests/fixtures/sample-mmr.xlsx');
}

generateSampleMMR().catch(console.error);
