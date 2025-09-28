import Joi from 'joi';

export const createProjectSchema = Joi.object({
  name: Joi.string().min(3).max(200).required(),
  description: Joi.string().max(1000).optional(),
  status: Joi.string()
    .valid('PLANNING', 'IN_PROGRESS', 'ON_HOLD', 'COMPLETED', 'CANCELLED')
    .optional(),
  priority: Joi.string()
    .valid('LOW', 'MEDIUM', 'HIGH', 'CRITICAL')
    .optional(),
  budget: Joi.number().positive().optional(),
  startDate: Joi.date().iso().optional(),
  endDate: Joi.date().iso().greater(Joi.ref('startDate')).optional(),
  location: Joi.string().max(500).optional(),
  gpsLatitude: Joi.number().min(-90).max(90).optional(),
  gpsLongitude: Joi.number().min(-180).max(180).optional(),
  projectManager: Joi.string().optional(),
  teamMembers: Joi.array().items(Joi.string()).optional(),
  stakeholders: Joi.array().items(Joi.string()).optional(),
  tags: Joi.array().items(Joi.string()).optional()
});

export const updateProjectSchema = Joi.object({
  name: Joi.string().min(3).max(200).optional(),
  description: Joi.string().max(1000).optional(),
  status: Joi.string()
    .valid('PLANNING', 'IN_PROGRESS', 'ON_HOLD', 'COMPLETED', 'CANCELLED')
    .optional(),
  priority: Joi.string()
    .valid('LOW', 'MEDIUM', 'HIGH', 'CRITICAL')
    .optional(),
  budget: Joi.number().positive().optional(),
  startDate: Joi.date().iso().optional(),
  endDate: Joi.date().iso().optional(),
  actualStartDate: Joi.date().iso().optional(),
  actualEndDate: Joi.date().iso().optional(),
  progress: Joi.number().min(0).max(100).optional(),
  location: Joi.string().max(500).optional(),
  gpsLatitude: Joi.number().min(-90).max(90).optional(),
  gpsLongitude: Joi.number().min(-180).max(180).optional(),
  projectManager: Joi.string().optional(),
  teamMembers: Joi.array().items(Joi.string()).optional(),
  stakeholders: Joi.array().items(Joi.string()).optional(),
  tags: Joi.array().items(Joi.string()).optional()
}).min(1); // At least one field required for update

export const queryProjectsSchema = Joi.object({
  page: Joi.number().integer().min(1).default(1),
  limit: Joi.number().integer().min(1).max(100).default(20),
  status: Joi.string()
    .valid('PLANNING', 'IN_PROGRESS', 'ON_HOLD', 'COMPLETED', 'CANCELLED')
    .optional(),
  priority: Joi.string()
    .valid('LOW', 'MEDIUM', 'HIGH', 'CRITICAL')
    .optional(),
  search: Joi.string().optional(),
  sortBy: Joi.string()
    .valid('createdAt', 'updatedAt', 'name', 'projectId', 'startDate')
    .default('createdAt'),
  sortOrder: Joi.string().valid('asc', 'desc').default('desc')
});
