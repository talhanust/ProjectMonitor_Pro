#!/usr/bin/env node
const XLSX = require('xlsx');

const categories = ['Documentation', 'Technical', 'Support', 'Training', 'Reference'];
const tags = ['guide', 'manual', 'api', 'rest', 'faq', 'help', 'tutorial', 'reference'];

function generateRow(id) {
  const category = categories[Math.floor(Math.random() * categories.length)];
  const selectedTags = tags.slice(0, Math.floor(Math.random() * 3) + 1);

  return {
    ID: `DOC-${String(id).padStart(4, '0')}`,
    Title: `${category} Document ${id}`,
    Description: `This is a detailed description for document ${id} in the ${category} category.`,
    Category: category,
    Tags: selectedTags.join(','),
    Source: `/documents/${category.toLowerCase()}/doc-${id}.pdf`,
    Date: new Date(2024, 0, 1 + Math.floor(Math.random() * 365)).toISOString().split('T')[0],
    Author: ['John Doe', 'Jane Smith', 'Bob Johnson'][Math.floor(Math.random() * 3)],
  };
}

const numRows = parseInt(process.argv[2]) || 100;
const outputFile = process.argv[3] || 'test-mmr.xlsx';

const data = Array.from({ length: numRows }, (_, i) => generateRow(i + 1));
const ws = XLSX.utils.json_to_sheet(data);
const wb = XLSX.utils.book_new();
XLSX.utils.book_append_sheet(wb, ws, 'Documents');
XLSX.writeFile(wb, outputFile);

const fs = require('fs');
const fileSize = fs.statSync(outputFile).size;

console.log(`✓ Created ${outputFile}`);
console.log(`  Rows: ${numRows}`);
console.log(`  Size: ${(fileSize / 1024).toFixed(2)} KB`);
