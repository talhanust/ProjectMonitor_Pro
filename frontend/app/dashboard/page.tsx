export default function DashboardPage() {
  return (
    <div className="min-h-screen p-8 bg-gray-50">
      <div className="max-w-7xl mx-auto">
        <h1 className="text-3xl font-bold text-gray-900 mb-8">Dashboard</h1>

        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          <div className="bg-white p-6 rounded-lg shadow">
            <h2 className="text-lg font-semibold text-gray-700 mb-2">Projects</h2>
            <p className="text-3xl font-bold text-blue-600">12</p>
          </div>

          <div className="bg-white p-6 rounded-lg shadow">
            <h2 className="text-lg font-semibold text-gray-700 mb-2">Tasks</h2>
            <p className="text-3xl font-bold text-green-600">48</p>
          </div>

          <div className="bg-white p-6 rounded-lg shadow">
            <h2 className="text-lg font-semibold text-gray-700 mb-2">Team Members</h2>
            <p className="text-3xl font-bold text-purple-600">8</p>
          </div>
        </div>

        <div className="mt-8">
          <a href="/" className="text-blue-600 hover:text-blue-800 transition-colors">
            ← Back to Home
          </a>
        </div>
      </div>
    </div>
  );
}
