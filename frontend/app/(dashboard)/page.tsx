'use client';

import React from 'react';
import Link from 'next/link';
import { 
  FolderOpen, 
  FileSpreadsheet, 
  Upload, 
  BarChart3, 
  Users, 
  Settings,
  TrendingUp,
  Clock
} from 'lucide-react';

export default function DashboardPage() {
  const stats = [
    { label: 'Active Projects', value: '12', icon: FolderOpen, color: 'bg-blue-500' },
    { label: 'MMRs Processed', value: '48', icon: FileSpreadsheet, color: 'bg-green-500' },
    { label: 'Documents', value: '256', icon: Upload, color: 'bg-purple-500' },
    { label: 'Team Members', value: '34', icon: Users, color: 'bg-orange-500' }
  ];

  const quickActions = [
    { label: 'New Project', href: '/projects/new', icon: FolderOpen },
    { label: 'Upload MMR', href: '/mmr/upload', icon: FileSpreadsheet },
    { label: 'Upload Document', href: '/documents/upload', icon: Upload },
    { label: 'View Reports', href: '/reports', icon: BarChart3 }
  ];

  return (
    <div className="p-6 space-y-6">
      <div>
        <h1 className="text-3xl font-bold text-gray-900">Dashboard</h1>
        <p className="text-gray-600 mt-1">Project Monitoring & Management System</p>
      </div>

      {/* Stats Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        {stats.map((stat) => {
          const Icon = stat.icon;
          return (
            <div key={stat.label} className="bg-white rounded-lg shadow p-6">
              <div className="flex items-center">
                <div className={`${stat.color} p-3 rounded-lg`}>
                  <Icon className="w-6 h-6 text-white" />
                </div>
                <div className="ml-4">
                  <p className="text-2xl font-semibold">{stat.value}</p>
                  <p className="text-gray-600 text-sm">{stat.label}</p>
                </div>
              </div>
            </div>
          );
        })}
      </div>

      {/* Quick Actions */}
      <div className="bg-white rounded-lg shadow p-6">
        <h2 className="text-xl font-semibold mb-4">Quick Actions</h2>
        <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
          {quickActions.map((action) => {
            const Icon = action.icon;
            return (
              <Link
                key={action.label}
                href={action.href}
                className="flex flex-col items-center p-4 border rounded-lg hover:bg-gray-50 transition"
              >
                <Icon className="w-8 h-8 text-blue-600 mb-2" />
                <span className="text-sm text-center">{action.label}</span>
              </Link>
            );
          })}
        </div>
      </div>

      {/* Recent Activity */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <div className="bg-white rounded-lg shadow p-6">
          <h2 className="text-xl font-semibold mb-4">Recent Projects</h2>
          <div className="space-y-3">
            {['Highway Construction', 'Bridge Renovation', 'Urban Development'].map((project) => (
              <div key={project} className="flex items-center justify-between p-3 border rounded-lg">
                <div className="flex items-center">
                  <FolderOpen className="w-5 h-5 text-gray-500 mr-3" />
                  <span>{project}</span>
                </div>
                <TrendingUp className="w-5 h-5 text-green-500" />
              </div>
            ))}
          </div>
        </div>

        <div className="bg-white rounded-lg shadow p-6">
          <h2 className="text-xl font-semibold mb-4">Recent MMRs</h2>
          <div className="space-y-3">
            {['December 2024', 'November 2024', 'October 2024'].map((month) => (
              <div key={month} className="flex items-center justify-between p-3 border rounded-lg">
                <div className="flex items-center">
                  <FileSpreadsheet className="w-5 h-5 text-gray-500 mr-3" />
                  <span>{month}</span>
                </div>
                <Clock className="w-5 h-5 text-blue-500" />
              </div>
            ))}
          </div>
        </div>
      </div>
    </div>
  );
}
