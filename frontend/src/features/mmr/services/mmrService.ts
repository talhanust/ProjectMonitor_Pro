const API_URL = process.env.NEXT_PUBLIC_MMR_API_URL || 'http://localhost:3001';

function getAuthToken(): string | null {
  if (typeof window === 'undefined') return null;
  return localStorage.getItem('accessToken');
}

export const mmrService = {
  async uploadFile(file: File, onProgress?: (progress: number) => void) {
    const token = getAuthToken();
    
    if (!token) {
      throw new Error('Authentication required. Please sign in at /login');
    }

    const formData = new FormData();
    formData.append('file', file);

    const xhr = new XMLHttpRequest();

    return new Promise((resolve, reject) => {
      xhr.upload.addEventListener('progress', (e) => {
        if (e.lengthComputable && onProgress) {
          const progress = (e.loaded / e.total) * 100;
          onProgress(progress);
        }
      });

      xhr.addEventListener('load', () => {
        if (xhr.status === 200) {
          try {
            const response = JSON.parse(xhr.responseText);
            resolve(response);
          } catch (e) {
            reject(new Error('Invalid response from server'));
          }
        } else if (xhr.status === 401) {
          reject(new Error('Session expired. Please sign in again at /login'));
        } else {
          reject(new Error(`Upload failed: ${xhr.statusText}`));
        }
      });

      xhr.addEventListener('error', () => reject(new Error('Network error during upload')));
      
      xhr.open('POST', `${API_URL}/api/upload/upload`);
      xhr.setRequestHeader('Authorization', `Bearer ${token}`);
      xhr.send(formData);
    });
  },

  async getProcessingStatus(fileId: string) {
    const token = getAuthToken();
    if (!token) throw new Error('Authentication required');

    const response = await fetch(`${API_URL}/api/mmr/jobs/${fileId}`, {
      headers: { 'Authorization': `Bearer ${token}` }
    });
    
    if (!response.ok) throw new Error('Failed to get status');
    return response.json();
  },

  async getValidationResults(fileId: string) {
    const token = getAuthToken();
    if (!token) throw new Error('Authentication required');

    const response = await fetch(`${API_URL}/api/mmr/jobs/${fileId}`, {
      headers: { 'Authorization': `Bearer ${token}` }
    });
    
    if (!response.ok) throw new Error('Failed to get validation results');
    return response.json();
  },

  async correctData(fileId: string, corrections: any) {
    const token = getAuthToken();
    if (!token) throw new Error('Authentication required');

    const response = await fetch(`${API_URL}/api/mmr/jobs/${fileId}/correct`, {
      method: 'POST',
      headers: { 
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${token}`
      },
      body: JSON.stringify(corrections),
    });
    
    if (!response.ok) throw new Error('Failed to correct data');
    return response.json();
  },

  async approveData(fileId: string) {
    const token = getAuthToken();
    if (!token) throw new Error('Authentication required');

    const response = await fetch(`${API_URL}/api/mmr/jobs/${fileId}/approve`, {
      method: 'POST',
      headers: { 'Authorization': `Bearer ${token}` }
    });
    
    if (!response.ok) throw new Error('Failed to approve data');
    return response.json();
  },
};
